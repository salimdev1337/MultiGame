/// Integration test: 2048 — start → move → board changes
///
/// Run with:
///   flutter test integration_test/game_2048_flow_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multigame/games/game_2048/providers/game_2048_notifier.dart';
import 'package:multigame/games/game_2048/screens/game_2048_screen.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// ── Fake ───────────────────────────────────────────────────────────────────

class _FakeStats implements FirebaseStatsService {
  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildUnderTest() {
  return ProviderScope(
    overrides: [
      firebaseStatsServiceProvider.overrideWithValue(_FakeStats()),
    ],
    child: const MaterialApp(home: Game2048Page()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('2048 game flow', () {
    testWidgets('game screen renders without crashing', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(Game2048Page), findsOneWidget);
    });

    testWidgets('initial score is 0', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(Game2048Page));
      final container = ProviderScope.containerOf(element);
      final state = container.read(game2048Provider);

      expect(state.score, equals(0));
    });

    testWidgets('move left changes the board', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(Game2048Page));
      final container = ProviderScope.containerOf(element);
      final before = container
          .read(game2048Provider)
          .grid
          .map((row) => List<int>.from(row))
          .toList();

      container.read(game2048Provider.notifier).move('left');
      await tester.pumpAndSettle();

      final after = container.read(game2048Provider).grid;
      expect(after, isNot(equals(before)));
    });
  });
}
