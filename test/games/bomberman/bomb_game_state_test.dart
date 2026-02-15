import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';

void main() {
  BombGameState baseState() {
    return BombGameState(
      grid: MapGenerator.generate(seed: 0),
      players: const [
        BombPlayer(id: 0, x: 1, y: 1),
        BombPlayer(id: 1, x: 13, y: 1, isBot: true, isAlive: false),
      ],
      roundWins: const [1, 0],
      phase: GamePhase.playing,
    );
  }

  group('BombGameState — player counts', () {
    test('aliveCount counts only living non-ghost players', () {
      final state = baseState();
      expect(state.aliveCount, equals(1)); // player 1 is dead
    });

    test('livingCount excludes ghosts even when isAlive is true', () {
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 0),
        players: const [
          BombPlayer(id: 0, x: 1, y: 1, isAlive: true, isGhost: false),
          BombPlayer(id: 1, x: 3, y: 1, isAlive: true, isGhost: true),
          BombPlayer(id: 2, x: 5, y: 1, isAlive: false),
        ],
        roundWins: const [0, 0, 0],
      );
      // Only player 0 counts — player 1 is ghost, player 2 is dead
      expect(state.livingCount, equals(1));
    });

    test('activeCount includes ghosts (alive=true regardless of isGhost)', () {
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 0),
        players: const [
          BombPlayer(id: 0, x: 1, y: 1, isAlive: true, isGhost: false),
          BombPlayer(id: 1, x: 3, y: 1, isAlive: true, isGhost: true),
          BombPlayer(id: 2, x: 5, y: 1, isAlive: false),
        ],
        roundWins: const [0, 0, 0],
      );
      expect(state.activeCount, equals(2)); // players 0 and 1
    });

    test('aliveCount is alias for livingCount', () {
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 0),
        players: const [
          BombPlayer(id: 0, x: 1, y: 1, isGhost: true),
          BombPlayer(id: 1, x: 3, y: 1),
        ],
        roundWins: const [0, 0],
      );
      expect(state.aliveCount, equals(state.livingCount));
    });

    test('playerCount is total regardless of alive/ghost status', () {
      final state = baseState();
      expect(state.playerCount, equals(2));
    });

    test('localPlayer is first player', () {
      final state = baseState();
      expect(state.localPlayer?.id, equals(0));
    });

    test('localPlayer is null when players list is empty', () {
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 0),
        players: const [],
        roundWins: const [],
      );
      expect(state.localPlayer, isNull);
    });
  });

  group('BombGameState.copyWith', () {
    test('preserves unmodified fields', () {
      final state = baseState();
      final copy = state.copyWith(round: 2);
      expect(copy.round, equals(2));
      expect(copy.players.length, equals(state.players.length));
      expect(copy.phase, equals(state.phase));
      expect(copy.roundWins, equals(state.roundWins));
    });

    test(
      'clearWinner: true clears winnerId even when a new winnerId is passed',
      () {
        final state = baseState().copyWith(winnerId: 0);
        final cleared = state.copyWith(clearWinner: true);
        expect(cleared.winnerId, isNull);
      },
    );

    test('clearWinner: false preserves existing winnerId', () {
      final state = baseState().copyWith(winnerId: 1);
      final copy = state.copyWith(round: 2);
      expect(copy.winnerId, equals(1));
    });

    test('clearRoundOverMessage: true clears message', () {
      final state = baseState().copyWith(roundOverMessage: 'test');
      final cleared = state.copyWith(clearRoundOverMessage: true);
      expect(cleared.roundOverMessage, isNull);
    });

    test('clearRoundOverMessage: false preserves existing message', () {
      final state = baseState().copyWith(roundOverMessage: 'hello');
      final copy = state.copyWith(round: 2);
      expect(copy.roundOverMessage, equals('hello'));
    });

    test('winnerId 0 is preserved (falsy but valid)', () {
      final state = baseState().copyWith(winnerId: 0);
      expect(state.winnerId, equals(0));
      final copy = state.copyWith(round: 2);
      expect(copy.winnerId, equals(0));
    });

    test(
      'multiple flags simultaneously: clearWinner and clearRoundOverMessage',
      () {
        final state = baseState().copyWith(winnerId: 1, roundOverMessage: 'hi');
        final cleared = state.copyWith(
          clearWinner: true,
          clearRoundOverMessage: true,
        );
        expect(cleared.winnerId, isNull);
        expect(cleared.roundOverMessage, isNull);
      },
    );

    test('passing empty lists replaces non-empty lists', () {
      final state = baseState();
      final copy = state.copyWith(bombs: const [], explosions: const []);
      expect(copy.bombs, isEmpty);
      expect(copy.explosions, isEmpty);
    });
  });

  group('BombPlayer', () {
    test('canPlaceBomb true when alive and under limit', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, maxBombs: 2, activeBombs: 1);
      expect(p.canPlaceBomb, isTrue);
    });

    test('canPlaceBomb false when at bomb limit', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, maxBombs: 1, activeBombs: 1);
      expect(p.canPlaceBomb, isFalse);
    });

    test('canPlaceBomb false when dead', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, isAlive: false);
      expect(p.canPlaceBomb, isFalse);
    });

    test(
      'canPlaceBomb true for ghost player — ghost restriction is enforced by notifier, not model',
      () {
        // Ghost players: isAlive=true, isGhost=true.
        // The model's canPlaceBomb only checks isAlive and activeBombs < maxBombs.
        // Ghost-specific bomb restrictions are applied in BombermanNotifier, not here.
        const p = BombPlayer(
          id: 0,
          x: 1,
          y: 1,
          isAlive: true,
          isGhost: true,
          maxBombs: 2,
          activeBombs: 0,
        );
        expect(p.canPlaceBomb, isTrue);
      },
    );

    test('gridX and gridY floor positive floats', () {
      const p = BombPlayer(id: 0, x: 3.7, y: 2.3);
      expect(p.gridX, equals(3));
      expect(p.gridY, equals(2));
    });

    test('gridX and gridY floor exact integers', () {
      const p = BombPlayer(id: 0, x: 4.0, y: 6.0);
      expect(p.gridX, equals(4));
      expect(p.gridY, equals(6));
    });

    test('equality is by id only — position differences are ignored', () {
      const p1 = BombPlayer(id: 0, x: 1, y: 1);
      const p2 = BombPlayer(id: 0, x: 5, y: 5);
      expect(p1, equals(p2));
    });

    test('players with different ids are not equal', () {
      const p1 = BombPlayer(id: 0, x: 1, y: 1);
      const p2 = BombPlayer(id: 1, x: 1, y: 1);
      expect(p1, isNot(equals(p2)));
    });

    test('hasShield defaults to false', () {
      const p = BombPlayer(id: 0, x: 1, y: 1);
      expect(p.hasShield, isFalse);
    });

    test('copyWith hasShield sets shield correctly', () {
      const p = BombPlayer(id: 0, x: 1, y: 1);
      final shielded = p.copyWith(hasShield: true);
      expect(shielded.hasShield, isTrue);
      final consumed = shielded.copyWith(hasShield: false);
      expect(consumed.hasShield, isFalse);
    });
  });
}
