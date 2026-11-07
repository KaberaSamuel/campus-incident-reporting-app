import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/utils/firebase_error_message.dart';
import '../../../core/utils/image_compress_util.dart';
import '../../auth/providers/auth_provider.dart';
import '../../incidents/models/incident_category.dart';
import '../../incidents/repositories/incident_repository.dart';
import '../../locations/models/location.dart';
import '../../locations/repositories/location_repository.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailNoteController = TextEditingController();

  IncidentCategory _category = IncidentCategory.other;
  String? _locationId;
  List<CampusLocation> _locations = [];
  final List<Uint8List> _images = [];
  bool _loadingLocations = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      _locations = await context.read<LocationRepository>().fetchAll();
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  /// Lets the user choose where a photo comes from: camera, gallery or files.
  Future<void> _pickImages() async {
    if (_images.length >= kMaxIncidentPhotos) {
      _showSnack('You can attach at most $kMaxIncidentPhotos photos.');
      return;
    }
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, _PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, _PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Browse files'),
              onTap: () => Navigator.pop(context, _PhotoSource.files),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = <Uint8List>[];
      switch (source) {
        case _PhotoSource.camera:
          final file = await ImagePicker()
              .pickImage(source: ImageSource.camera, imageQuality: 85);
          if (file != null) picked.add(await file.readAsBytes());
        case _PhotoSource.gallery:
          final files = await ImagePicker().pickMultiImage(imageQuality: 85);
          for (final f in files) {
            picked.add(await f.readAsBytes());
          }
        case _PhotoSource.files:
          final files = await FilePicker.pickFiles(type: FileType.image);
          for (final f in files) {
            picked.add(await f.readAsBytes());
          }
      }
      await _addImages(picked);
    } catch (e) {
      _showSnack('Could not load the photo. Try another one.');
    }
  }

  Future<void> _addImages(List<Uint8List> raw) async {
    for (final bytes in raw) {
      if (_images.length >= kMaxIncidentPhotos) {
        _showSnack('You can attach at most $kMaxIncidentPhotos photos.');
        break;
      }
      final compressed = await compressImageBytes(bytes);
      if (compressed != null) _images.add(compressed);
    }
    if (mounted) setState(() {});
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_locations.isEmpty) {
      _showSnack('Contact campus staff to add locations before reporting.');
      return;
    }
    if (_locationId == null) {
      _showSnack('Choose a location.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final uid = auth.user!.uid;
    final name = auth.profile?.fullName ?? 'Student';
    final location = _locations.firstWhere((l) => l.id == _locationId);

    setState(() => _submitting = true);
    try {
      final repo = context.read<IncidentRepository>();
      await repo.createWithImages(
        input: IncidentCreateInput(
          reporterId: uid,
          reporterName: name,
          category: _category,
          title: _titleController.text,
          description: _descriptionController.text,
          locationId: location.id,
          locationName: location.name,
          detailNote: _detailNoteController.text.trim().isEmpty
              ? null
              : _detailNoteController.text.trim(),
        ),
        imageBytes: _images,
      );
      if (!mounted) return;
      _showSnack('Report submitted.');
      context.go('/student/reports');
    } catch (e) {
      _showSnack(friendlyFirebaseAuthMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocations) {
      return const Center(child: CircularProgressIndicator());
    }

    final locationsEmpty = _locations.isEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (locationsEmpty)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No campus locations are available yet. Contact campus staff to add locations before you can submit a report.',
                ),
              ),
            ),
          DropdownButtonFormField<IncidentCategory>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: IncidentCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: locationsEmpty ? null : (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            enabled: !locationsEmpty,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            enabled: !locationsEmpty,
            minLines: 3,
            maxLines: 5,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a description' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _locationId,
            decoration: const InputDecoration(labelText: 'Location'),
            items: _locations
                .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
                .toList(),
            onChanged: locationsEmpty ? null : (v) => setState(() => _locationId = v),
            validator: (_) => _locationId == null ? 'Choose a location' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _detailNoteController,
            decoration: const InputDecoration(
              labelText: 'Detail note (optional)',
            ),
            enabled: !locationsEmpty,
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Text('Photos (optional, max $kMaxIncidentPhotos)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._images.asMap().entries.map(
                (e) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(e.value, width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _images.removeAt(e.key);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: locationsEmpty ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: locationsEmpty || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}

enum _PhotoSource { camera, gallery, files }
