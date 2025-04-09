import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapd722_project/PatientListScreen.dart';

void main() {
  testWidgets('PatientListScreen UI elements appear correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PatientListPage()));

    // Check if AppBar has 'Patient List' title
    expect(find.text('Patient List'), findsOneWidget);

    // Check if search bar exists
    expect(find.byType(TextField), findsOneWidget);

    // Check if search icon exists
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Check if the icon of adding patient exists
    expect(find.byIcon(Icons.person_add), findsOneWidget);

    // Check if CircularProgressIndicator displays
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
