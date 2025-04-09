import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapd722_project/AddMeasurementScreen.dart';

void main() {
  testWidgets('AddMeasurementPage UI renders and responds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddMeasurementPage(
          patientId: '123',
          patientName: 'John Doe',
        ),
      ),
    );

    // Check title
    expect(find.text('Add Measurement'), findsOneWidget);

    // Default type is Blood Pressure, check systolic/diastolic fields exist
    expect(find.text('Systolic'), findsOneWidget);
    expect(find.text('Diastolic'), findsOneWidget);

    // Click dropdown and change to Heartbeat Rate
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heartbeat Rate').last);
    await tester.pump();

    // Check heartbeat input field and bpm
    expect(find.textContaining('Enter Heartbeat'), findsOneWidget);
    expect(find.text('bpm'), findsOneWidget);

    // Check if submit button exist
    expect(find.text('Submit'), findsOneWidget);
  });
}
