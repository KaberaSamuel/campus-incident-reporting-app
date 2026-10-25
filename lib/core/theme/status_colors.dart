import 'package:flutter/material.dart';

/// Visual tokens for incident status badges (matches [IncidentStatus] in phase 3+).
enum StatusBadgeKind { submitted, inProgress, resolved }

Color statusColor(StatusBadgeKind status) {
  switch (status) {
    case StatusBadgeKind.submitted:
      return const Color(0xFF1565C0);
    case StatusBadgeKind.inProgress:
      return const Color(0xFFEF6C00);
    case StatusBadgeKind.resolved:
      return const Color(0xFF2E7D32);
  }
}

Color statusBackgroundColor(StatusBadgeKind status) {
  switch (status) {
    case StatusBadgeKind.submitted:
      return const Color(0xFFE3F2FD);
    case StatusBadgeKind.inProgress:
      return const Color(0xFFFFF3E0);
    case StatusBadgeKind.resolved:
      return const Color(0xFFE8F5E9);
  }
}
