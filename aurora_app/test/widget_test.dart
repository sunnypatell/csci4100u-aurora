// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurora_app/screens/landing_screen.dart';
import 'package:aurora_app/screens/auth/login_screen.dart';

void main() {
  group('LandingScreen', () {
    testWidgets('renders title and tagline', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      expect(find.text('Aurora'), findsOneWidget);
      expect(
        find.text('A private space to pause, breathe, and\nunderstand your mind.'),
        findsOneWidget,
      );
      expect(find.text('Begin reflection'), findsOneWidget);
    });

    testWidgets('navigates to LoginScreen when Begin tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      await tester.tap(find.text('Begin reflection'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      // Basic sanity: login screen welcome text present.
      expect(find.textContaining('Welcome'), findsOneWidget);
    });
  });
}
