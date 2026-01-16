import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle/screens/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProfilePage Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'total_completed': 5,
        'best_3x3_moves': 85,
        'best_4x4_moves': 150,
        'best_5x5_moves': 250,
        'best_3x3_time': 45,
        'best_4x4_time': 90,
        'best_5x5_time': 180,
      });
    });

    testWidgets('renders profile header', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('Puzzle Master'), findsOneWidget);
      expect(find.text('🎮'), findsOneWidget);
    });

    testWidgets('displays total completed puzzles', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('5 Puzzles Completed'), findsOneWidget);
    });

    testWidgets('displays statistics section', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Best Times'), findsOneWidget);
      expect(find.text('Best Moves'), findsOneWidget);
    });

    testWidgets('shows grid size labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(
        find.text('3x3 Grid'),
        findsNWidgets(2),
      ); // In both Best Times and Best Moves
      expect(find.text('4x4 Grid'), findsNWidgets(2));
      expect(find.text('5x5 Grid'), findsNWidgets(2));
    });

    testWidgets('displays best moves stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('85'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('displays best time stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('0m 45s'), findsOneWidget);
      expect(find.text('1m 30s'), findsOneWidget);
      expect(find.text('3m 0s'), findsOneWidget);
    });

    testWidgets('shows -- for unset stats', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      expect(find.text('--'), findsWidgets);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can pull to refresh', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
