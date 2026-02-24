import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/memory/models/memory_game_state.dart';
import 'package:multigame/games/memory/providers/memory_notifier.dart';
import 'package:multigame/games/memory/screens/memory_game_screen.dart';
import 'package:multigame/games/memory/widgets/memory_card_grid.dart';
import 'package:multigame/games/memory/widgets/memory_idle_screen.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeStatsService implements FirebaseStatsService {
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

class _FakeMemoryNotifier extends MemoryNotifier {
  final MemoryGameState _fixed;
  _FakeMemoryNotifier(this._fixed);

  @override
  MemoryGameState build() => _fixed;
}

// ── Helper ─────────────────────────────────────────────────────────────────

Widget _wrap(MemoryGameState state) {
  return ProviderScope(
    overrides: [
      firebaseStatsServiceProvider.overrideWithValue(_FakeStatsService()),
      memoryProvider.overrideWith(() => _FakeMemoryNotifier(state)),
    ],
    child: const MaterialApp(home: MemoryGamePage()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  testWidgets('idle phase renders MemoryIdleScreen', (tester) async {
    await tester.pumpWidget(_wrap(const MemoryGameState()));
    await tester.pump();

    expect(find.byType(MemoryIdleScreen), findsOneWidget);
    expect(find.byType(MemoryCardGrid), findsNothing);
  });

  testWidgets('playing phase renders MemoryCardGrid', (tester) async {
    await tester.pumpWidget(_wrap(
      const MemoryGameState(phase: MemoryGamePhase.playing),
    ));
    await tester.pump();

    expect(find.byType(MemoryCardGrid), findsOneWidget);
    expect(find.byType(MemoryIdleScreen), findsNothing);
  });
}
