import 'package:campus_incidents/features/incidents/models/incident.dart';
import 'package:campus_incidents/features/incidents/models/incident_category.dart';
import 'package:campus_incidents/features/incidents/models/incident_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Incident toFirestore includes titleLowercase', () {
    final now = DateTime(2026, 1, 1);
    final incident = Incident(
      id: 'x',
      reporterId: 'u1',
      reporterName: 'Sam',
      category: IncidentCategory.water,
      title: 'Leaking Pipe',
      description: 'Hallway',
      titleLowercase: 'leaking pipe',
      locationId: 'loc1',
      locationName: 'Block A',
      status: IncidentStatus.submitted,
      createdAt: now,
      updatedAt: now,
    );
    final data = incident.toFirestore();
    expect(data['titleLowercase'], 'leaking pipe');
    expect(data['status'], 'submitted');
  });
}
