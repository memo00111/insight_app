// This is a basic Flutter widget test for Insight App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insight_version_8/main.dart';

void main() {
  testWidgets('Insight App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InsightApp(isFirstLaunch: false));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Wait for any initial async operations to complete
    await tester.pumpAndSettle();

    // Verify that we can find some basic UI elements
    // This is a simple smoke test to ensure the app initializes properly
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });

  testWidgets('App navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InsightApp(isFirstLaunch: false));
    
    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Test that the app doesn't crash on startup
    expect(tester.takeException(), isNull);
  });
}
