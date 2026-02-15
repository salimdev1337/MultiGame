import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';

BombGameState _testState() {
  final grid = MapGenerator.generate(seed: 42);
  return BombGameState(
    grid: grid,
    players: const [
      BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'Alice'),
      BombPlayer(id: 1, x: 13.5, y: 1.5, displayName: 'Bob'),
    ],
    bombs: const [Bomb(id: 0, x: 3, y: 3, ownerId: 0, range: 2, fuseMs: 2000)],
    explosions: const [ExplosionTile(x: 2, y: 2, remainingMs: 200)],
    powerups: const [PowerupCell(x: 5, y: 5, type: PowerupType.speed)],
    phase: GamePhase.playing,
    countdown: 0,
    roundTimeSeconds: 120,
    round: 1,
    roundWins: [0, 0],
  );
}

void main() {
  group('BombGameState JSON', () {
    test('toFrameJson / applyFrameSync round-trip is a no-op', () {
      final original = _testState();
      final frame = original.toFrameJson();
      final restored = original.applyFrameSync(frame);

      // Dynamic fields must match
      expect(restored.players.length, original.players.length);
      expect(restored.players[0].x, original.players[0].x);
      expect(restored.players[0].y, original.players[0].y);
      expect(restored.players[0].displayName, original.players[0].displayName);
      expect(restored.players[1].id, original.players[1].id);

      expect(restored.bombs.length, original.bombs.length);
      expect(restored.bombs[0].x, original.bombs[0].x);
      expect(restored.bombs[0].fuseMs, original.bombs[0].fuseMs);

      expect(restored.explosions.length, original.explosions.length);
      expect(
        restored.explosions[0].remainingMs,
        original.explosions[0].remainingMs,
      );

      expect(restored.powerups.length, original.powerups.length);
      expect(restored.powerups[0].type, original.powerups[0].type);

      expect(restored.phase, original.phase);
      expect(restored.roundTimeSeconds, original.roundTimeSeconds);
      expect(restored.round, original.round);
      expect(restored.roundWins, original.roundWins);

      // Grid is preserved (not replaced by applyFrameSync)
      expect(restored.grid, original.grid);
    });

    test('applyFrameSync preserves the original grid', () {
      final original = _testState();
      // Make a different state with a different phase
      final hostState = original.copyWith(
        phase: GamePhase.roundOver,
        roundOverMessage: 'Alice wins!',
      );
      final frame = hostState.toFrameJson();

      final guestRestored = original.applyFrameSync(frame);

      // Phase must come from the frame
      expect(guestRestored.phase, GamePhase.roundOver);
      expect(guestRestored.roundOverMessage, 'Alice wins!');

      // Grid must be the original guest grid (unchanged)
      expect(guestRestored.grid, original.grid);
    });

    test('toFullJson / fromFullJson round-trip includes grid', () {
      final original = _testState();
      final json = original.toFullJson();
      final restored = BombGameState.fromFullJson(json);

      for (int row = 0; row < kGridH; row++) {
        for (int col = 0; col < kGridW; col++) {
          expect(
            restored.grid[row][col],
            original.grid[row][col],
            reason: 'grid[$row][$col] mismatch',
          );
        }
      }
      expect(restored.players.length, original.players.length);
      expect(restored.round, original.round);
    });

    test('winnerId null is preserved through applyFrameSync', () {
      final original = _testState();
      final frame = original
          .copyWith(clearWinner: true, clearRoundOverMessage: true)
          .toFrameJson();

      final restored = original.copyWith(winnerId: 99).applyFrameSync(frame);
      expect(restored.winnerId, isNull);
    });

    test('winnerId non-null is preserved through applyFrameSync', () {
      final original = _testState();
      final withWinner = original.copyWith(
        phase: GamePhase.gameOver,
        winnerId: 1,
        roundOverMessage: 'Bob wins!',
      );
      final frame = withWinner.toFrameJson();
      final restored = original.applyFrameSync(frame);

      expect(restored.winnerId, 1);
      expect(restored.roundOverMessage, 'Bob wins!');
    });

    test('CellTypeJson toJson/fromJson round-trips all values', () {
      for (final ct in CellType.values) {
        expect(CellTypeJson.fromJson(ct.toJson()), ct);
      }
    });

    test('GamePhaseJson toJson/fromJson round-trips all values', () {
      for (final gp in GamePhase.values) {
        expect(GamePhaseJson.fromJson(gp.toJson()), gp);
      }
    });

    test('PowerupTypeJson toJson/fromJson round-trips all values', () {
      for (final pt in PowerupType.values) {
        expect(PowerupTypeJson.fromJson(pt.toJson()), pt);
      }
    });
  });

  group('BombMessage frameSync / gridUpdate', () {
    test('frameSync encode → decode round-trip', () {
      final state = _testState();
      final frame = state.toFrameJson();
      final msg = BombMessage.frameSync(frame);
      final encoded = msg.encode();

      final decoded = BombMessage.tryDecode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.type, BombMessageType.frameSync);

      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['round'], state.round);
      expect((data['players'] as List).length, state.players.length);
      expect((data['bombs'] as List).length, state.bombs.length);
    });

    test('gridUpdate encode → decode round-trip', () {
      final cells = [
        {'x': 3, 'y': 4, 'type': CellType.empty.index},
        {'x': 5, 'y': 2, 'type': CellType.empty.index},
      ];
      final msg = BombMessage.gridUpdate(cells);
      final encoded = msg.encode();

      final decoded = BombMessage.tryDecode(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.type, BombMessageType.gridUpdate);

      final cellList = (decoded.payload['cells'] as List)
          .cast<Map<String, dynamic>>();
      expect(cellList.length, 2);
      expect(cellList[0]['x'], 3);
      expect(cellList[0]['y'], 4);
      expect(cellList[1]['x'], 5);
    });

    test('frameSync with winnerId null survives encode/decode', () {
      final state = _testState();
      final frame = state.toFrameJson();
      expect(frame['winnerId'], isNull);

      final encoded = BombMessage.frameSync(frame).encode();
      final decoded = BombMessage.tryDecode(encoded)!;
      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['winnerId'], isNull);
    });
  });
}
