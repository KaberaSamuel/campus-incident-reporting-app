import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_query_params.dart';
import '../models/incident_status.dart';
import '../repositories/incident_repository.dart';

class IncidentListProvider extends ChangeNotifier {
  IncidentListProvider(this._repository);

  final IncidentRepository _repository;

  final List<Incident> _items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  bool hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  String? searchQuery;
  IncidentCategory? category;
  IncidentStatus? status;
  String? locationId;
  bool mineOnly = false;
  bool openOnly = false;
  String? reporterId;

  List<Incident> get items => List.unmodifiable(_items);

  void configure({
    bool? mineOnly,
    bool? openOnly,
    String? reporterId,
  }) {
    if (mineOnly != null) this.mineOnly = mineOnly;
    if (openOnly != null) this.openOnly = openOnly;
    if (reporterId != null) this.reporterId = reporterId;
  }

  /// Reloads the first page. With [silent] the current items stay on screen
  /// until the new page arrives (used for live updates).
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      hasMore = true;
      _lastDocument = null;
      _items.clear();
      notifyListeners();
    }

    try {
      final page = await _fetchPage();
      if (silent) _items.clear();
      _items.addAll(page.incidents);
      _lastDocument = page.lastDocument;
      hasMore = page.incidents.length >= _pageSize && page.lastDocument != null;
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || isLoading || !hasMore || _lastDocument == null) {
      return;
    }
    isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _fetchPage(startAfter: _lastDocument);
      _items.addAll(page.incidents);
      _lastDocument = page.lastDocument;
      hasMore = page.incidents.length >= _pageSize && page.lastDocument != null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void setFilters({
    String? q,
    IncidentCategory? category,
    IncidentStatus? status,
    String? locationId,
    bool? mineOnly,
  }) {
    searchQuery = q;
    this.category = category;
    this.status = status;
    this.locationId = locationId;
    if (mineOnly != null) this.mineOnly = mineOnly;
  }

  static const _pageSize = 20;

  Future<IncidentQueryPage> _fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return _repository.queryIncidents(
      IncidentQueryParams(
        q: searchQuery,
        category: category,
        status: openOnly ? null : status,
        locationId: locationId,
        mineOnly: mineOnly,
        openOnly: openOnly,
        reporterId: reporterId,
        limit: _pageSize,
        startAfter: startAfter,
      ),
    );
  }
}
