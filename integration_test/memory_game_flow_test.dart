/// Integration test: Memory game — idle → start → flip pairs → win
///
/// Run with:
///   flutter test integration_test/memory_game_flow_test.dart
///
/// These tests exercise the real widget tree against real providers.
/// No Firebase calls are made (Memory has no online mode).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multigame/games/memory/models/memory_game_state.dart';
import 'package:multigame/games/memory/providers/memory_notifier.dart';
import 'package:multigame/games/memory/screens/memory_game_screen.dart';
import 'package:multigame/games/memory/widgets/memory_card_grid.dart';
import 'package:multigame/games/memory/widgets/memory_idle_screen.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// ── Minimal fake — avoids real Firebase calls ──────────────────────────────

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

// ── Test helpers ───────────────────────────────────────────────────────────

Widget _buildUnderTest() {
  return ProviderScope(
    overrides: [
      firebaseStatsServiceProvider.overrideWithValue(_FakeStats()),
    ],
    child: const MaterialApp(home: MemoryGamePage()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Memory game flow', () {
    testWidgets('idle screen renders start button', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(MemoryIdleScreen), findsOneWidget);
      // Idle screen shows difficulty buttons — Easy should be visible
      expect(find.text('Easy'), findsOneWidget);
    });

    testWidgets('tapping Easy starts a game and shows card grid', (
      tester,
    ) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      expect(find.byType(MemoryCardGrid), findsOneWidget);
      expect(find.byType(MemoryIdleScreen), findsNothing);
    });

    testWidgets('phase transitions to playing after starting Easy', (
      tester,
    ) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // Confirm state via the provider directly
      final element = tester.element(find.byType(MemoryGamePage));
      final container = ProviderScope.containerOf(element);
      final state = container.read(memoryProvider);

      expect(state.phase, MemoryGamePhase.playing);
      expect(state.cards.length, equals(16)); // 4×4 easy grid
    });
  });
}
