import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapd722_project/AddPatientScreen.dart';

void main() {
  testWidgets('AddPatientPage UI and form validation test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPatientPage()));

    // Check title
    expect(find.text('Add Patient'), findsOneWidget);

    // Check all the input fields
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Emergency Contact'), findsOneWidget);
    expect(find.text('Medical History'), findsOneWidget);
    expect(find.text('Allergies'), findsOneWidget);

    // Check gender and blood type dropdowns
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Blood Type'), findsOneWidget);

    // Check if submit button exists
    expect(find.text('Submit'), findsOneWidget);

    // Test clicking submit button
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.text('Age is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Emergency Contact is required'), findsOneWidget);
    expect(find.text('Gender is required'), findsOneWidget);
    expect(find.text('Blood Type is required'), findsOneWidget);
  });
}
