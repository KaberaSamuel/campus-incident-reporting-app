import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../incidents/models/incident.dart';
import '../../incidents/models/incident_query_params.dart';
import '../../incidents/repositories/incident_repository.dart';
import '../../incidents/widgets/incident_list_tile.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  CampusIncidentStats? _stats;
  List<Incident> _recent = [];
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
      final recent = await repo.queryIncidents(
        const IncidentQueryParams(limit: 5),
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recent = recent.incidents;
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
      return const LoadingView(message: 'Loading campus overview…');
    }
    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    final stats = _stats!;
    final uid = context.watch<AuthProvider>().user?.uid;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Campus overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(label: 'Submitted', value: stats.submitted),
              const SizedBox(width: 8),
              _StatCard(label: 'In progress', value: stats.inProgress),
              const SizedBox(width: 8),
              _StatCard(label: 'Resolved', value: stats.resolved),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.total} total · ${stats.open} open',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Recent reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            const EmptyStateView(
              icon: Icons.inbox_outlined,
              title: 'No reports yet',
              subtitle: 'Be the first to report a campus issue.',
            )
          else
            ..._recent.map(
              (incident) => IncidentListTile(
                incident: incident,
                currentUserId: uid,
                onTap: () => context.push('/student/incident/${incident.id}'),
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
