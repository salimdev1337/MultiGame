import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/screens/home_page.dart';
import 'package:puzzle/widgets/game_carousel.dart';
import 'package:puzzle/widgets/achievement_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HomePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'total_completed': 3,
        'achievement_first_win': true,
      });
    });

    testWidgets('renders welcome header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back,'), findsOneWidget);
      expect(find.text('Puzzle Master'), findsOneWidget);
    });

    testWidgets('displays game carousel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameCarousel), findsOneWidget);
    });

    testWidgets('displays achievements section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Achievements'), findsOneWidget);
      expect(find.text('🏆'), findsOneWidget);
    });

    testWidgets('shows achievement cards after loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AchievementCard), findsWidgets);
    });

    testWidgets('shows total completed count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('👑 3'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can pull to refresh', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomePage(onGameSelected: (_) {})),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
