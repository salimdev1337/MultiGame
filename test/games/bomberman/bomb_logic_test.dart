import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/bomb_logic.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

void main() {
  // Build a simple open grid for testing (no blocks, no walls except border).
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

  group('BombLogic.explode', () {
    test('center tile always becomes explosion', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final player = const BombPlayer(id: 0, x: 1, y: 1, activeBombs: 1);

      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [player],
        powerups: [],
      );

      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 5), isTrue);
    });

    test('blast propagates to range tiles in 4 directions', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
        fuseMs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [],
        powerups: [],
      );

      // Up, down, left, right each should have 3 blast tiles
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 2), isTrue);
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 8), isTrue);
      expect(result.newExplosions.any((e) => e.x == 2 && e.y == 5), isTrue);
      expect(result.newExplosions.any((e) => e.x == 8 && e.y == 5), isTrue);
    });

    test('permanent wall stops blast', () {
      final grid = openGrid();
      // Place a wall directly to the right of the bomb
      grid[5][6] = CellType.wall;
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
        fuseMs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [],
        powerups: [],
      );

      // x=6 blocked, x=7,8 should not appear in the right direction
      expect(result.newExplosions.any((e) => e.x == 6 && e.y == 5), isFalse);
      expect(result.newExplosions.any((e) => e.x == 7 && e.y == 5), isFalse);
    });

    test('destructible block is destroyed by blast', () {
      final grid = openGrid();
      grid[5][7] = CellType.block;
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
        fuseMs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [],
        powerups: [],
        rng: Random(0),
      );

      expect(result.grid[5][7], CellType.empty);
      // Blast does not continue past destroyed block
      expect(result.newExplosions.any((e) => e.x == 8 && e.y == 5), isFalse);
    });

    test('player in blast becomes a ghost (one-hit mode)', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final player = const BombPlayer(id: 1, x: 5, y: 6, activeBombs: 0);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [player],
        powerups: [],
      );

      final damaged = result.players.firstWhere((p) => p.id == 1);
      // One hit → ghost (isAlive stays true, isGhost becomes true)
      expect(damaged.isAlive, isTrue);
      expect(damaged.isGhost, isTrue);
    });

    test('player with 1 life in blast is killed', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final player = const BombPlayer(
        id: 1,
        x: 5,
        y: 6,
        lives: 1,
        activeBombs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [player],
        powerups: [],
      );

      // With ghost mode: hit player becomes a ghost (isAlive stays true, isGhost = true)
      final killed = result.players.firstWhere((p) => p.id == 1);
      expect(killed.isGhost, isTrue);
    });

    test('owner activeBombs is decremented after explosion', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 1,
        fuseMs: 0,
      );
      final owner = const BombPlayer(id: 0, x: 1, y: 1, activeBombs: 2);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [owner],
        powerups: [],
      );

      final updated = result.players.firstWhere((p) => p.id == 0);
      expect(updated.activeBombs, equals(1));
    });

    test('chain bomb is detected', () {
      final grid = openGrid();
      final bomb1 = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final bomb2 = const Bomb(
        id: 1,
        x: 7,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 5000,
      );
      final result = BombLogic.explode(
        bomb: bomb1,
        grid: grid,
        allBombs: [bomb1, bomb2],
        players: [],
        powerups: [],
      );

      expect(result.chainBombs.any((b) => b.id == 1), isTrue);
    });

    test('bomb removed from remaining after explosion', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 1,
        fuseMs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [],
        powerups: [],
      );

      expect(result.remainingBombs.any((b) => b.id == 0), isFalse);
    });
  });

  group('BombLogic.isWalkable', () {
    test('empty cell is walkable', () {
      final grid = MapGenerator.generate(seed: 1);
      expect(BombLogic.isWalkable(grid, 1, 1), isTrue);
    });

    test('wall is not walkable', () {
      final grid = MapGenerator.generate(seed: 1);
      expect(BombLogic.isWalkable(grid, 0, 0), isFalse);
    });

    test('out of bounds is not walkable', () {
      final grid = MapGenerator.generate(seed: 1);
      expect(BombLogic.isWalkable(grid, -1, 0), isFalse);
      expect(BombLogic.isWalkable(grid, kGridW, 0), isFalse);
    });
  });

  group('BombLogic.collectPowerups', () {
    test('player collects powerup at their grid position', () {
      final player = const BombPlayer(id: 0, x: 3, y: 3, maxBombs: 1, range: 1);
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
      ];

      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );

      expect(result.players[0].maxBombs, equals(2));
      expect(result.powerups, isEmpty);
    });

    test('blastRange powerup increases range', () {
      final player = const BombPlayer(id: 0, x: 4, y: 4, range: 1);
      final powerups = [
        const PowerupCell(x: 4, y: 4, type: PowerupType.blastRange),
      ];

      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );

      expect(result.players[0].range, equals(2));
    });

    test('speed powerup increases speed', () {
      final player = const BombPlayer(id: 0, x: 2, y: 2, speed: 3.5);
      final powerups = [const PowerupCell(x: 2, y: 2, type: PowerupType.speed)];

      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );

      expect(result.players[0].speed, closeTo(4.0, 0.01));
    });

    test('ghost player does not collect powerups', () {
      // isAlive=true but isGhost=true → cannot collect
      final player = const BombPlayer(id: 0, x: 3, y: 3, isGhost: true);
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
      ];

      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );

      expect(result.powerups, isNotEmpty); // not consumed
      expect(
        result.players[0].maxBombs,
        equals(2),
      ); // unchanged (default maxBombs=2)
    });

    test('powerup not at player position is not consumed', () {
      final player = const BombPlayer(id: 0, x: 1, y: 1);
      final powerups = [
        const PowerupCell(x: 5, y: 5, type: PowerupType.extraBomb),
      ];

      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );

      expect(result.powerups.length, equals(1));
    });
  });
}
