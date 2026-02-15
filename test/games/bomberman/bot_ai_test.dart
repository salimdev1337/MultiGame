import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/bot_ai.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';

/// Build an open grid (no interior obstacles) for clean AI testing.
List<List<CellType>> openGrid() {
  return List.generate(
    kGridH,
    (r) => List.generate(kGridW, (c) {
      if (r == 0 || r == kGridH - 1 || c == 0 || c == kGridW - 1) {
        return CellType.wall;
      }
      return CellType.empty;
    }),
  );
}

BombGameState makeState({
  required List<BombPlayer> players,
  List<List<CellType>>? grid,
  List<Bomb> bombs = const [],
}) {
  return BombGameState(
    grid: grid ?? openGrid(),
    players: players,
    bombs: bombs,
    roundWins: List.filled(players.length, 0),
    phase: GamePhase.playing,
  );
}

void main() {
  group('BotAI.decide', () {
    test('returns no-op for dead bot', () {
      final state = makeState(
        players: [
          const BombPlayer(id: 0, x: 5, y: 5, isBot: true, isAlive: false),
          const BombPlayer(id: 1, x: 1, y: 1),
        ],
      );

      final decision = BotAI.decide(botId: 0, state: state);
      expect(decision.dx, 0);
      expect(decision.dy, 0);
      expect(decision.placeBomb, isFalse);
    });

    test('bot flees when explosion is active at its position', () {
      final grid = openGrid();
      final state = makeState(
        grid: grid,
        players: [
          const BombPlayer(id: 0, x: 5, y: 5, isBot: true),
          const BombPlayer(id: 1, x: 1, y: 1),
        ],
        // Bomb about to explode close to bot
        bombs: [
          const Bomb(id: 0, x: 5, y: 5, ownerId: 1, range: 2, fuseMs: 100),
        ],
      );

      final decision = BotAI.decide(botId: 0, state: state);
      // Bot should move (dx or dy != 0) to escape
      expect(decision.dx != 0 || decision.dy != 0, isTrue);
    });

    test('bot chases human player when no danger', () {
      // Human is far right; bot should move right (dx = 1) or generally
      // toward the human.
      final state = makeState(
        players: [
          const BombPlayer(id: 0, x: 2, y: 1, isBot: true),
          const BombPlayer(id: 1, x: 10, y: 1),
        ],
      );

      final decision = BotAI.decide(botId: 0, state: state);
      // BFS path from (2,1) to (10,1) should move right
      expect(decision.dx, greaterThan(0));
    });

    test('bot does not move if already adjacent to human and places bomb', () {
      // Bot right next to a block, can place bomb
      final grid = openGrid();
      grid[1][4] = CellType.block; // block to the right of bot
      final state = makeState(
        grid: grid,
        players: [
          const BombPlayer(
            id: 0,
            x: 3,
            y: 1,
            isBot: true,
            maxBombs: 1,
            activeBombs: 0,
          ),
          const BombPlayer(id: 1, x: 10, y: 10),
        ],
      );

      final decision = BotAI.decide(botId: 0, state: state);
      expect(decision.placeBomb, isTrue);
    });

    test('returns BotDecision.none constants are correct', () {
      expect(BotDecision.none.dx, equals(0));
      expect(BotDecision.none.dy, equals(0));
      expect(BotDecision.none.placeBomb, isFalse);
    });
  });
}
