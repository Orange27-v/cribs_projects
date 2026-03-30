// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cribs_arena/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(CribsArenaApp(navigatorKey: navigatorKey));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Simple verification that something rendered
    // expect(find.byType(MaterialApp), findsOneWidget);
  });
}
