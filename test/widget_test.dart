import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travid/main.dart'; // adjust this path to your actual app package

void main() {
  testWidgets('Travid Voice Assistant - Initial UI and Welcome Speech', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(TravidApp());

    // ✅ Verify the welcome note appears once
    expect(
      find.textContaining('Welcome to Travid', findRichText: true),
      findsOneWidget,
    );

    // ✅ Verify that the assistant is in listening mode
    expect(find.text('Listening...'), findsOneWidget);

    // ✅ Verify that the mic icon or animation widget exists
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // ✅ Optionally, ensure the home tab is visible
    expect(find.text('Home'), findsOneWidget);

    // ✅ Ensure the navigation bar has all tabs
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Maps'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
