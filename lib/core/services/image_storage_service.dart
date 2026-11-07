import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Thrown when the R2 upload Worker rejects a request.
class ImageStorageException implements Exception {
  ImageStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Stores incident photos in Cloudflare R2.
///
/// Uploads go through a Cloudflare Worker because an APK can never hold R2
/// secret keys. The Worker verifies the Firebase ID token, then applies the
/// same ownership rules as Firestore (students upload; reporter or staff
/// delete). Reading is public via the bucket's r2.dev URL, so widgets can use
/// plain `Image.network`.
class ImageStorageService {
  ImageStorageService({String? baseUrl, FirebaseAuth? auth, http.Client? client})
      : _baseUrl = (baseUrl ?? defaultBaseUrl).replaceAll(RegExp(r'/+$'), ''),
        _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

  /// Base URL of the deployed `campus-incidents-storage` Worker.
  ///
  /// Override with `--dart-define=R2_WORKER_URL=https://...` when the Worker is
  /// deployed to a different subdomain.
  static const String defaultBaseUrl = String.fromEnvironment(
    'R2_WORKER_URL',
    defaultValue: 'https://storage.campus-incident-reporting.workers.dev',
  );

  final String _baseUrl;
  final FirebaseAuth _auth;
  final http.Client _client;

  bool get isConfigured =>
      _baseUrl.isNotEmpty && !_baseUrl.contains('REPLACE_ME');

  Future<String> _requireToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ImageStorageException('Sign in to attach photos.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw ImageStorageException('Could not verify your session. Sign in again.');
    }
    return token;
  }

  /// Uploads one photo and returns its public URL.
  Future<String> upload({
    required String incidentId,
    required Uint8List bytes,
    required int index,
  }) async {
    if (!isConfigured) {
      throw ImageStorageException('Photo storage is not configured yet.');
    }
    final token = await _requireToken();
    final key = buildObjectPath(incidentId: incidentId, index: index);
    final request = http.Request('POST', Uri.parse('$_baseUrl/$key'))
      ..headers['authorization'] = 'Bearer $token'
      ..headers['content-type'] = 'image/jpeg'
      ..bodyBytes = bytes;

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw ImageStorageException(_messageFor(response));
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final url = decoded['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ImageStorageException('Upload succeeded but no URL was returned.');
    }
    return url;
  }

  /// Best-effort delete. Missing objects are treated as success.
  Future<void> deleteByUrl(String url) async {
    final key = keyFromUrl(url);
    if (key == null) return;
    final token = await _requireToken();
    try {
      await _client.delete(
        Uri.parse('$_baseUrl/$key'),
        headers: {'authorization': 'Bearer $token'},
      );
    } catch (_) {
      // Cleanup is best-effort; the incident document is already gone.
    }
  }

  static String buildObjectPath({
    required String incidentId,
    required int index,
  }) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'incidents/$incidentId/${index}_$stamp.jpg';
  }

  /// Extracts `incidents/<id>/<file>` from a public URL.
  static String? keyFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final start = segments.indexOf('incidents');
    if (start < 0 || segments.length < start + 3) return null;
    return segments.sublist(start).join('/');
  }

  String _messageFor(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    if (response.statusCode == 413) return 'Image is too large (max 5 MB).';
    if (response.statusCode == 401) return 'Your session expired. Sign in again.';
    if (response.statusCode == 403) return 'You are not allowed to upload photos.';
    return 'Photo upload failed (${response.statusCode}). Try again.';
  }
}
