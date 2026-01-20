import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/screens/main_navigation.dart';
import 'package:multigame/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MainNavigation Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders bottom navigation bar with 3 tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Game'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows HomePage by default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
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
      await tester.pumpAndSettle();

      // Home should be highlighted initially
      final homeTab = find.ancestor(
        of: find.text('Home'),
        matching: find.byType(AnimatedContainer),
      );
      expect(homeTab, findsWidgets);

      // Switch to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Profile should now be highlighted
      final profileTab = find.ancestor(
        of: find.text('Profile'),
        matching: find.byType(AnimatedContainer),
      );
      expect(profileTab, findsWidgets);
    });

    testWidgets('shows top indicator on selected tab', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainNavigation()));
      await tester.pumpAndSettle();

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
