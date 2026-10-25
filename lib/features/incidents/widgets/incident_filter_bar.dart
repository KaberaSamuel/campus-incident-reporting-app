import 'package:flutter/material.dart';

import '../../locations/models/location.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';

class IncidentFilterValues {
  const IncidentFilterValues({
    this.query = '',
    this.category,
    this.status,
    this.locationId,
    this.mineOnly = false,
  });

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final String? locationId;
  final bool mineOnly;
}

class IncidentFilterBar extends StatelessWidget {
  const IncidentFilterBar({
    super.key,
    required this.values,
    required this.locations,
    required this.showMineOnlyToggle,
    required this.onChanged,
    required this.onApply,
  });

  final IncidentFilterValues values;
  final List<CampusLocation> locations;
  final bool showMineOnlyToggle;
  final ValueChanged<IncidentFilterValues> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by title',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (q) => onChanged(
              IncidentFilterValues(
                query: q,
                category: values.category,
                status: values.status,
                locationId: values.locationId,
                mineOnly: values.mineOnly,
              ),
            ),
            onSubmitted: (_) => onApply(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (showMineOnlyToggle)
                  FilterChip(
                    label: const Text('My reports'),
                    selected: values.mineOnly,
                    onSelected: (selected) {
                      onChanged(
                        IncidentFilterValues(
                          query: values.query,
                          category: values.category,
                          status: values.status,
                          locationId: values.locationId,
                          mineOnly: selected,
                        ),
                      );
                      onApply();
                    },
                  ),
                const SizedBox(width: 8),
                DropdownButton<IncidentCategory?>(
                  value: values.category,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All categories')),
                    ...IncidentCategory.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    ),
                  ],
                  onChanged: (c) {
                    onChanged(
                      IncidentFilterValues(
                        query: values.query,
                        category: c,
                        status: values.status,
                        locationId: values.locationId,
                        mineOnly: values.mineOnly,
                      ),
                    );
                    onApply();
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<IncidentStatus?>(
                  value: values.status,
                  hint: const Text('Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    ...IncidentStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (s) {
                    onChanged(
                      IncidentFilterValues(
                        query: values.query,
                        category: values.category,
                        status: s,
                        locationId: values.locationId,
                        mineOnly: values.mineOnly,
                      ),
                    );
                    onApply();
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: values.locationId,
                  hint: const Text('Location'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All locations')),
                    ...locations.map(
                      (l) => DropdownMenuItem(value: l.id, child: Text(l.name)),
                    ),
                  ],
                  onChanged: (id) {
                    onChanged(
                      IncidentFilterValues(
                        query: values.query,
                        category: values.category,
                        status: values.status,
                        locationId: id,
                        mineOnly: values.mineOnly,
                      ),
                    );
                    onApply();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
