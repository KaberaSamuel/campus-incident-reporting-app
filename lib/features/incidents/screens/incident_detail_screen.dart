import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import '../repositories/incident_repository.dart';

class IncidentDetailScreen extends StatefulWidget {
  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
    required this.isStaffView,
  });

  final String incidentId;
  final bool isStaffView;

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  IncidentStatus? _selectedStatus;
  final _staffNoteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _staffNoteController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent(BuildContext context, Incident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = context.read<AuthProvider>().user!.uid;
    try {
      await context.read<IncidentRepository>().deleteForStudent(
        incidentId: widget.incidentId,
        uid: uid,
      );
      if (context.mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteStaff(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete incident?'),
        content: const Text('This removes the report and its photos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    await context.read<IncidentRepository>().deleteForStaff(widget.incidentId);
    if (context.mounted) context.pop();
  }

  Future<void> _saveStaff(BuildContext context, Incident incident) async {
    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    try {
      await context.read<IncidentRepository>().updateByStaff(
        incidentId: widget.incidentId,
        input: IncidentStaffUpdateInput(
          status: _selectedStatus ?? incident.status,
          staffNote: _staffNoteController.text.trim().isEmpty
              ? null
              : _staffNoteController.text.trim(),
          changedByUid: auth.user!.uid,
          changedByName: auth.profile?.fullName ?? 'Staff',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident updated.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<IncidentRepository>();
    final uid = context.watch<AuthProvider>().user?.uid;

    return StreamBuilder<Incident?>(
      stream: repo.watchById(widget.incidentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final incident = snapshot.data;
        if (incident == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorStateView(message: 'Incident not found.'),
          );
        }

        _selectedStatus ??= incident.status;
        if (_staffNoteController.text.isEmpty && (incident.staffNote ?? '').isNotEmpty) {
          _staffNoteController.text = incident.staffNote!;
        }

        final canStudentDelete = !widget.isStaffView &&
            uid == incident.reporterId &&
            incident.status == IncidentStatus.submitted;

        return Scaffold(
          appBar: AppBar(title: Text(incident.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatusBadge(
                label: incident.status.label,
                kind: incident.status.badgeKind,
              ),
              const SizedBox(height: 12),
              Text(incident.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text('${incident.category.label} · ${incident.locationName}'),
              Text('Reported by ${incident.reporterName}'),
              if (incident.detailNote != null) ...[
                const SizedBox(height: 8),
                Text('Note: ${incident.detailNote}'),
              ],
              if (incident.staffNote != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Staff note', style: Theme.of(context).textTheme.titleSmall),
                        Text(incident.staffNote!),
                      ],
                    ),
                  ),
                ),
              ],
              if (incident.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Photos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: incident.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        incident.imageUrls[i],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
              ...incident.statusHistory.map(
                (e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.timeline),
                  title: Text(e.status.label),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(e.changedAt) +
                        (e.changedByName != null ? ' · ${e.changedByName}' : ''),
                  ),
                ),
              ),
              if (widget.isStaffView) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<IncidentStatus>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: IncidentStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _staffNoteController,
                  decoration: const InputDecoration(labelText: 'Staff note'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : () => _saveStaff(context, incident),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _deleteStaff(context),
                  child: const Text('Delete incident'),
                ),
              ],
              if (canStudentDelete) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _deleteStudent(context, incident),
                  child: const Text('Delete my report'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
