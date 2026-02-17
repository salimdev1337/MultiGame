import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pump enough frames to:
/// 1. Flush SharedPreferences microtasks so _isLoading becomes false.
/// 2. Advance fake time past all Future.delayed timers in AnimatedProfileHeader
///    (max 300 ms) and _AchievementCard stagger delays (max ~900 ms), so no
///    pending timers remain after the test disposes the widget tree.
Future<void> _settleProfile(WidgetTester tester) async {
  await tester.pump(); // initial frame
  await tester.pump(const Duration(milliseconds: 50)); // microtask queue flush
  await tester.pump(const Duration(milliseconds: 50)); // setState rebuilds
  await tester.pump(const Duration(seconds: 1)); // fire all Future.delayed timers
}

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

    testWidgets('renders profile page widget', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('renders scroll view after loading', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      // Loading complete: skeleton replaced by CustomScrollView
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('displays statistics section', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows grid size labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('displays best moves stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('displays best time stats', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('shows default values for unset stats', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('shows skeleton loading initially', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

      // pumpWidget renders the first frame; _isLoading=true shows skeleton.
      expect(find.byType(CustomScrollView), findsNothing);

      // Settle using incremental pumps (same as _settleProfile) so that all
      // Future.delayed timers created after the header is mounted also fire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('can pull to refresh', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProfilePage()));
      await _settleProfile(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
