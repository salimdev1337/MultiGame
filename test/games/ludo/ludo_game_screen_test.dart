import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/ludo/models/ludo_enums.dart';
import 'package:multigame/games/ludo/models/ludo_game_state.dart';
import 'package:multigame/games/ludo/models/ludo_player.dart';
import 'package:multigame/games/ludo/providers/ludo_notifier.dart';
import 'package:multigame/games/ludo/screens/ludo_game_screen.dart';
import 'package:multigame/games/ludo/widgets/ludo_mode_selector.dart';
import 'package:multigame/games/ludo/widgets/ludo_won_screen.dart';
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

class _FakeLudoNotifier extends LudoNotifier {
  final LudoGameState _fixed;
  _FakeLudoNotifier(this._fixed);

  @override
  LudoGameState build() => _fixed;
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrap(LudoGameState state) {
  return ProviderScope(
    overrides: [
      firebaseStatsServiceProvider.overrideWithValue(_FakeStatsService()),
      ludoProvider.overrideWith(() => _FakeLudoNotifier(state)),
    ],
    child: const MaterialApp(home: LudoGamePage()),
  );
}

List<LudoPlayer> _fourPlayers() => [
      LudoPlayer.initial(
        color: LudoPlayerColor.red,
        name: 'Red',
        isBot: false,
      ),
      LudoPlayer.initial(
        color: LudoPlayerColor.blue,
        name: 'Blue',
        isBot: true,
      ),
      LudoPlayer.initial(
        color: LudoPlayerColor.green,
        name: 'Green',
        isBot: true,
      ),
      LudoPlayer.initial(
        color: LudoPlayerColor.yellow,
        name: 'Yellow',
        isBot: true,
      ),
    ];

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  testWidgets('idle phase renders LudoModeSelector', (tester) async {
    await tester.pumpWidget(_wrap(const LudoGameState()));
    await tester.pump();

    expect(find.byType(LudoModeSelector), findsOneWidget);
    expect(find.byType(LudoWonScreen), findsNothing);
  });

  testWidgets('rolling phase renders board, not idle or won', (tester) async {
    await tester.pumpWidget(_wrap(
      LudoGameState(phase: LudoPhase.rolling, players: _fourPlayers()),
    ));
    await tester.pump();

    expect(find.byType(LudoModeSelector), findsNothing);
    expect(find.byType(LudoWonScreen), findsNothing);
  });

  testWidgets('won phase renders LudoWonScreen', (tester) async {
    await tester.pumpWidget(_wrap(
      const LudoGameState(phase: LudoPhase.won),
    ));
    await tester.pump();

    expect(find.byType(LudoWonScreen), findsOneWidget);
    expect(find.byType(LudoModeSelector), findsNothing);
  });
}
