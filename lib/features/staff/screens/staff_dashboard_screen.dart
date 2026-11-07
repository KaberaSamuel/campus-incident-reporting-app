import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../incidents/models/incident.dart';
import '../../incidents/repositories/incident_repository.dart';
import '../../incidents/widgets/incident_list_tile.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  CampusIncidentStats? _stats;
  List<Incident> _open = [];
  String? _error;
  bool _loading = true;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _load();
    _changes = context
        .read<IncidentRepository>()
        .watchChanges()
        .listen((_) => _load(silent: true));
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repo = context.read<IncidentRepository>();
      final stats = await repo.fetchCampusStats();
      final open = await repo.queryOpenIncidents(limit: 8);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _open = open.incidents;
        _loading = false;
      });
    } catch (e) {
      if (silent || !mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Loading dashboard…');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(label: 'Open', value: stats.open),
              const SizedBox(width: 8),
              _StatCard(label: 'Resolved', value: stats.resolved),
              const SizedBox(width: 8),
              _StatCard(label: 'Total', value: stats.total),
            ],
          ),
          const SizedBox(height: 24),
          Text('Open incidents', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._open.map(
            (incident) => IncidentListTile(
              incident: incident,
              currentUserId: null,
              onTap: () => context.push('/staff/incident/${incident.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('$value', style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
