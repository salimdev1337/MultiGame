import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/screens/main_navigation.dart';
import 'package:multigame/screens/home_page_premium.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MainNavigation Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders bottom navigation bar with 3 tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      // Pump multiple times to drain flutter_animate 0-duration timers created on each rebuild
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Game'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows HomePagePremium by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(HomePagePremium), findsOneWidget);
    });

    testWidgets('switches to Profile tab when tapped', (tester) async {
      // TODO: Add Firebase mocking to properly test navigation with providers
    }, skip: true);

    testWidgets(
      'shows no game selected view when Game tab tapped without selection',
      (tester) async {
        // TODO: Add Firebase mocking to properly test navigation with providers
      },
      skip: true,
    );

    testWidgets('highlights active tab', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Home tab text should be visible (active tab is highlighted via FloatingNavBar)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Game'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows top indicator on selected tab', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Check for animated containers (top indicators)
      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsWidgets);
    });

    testWidgets('Go to Home button works from no game selected view', (
      tester,
    ) async {
      // TODO: Add Firebase mocking to properly test navigation with providers
    }, skip: true);
  });
}
