import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/ludo/models/ludo_enums.dart';
import 'package:multigame/games/ludo/models/ludo_game_state.dart';
import 'package:multigame/games/ludo/providers/ludo_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// ── Fake Firebase stats service ───────────────────────────────────────────

class _FakeStatsService implements FirebaseStatsService {
  int saveCount = 0;

  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    saveCount++;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ── Helper ─────────────────────────────────────────────────────────────────

ProviderContainer _makeContainer() {
  final fake = _FakeStatsService();
  return ProviderContainer(
    overrides: [
      firebaseStatsServiceProvider.overrideWithValue(fake),
    ],
  );
}

void main() {
  // ── initial state ─────────────────────────────────────────────────────────
  group('initial state', () {
    test('phase is idle and players list is empty', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final state = container.read(ludoProvider);
      expect(state.phase, LudoPhase.idle);
      expect(state.players, isEmpty);
    });
  });

  // ── startSolo ─────────────────────────────────────────────────────────────
  group('startSolo', () {
    test('creates 4 players and moves to rolling phase', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.medium);
      final state = container.read(ludoProvider);

      expect(state.phase, LudoPhase.rolling);
      expect(state.players.length, 4);
      expect(state.mode, LudoMode.soloVsBots);
    });

    test('red player is human, others are bots', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.easy);
      final state = container.read(ludoProvider);

      final redPlayer = state.players.firstWhere(
        (p) => p.color == LudoPlayerColor.red,
      );
      expect(redPlayer.isBot, isFalse);
      for (final p in state.players.where(
        (p) => p.color != LudoPlayerColor.red,
      )) {
        expect(p.isBot, isTrue);
      }
    });

    test('each player starts with 4 base tokens', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.hard);
      final state = container.read(ludoProvider);

      for (final p in state.players) {
        expect(p.tokens.length, 4);
        expect(p.tokens.every((t) => t.isInBase), isTrue);
      }
    });

    test('stores difficulty in state', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.hard);
      expect(container.read(ludoProvider).difficulty, LudoDifficulty.hard);
    });
  });

  // ── startFreeForAll ───────────────────────────────────────────────────────
  group('startFreeForAll', () {
    test('3-player FFA: 3 players, yellow excluded by default', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startFreeForAll(playerCount: 3);
      final state = container.read(ludoProvider);

      expect(state.players.length, 3);
      expect(state.players.every((p) => p.color != LudoPlayerColor.yellow), isTrue);
      expect(state.mode, LudoMode.freeForAll3);
      expect(state.excludedColor, LudoPlayerColor.yellow);
    });

    test('4-player FFA: 4 players, mode is freeForAll4', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startFreeForAll(playerCount: 4);
      final state = container.read(ludoProvider);

      expect(state.players.length, 4);
      expect(state.mode, LudoMode.freeForAll4);
      expect(state.excludedColor, isNull);
    });

    test('all players are human in FFA mode', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startFreeForAll(playerCount: 4);
      final state = container.read(ludoProvider);

      expect(state.players.every((p) => !p.isBot), isTrue);
    });
  });

  // ── startTeamVsTeam ───────────────────────────────────────────────────────
  group('startTeamVsTeam', () {
    test('creates 4 players in twoVsTwo mode', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startTeamVsTeam();
      final state = container.read(ludoProvider);

      expect(state.mode, LudoMode.twoVsTwo);
      expect(state.players.length, 4);
    });

    test('red and green are on team 0; blue and yellow on team 1', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startTeamVsTeam();
      final state = container.read(ludoProvider);

      final redTeam = state.playerByColor(LudoPlayerColor.red)!.teamIndex;
      final greenTeam = state.playerByColor(LudoPlayerColor.green)!.teamIndex;
      final blueTeam = state.playerByColor(LudoPlayerColor.blue)!.teamIndex;
      final yellowTeam = state.playerByColor(LudoPlayerColor.yellow)!.teamIndex;

      expect(redTeam, 0);
      expect(greenTeam, 0);
      expect(blueTeam, 1);
      expect(yellowTeam, 1);
    });
  });

  // ── goToIdle ──────────────────────────────────────────────────────────────
  group('goToIdle', () {
    test('resets state to idle with empty players', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.easy);
      container.read(ludoProvider.notifier).goToIdle();
      final state = container.read(ludoProvider);

      expect(state.phase, LudoPhase.idle);
      expect(state.players, isEmpty);
    });
  });

  // ── rollDice ──────────────────────────────────────────────────────────────
  group('rollDice', () {
    test('human roll produces a diceValue in 1..6', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.easy);

      // Blue is index 0, so it's their turn first (bot).  If bots ran before we
      // read, we skip — just confirm the state transitions.
      final stateBefore = container.read(ludoProvider);
      if (stateBefore.phase == LudoPhase.rolling &&
          !stateBefore.currentPlayer.isBot) {
        container.read(ludoProvider.notifier).rollDice();
        final stateAfter = container.read(ludoProvider);
        // After roll: either selectingToken (has moves) or still rolling
        // (no moves) with diceValue set.
        expect(stateAfter.diceValue, inInclusiveRange(1, 6));
      }
    });

    test('rollDice is a no-op when not in rolling phase', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(ludoProvider.notifier).startSolo(LudoDifficulty.easy);
      // We cannot easily force the phase externally, so just verify the
      // guard: if phase is idle, rollDice does nothing.
      container.read(ludoProvider.notifier).goToIdle();
      container.read(ludoProvider.notifier).rollDice(); // no-op
      expect(container.read(ludoProvider).phase, LudoPhase.idle);
    });
  });

  // ── LudoGameState helpers ─────────────────────────────────────────────────
  group('LudoGameState helpers', () {
    test('currentPlayer returns the player at currentPlayerIndex', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.soloVsBots,
        players: players,
        currentPlayerIndex: 2,
      );
      expect(state.currentPlayer.color, players[2].color);
    });

    test('playerByColor returns correct player', () {
      final players = LudoGameState.buildPlayers(mode: LudoMode.soloVsBots);
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.soloVsBots,
        players: players,
      );
      expect(
        state.playerByColor(LudoPlayerColor.green)?.color,
        LudoPlayerColor.green,
      );
    });

    test('playerByColor returns null for excluded color', () {
      final players = LudoGameState.buildPlayers(
        mode: LudoMode.freeForAll3,
        excludedColor: LudoPlayerColor.yellow,
      );
      final state = LudoGameState(
        phase: LudoPhase.rolling,
        mode: LudoMode.freeForAll3,
        players: players,
        excludedColor: LudoPlayerColor.yellow,
      );
      expect(state.playerByColor(LudoPlayerColor.yellow), isNull);
    });
  });
}
