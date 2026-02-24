/// Integration test: Ludo — idle screen → start solo game → board renders
///
/// Run with:
///   flutter test integration_test/ludo_flow_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:multigame/games/ludo/models/ludo_enums.dart';
import 'package:multigame/games/ludo/providers/ludo_notifier.dart';
import 'package:multigame/games/ludo/screens/ludo_game_screen.dart';
import 'package:multigame/games/ludo/widgets/ludo_mode_selector.dart';
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
    child: const MaterialApp(home: LudoGamePage()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ludo game flow', () {
    testWidgets('idle screen shows mode selector', (tester) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(LudoModeSelector), findsOneWidget);
    });

    testWidgets('starting solo game transitions out of idle phase', (
      tester,
    ) async {
      await tester.pumpWidget(_buildUnderTest());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(LudoGamePage));
      final container = ProviderScope.containerOf(element);

      // Start a solo game programmatically (mirrors tapping the Play button)
      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.easy);
      await tester.pumpAndSettle();

      final state = container.read(ludoProvider);
      expect(state.phase, isNot(LudoPhase.idle));
      expect(state.players.length, equals(4));
      // Red (index 0) is the human player
      expect(state.players.first.isBot, isFalse);
    });

  });
}
