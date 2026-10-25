import 'package:campus_incidents/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('light theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const Text('Campus Incidents')),
    );
    expect(find.text('Campus Incidents'), findsOneWidget);
  });
}
