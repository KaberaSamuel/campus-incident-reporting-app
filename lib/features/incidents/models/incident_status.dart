import '../../../core/theme/status_colors.dart';

enum IncidentStatus {
  submitted('submitted'),
  inProgress('in_progress'),
  resolved('resolved');

  const IncidentStatus(this.firestoreValue);
  final String firestoreValue;

  static IncidentStatus fromFirestore(String value) {
    return IncidentStatus.values.firstWhere(
      (s) => s.firestoreValue == value,
      orElse: () => IncidentStatus.submitted,
    );
  }

  String get label {
    switch (this) {
      case IncidentStatus.submitted:
        return 'Submitted';
      case IncidentStatus.inProgress:
        return 'In progress';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  StatusBadgeKind get badgeKind {
    switch (this) {
      case IncidentStatus.submitted:
        return StatusBadgeKind.submitted;
      case IncidentStatus.inProgress:
        return StatusBadgeKind.inProgress;
      case IncidentStatus.resolved:
        return StatusBadgeKind.resolved;
    }
  }
}
