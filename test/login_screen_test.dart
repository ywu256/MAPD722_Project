import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapd722_project/LoginScreen.dart';

void main() {
  testWidgets('LoginScreen UI test', (WidgetTester tester) async {
    // Load the screen
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Check if username and password exist
    expect(find.text('Enter Username'), findsOneWidget);
    expect(find.text('Enter Password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Check if Login button exists
    expect(find.text('Login'), findsOneWidget);

    // Enter email and password
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');

    // Click Login button
    await tester.tap(find.text('Login'));
    await tester.pump();
  });
}
