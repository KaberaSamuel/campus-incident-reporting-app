import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../locations/models/location.dart';
import '../../locations/repositories/location_repository.dart';
import '../providers/incident_list_provider.dart';
import '../repositories/incident_repository.dart';
import '../widgets/incident_filter_bar.dart';
import '../widgets/incident_list_tile.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({
    super.key,
    required this.title,
    required this.incidentRoutePrefix,
    this.showMineOnlyToggle = true,
    this.initialMineOnly = false,
    this.openOnly = false,
  });

  final String title;
  final String incidentRoutePrefix;
  final bool showMineOnlyToggle;
  final bool initialMineOnly;
  final bool openOnly;

  @override
  State<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  late IncidentFilterValues _filters;
  IncidentListProvider? _listProvider;
  List<CampusLocation> _locations = [];
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _filters = IncidentFilterValues(mineOnly: widget.initialMineOnly);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _changes?.cancel();
    _listProvider?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _listProvider = IncidentListProvider(context.read<IncidentRepository>());
    final uid = context.read<AuthProvider>().user?.uid;
    _listProvider!.configure(
      mineOnly: widget.initialMineOnly,
      openOnly: widget.openOnly,
      reporterId: uid,
    );
    _locations = await context.read<LocationRepository>().fetchAll();
    await _listProvider!.refresh();
    _changes = context
        .read<IncidentRepository>()
        .watchChanges()
        .listen((_) => _listProvider?.refresh(silent: true));
    if (mounted) setState(() {});
  }

  Future<void> _applyFilters(IncidentListProvider list) async {
    list.setFilters(
      q: _filters.query.trim().isEmpty ? null : _filters.query.trim(),
      category: _filters.category,
      status: _filters.status,
      locationId: _filters.locationId,
      mineOnly: _filters.mineOnly,
    );
    await list.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    final list = _listProvider;
    if (list == null) {
      return const LoadingView(message: 'Loading reports…');
    }

    return ListenableBuilder(
      listenable: list,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IncidentFilterBar(
              values: _filters,
              locations: _locations,
              showMineOnlyToggle: widget.showMineOnlyToggle,
              onChanged: (v) => setState(() => _filters = v),
              onApply: () => _applyFilters(list),
            ),
            Expanded(
              child: _buildBody(context, list, uid),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, IncidentListProvider list, String? uid) {
    if (list.isLoading && list.items.isEmpty) {
      return const LoadingView(message: 'Loading reports…');
    }
    if (list.errorMessage != null && list.items.isEmpty) {
      return ErrorStateView(
        message: list.errorMessage!,
        onRetry: list.refresh,
      );
    }
    if (list.items.isEmpty) {
      return const EmptyStateView(
        icon: Icons.list_alt_outlined,
        title: 'No reports yet',
        subtitle: 'Try changing filters or check back later.',
      );
    }

    return RefreshIndicator(
      onRefresh: list.refresh,
      child: ListView.builder(
        itemCount: list.items.length + (list.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= list.items.length) {
            if (!list.isLoadingMore) {
              list.loadMore();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final incident = list.items[index];
          return IncidentListTile(
            incident: incident,
            currentUserId: uid,
            onTap: () => context.push('${widget.incidentRoutePrefix}/${incident.id}'),
          );
        },
      ),
    );
  }
}
