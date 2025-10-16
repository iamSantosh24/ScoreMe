// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scorer/main.dart';

void main() {
  testWidgets('App shows Login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // The LoginScreen may show a loading indicator while credentials load,
    // or show the Login UI. Accept either to make the test resilient.
    await tester.pump();
    final hasLoginText = find.text('Login').evaluate().isNotEmpty;
    final hasSpinner = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    expect(hasLoginText || hasSpinner, isTrue);
  });
}
