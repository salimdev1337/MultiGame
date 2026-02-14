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

  group('BombGameState', () {
    test('aliveCount counts only living players', () {
      final state = baseState();
      expect(state.aliveCount, equals(1));
    });

    test('playerCount is total players', () {
      final state = baseState();
      expect(state.playerCount, equals(2));
    });

    test('localPlayer is first player', () {
      final state = baseState();
      expect(state.localPlayer?.id, equals(0));
    });

    test('copyWith preserves unmodified fields', () {
      final state = baseState();
      final copy = state.copyWith(round: 2);
      expect(copy.round, equals(2));
      expect(copy.players.length, equals(state.players.length));
      expect(copy.phase, equals(state.phase));
    });

    test('copyWith(clearWinner: true) clears winnerId', () {
      final state = baseState().copyWith(winnerId: 0);
      final cleared = state.copyWith(clearWinner: true);
      expect(cleared.winnerId, isNull);
    });

    test('copyWith(clearRoundOverMessage: true) clears message', () {
      final state = baseState().copyWith(roundOverMessage: 'test');
      final cleared = state.copyWith(clearRoundOverMessage: true);
      expect(cleared.roundOverMessage, isNull);
    });
  });

  group('BombPlayer', () {
    test('canPlaceBomb is true when alive and under limit', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, maxBombs: 2, activeBombs: 1);
      expect(p.canPlaceBomb, isTrue);
    });

    test('canPlaceBomb is false when at bomb limit', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, maxBombs: 1, activeBombs: 1);
      expect(p.canPlaceBomb, isFalse);
    });

    test('canPlaceBomb is false when dead', () {
      const p = BombPlayer(id: 0, x: 1, y: 1, isAlive: false);
      expect(p.canPlaceBomb, isFalse);
    });

    test('gridX and gridY floor correctly', () {
      // gridX/gridY use floor() — returns the cell the player's centre is inside
      const p = BombPlayer(id: 0, x: 3.7, y: 2.3);
      expect(p.gridX, equals(3)); // floor(3.7) = 3
      expect(p.gridY, equals(2)); // floor(2.3) = 2
    });

    test('equality is by id', () {
      const p1 = BombPlayer(id: 0, x: 1, y: 1);
      const p2 = BombPlayer(id: 0, x: 5, y: 5);
      expect(p1, equals(p2));
    });
  });
}
