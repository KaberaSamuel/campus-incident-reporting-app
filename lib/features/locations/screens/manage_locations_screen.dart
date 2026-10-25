import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  List<CampusLocation> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _locations = await context.read<LocationRepository>().fetchAll();
    setState(() => _loading = false);
  }

  Future<void> _showEditor({CampusLocation? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add location' : 'Edit location'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;

    final repo = context.read<LocationRepository>();
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    if (existing == null) {
      await repo.create(name: name);
    } else {
      await repo.update(id: existing.id, name: name, sortOrder: existing.sortOrder);
    }
    await _load();
  }

  Future<void> _delete(CampusLocation location) async {
    try {
      await context.read<LocationRepository>().delete(location.id);
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView(message: 'Loading locations…');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => _showEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Add location'),
          ),
        ),
        Expanded(
          child: _locations.isEmpty
              ? const EmptyStateView(
                  icon: Icons.place_outlined,
                  title: 'No locations',
                  subtitle: 'Add campus locations for students to choose when reporting.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return ListTile(
                        title: Text(loc.name),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditor(existing: loc);
                            } else if (value == 'delete') {
                              _delete(loc);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
