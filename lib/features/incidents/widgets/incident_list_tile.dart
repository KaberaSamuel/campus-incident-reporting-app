import 'package:flutter/material.dart';

import '../../../core/widgets/status_badge.dart';
import '../models/incident.dart';

class IncidentListTile extends StatelessWidget {
  const IncidentListTile({
    super.key,
    required this.incident,
    required this.currentUserId,
    required this.onTap,
  });

  final Incident incident;
  final String? currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMine = currentUserId != null && incident.reporterId == currentUserId;
    final thumb = incident.imageUrls.isNotEmpty ? incident.imageUrls.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumb,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.report_outlined),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${incident.locationName} · ${incident.category.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isMine
                                ? '${incident.reporterName} · You'
                                : incident.reporterName,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        StatusBadge(
                          label: incident.status.label,
                          kind: incident.status.badgeKind,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
