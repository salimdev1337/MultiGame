import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/bomb_logic.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

// Open grid: border walls only, everything interior is empty.
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

void main() {
  group('BombLogic.explode — blast propagation', () {
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
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [const BombPlayer(id: 0, x: 1, y: 1, activeBombs: 1)],
        powerups: [],
      );
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 5), isTrue);
    });

    test('blast propagates exactly range tiles in all 4 directions', () {
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
      // Up 3, down 3, left 3, right 3
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 2), isTrue);
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 8), isTrue);
      expect(result.newExplosions.any((e) => e.x == 2 && e.y == 5), isTrue);
      expect(result.newExplosions.any((e) => e.x == 8 && e.y == 5), isTrue);
      // Should NOT exceed range
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 1), isFalse);
      expect(result.newExplosions.any((e) => e.x == 5 && e.y == 9), isFalse);
    });

    test('range 1 only hits adjacent tiles', () {
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
      expect(result.newExplosions.length, equals(5)); // center + 4 adj
    });

    test('permanent wall stops blast — tiles beyond wall not hit', () {
      final grid = openGrid();
      grid[5][6] = CellType.wall; // wall directly right of bomb
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
      expect(result.newExplosions.any((e) => e.x == 6 && e.y == 5), isFalse);
      expect(result.newExplosions.any((e) => e.x == 7 && e.y == 5), isFalse);
      // Other directions are unaffected
      expect(result.newExplosions.any((e) => e.x == 2 && e.y == 5), isTrue);
    });

    test('destructible block is destroyed — blast stops at it', () {
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
      // Tile at block is in explosion (block tile itself gets hit)
      expect(result.newExplosions.any((e) => e.x == 7 && e.y == 5), isTrue);
      // Tile behind block is NOT
      expect(result.newExplosions.any((e) => e.x == 8 && e.y == 5), isFalse);
    });

    test('blast at left grid boundary does not go out of bounds', () {
      final grid = openGrid();
      // Bomb right next to left border wall
      final bomb = const Bomb(
        id: 0,
        x: 1,
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
      // Left direction hits wall at x=0, stops immediately
      expect(result.newExplosions.any((e) => e.x == 0 && e.y == 5), isFalse);
    });

    test('blast at top grid boundary does not go out of bounds', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 1,
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
      expect(result.newExplosions.any((e) => e.y == 0), isFalse);
    });

    test(
      'each direction is independent — wall in one dir does not affect others',
      () {
        final grid = openGrid();
        grid[5][8] = CellType.wall; // right direction blocked
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
        expect(result.newExplosions.any((e) => e.x == 8 && e.y == 5), isFalse);
        // Left, up, down still propagate
        expect(result.newExplosions.any((e) => e.x == 2 && e.y == 5), isTrue);
        expect(result.newExplosions.any((e) => e.x == 5 && e.y == 2), isTrue);
        expect(result.newExplosions.any((e) => e.x == 5 && e.y == 8), isTrue);
      },
    );
  });

  group('BombLogic.explode — player damage', () {
    test('player in blast becomes ghost (one-hit mechanic)', () {
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
      expect(damaged.isAlive, isTrue);
      expect(damaged.isGhost, isTrue);
    });

    test('player outside blast range is unharmed', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final player = const BombPlayer(id: 1, x: 5, y: 9); // y=9, range only 2
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [player],
        powerups: [],
      );
      final unharmed = result.players.firstWhere((p) => p.id == 1);
      expect(unharmed.isGhost, isFalse);
      expect(unharmed.isAlive, isTrue);
    });

    test('player with shield absorbs hit — shield consumed, not ghosted', () {
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
        hasShield: true,
        activeBombs: 0,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [player],
        powerups: [],
      );
      final p = result.players.firstWhere((p) => p.id == 1);
      expect(p.isGhost, isFalse); // shield absorbed the hit
      expect(p.hasShield, isFalse); // shield consumed
      expect(p.isAlive, isTrue);
    });

    test('already-ghost player is not affected by normal bomb blast', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final ghost = const BombPlayer(
        id: 1,
        x: 5,
        y: 6,
        isGhost: true,
        isAlive: true,
      );
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [ghost],
        powerups: [],
      );
      final p = result.players.firstWhere((p) => p.id == 1);
      expect(p.isGhost, isTrue); // unchanged
      expect(p.isAlive, isTrue);
    });

    test('dead player is not affected by blast', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final dead = const BombPlayer(id: 1, x: 5, y: 6, isAlive: false);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [dead],
        powerups: [],
      );
      final p = result.players.firstWhere((p) => p.id == 1);
      expect(p.isAlive, isFalse);
      expect(p.isGhost, isFalse);
    });

    test('multiple players — only those in blast are hit', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 2,
        fuseMs: 0,
      );
      final inBlast = const BombPlayer(id: 1, x: 5, y: 6);
      final outOfBlast = const BombPlayer(id: 2, x: 9, y: 9);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [inBlast, outOfBlast],
        powerups: [],
      );
      expect(result.players.firstWhere((p) => p.id == 1).isGhost, isTrue);
      expect(result.players.firstWhere((p) => p.id == 2).isGhost, isFalse);
    });
  });

  group('BombLogic.explode — ghost bombs', () {
    test('ghost bomb destroys blocks but does NOT hurt living players', () {
      final grid = openGrid();
      grid[5][7] = CellType.block;
      final ghostPlayer = const BombPlayer(id: 0, x: 1, y: 1, isGhost: true);
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
        fuseMs: 0,
      );
      final livingTarget = const BombPlayer(id: 1, x: 5, y: 6);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [ghostPlayer, livingTarget],
        powerups: [],
        rng: Random(1),
      );
      // Block destroyed
      expect(result.grid[5][7], CellType.empty);
      // Living player untouched
      expect(result.players.firstWhere((p) => p.id == 1).isGhost, isFalse);
    });

    test('ghost bomb still decrements owner activeBombs', () {
      final grid = openGrid();
      final ghost = const BombPlayer(
        id: 0,
        x: 1,
        y: 1,
        isGhost: true,
        activeBombs: 2,
      );
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
        players: [ghost],
        powerups: [],
      );
      final updated = result.players.firstWhere((p) => p.id == 0);
      expect(updated.activeBombs, equals(1));
    });
  });

  group('BombLogic.explode — chain reactions', () {
    test('chain bomb is detected when in blast path', () {
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

    test('chain bomb not returned if blocked by wall', () {
      final grid = openGrid();
      grid[5][6] = CellType.wall;
      final bomb1 = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
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
      expect(result.chainBombs.any((b) => b.id == 1), isFalse);
    });

    test('multiple chain bombs detected in different directions', () {
      final grid = openGrid();
      final bomb0 = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 3,
        fuseMs: 0,
      );
      final bombRight = const Bomb(
        id: 1,
        x: 7,
        y: 5,
        ownerId: 1,
        range: 2,
        fuseMs: 5000,
      );
      final bombDown = const Bomb(
        id: 2,
        x: 5,
        y: 7,
        ownerId: 1,
        range: 2,
        fuseMs: 5000,
      );
      final result = BombLogic.explode(
        bomb: bomb0,
        grid: grid,
        allBombs: [bomb0, bombRight, bombDown],
        players: [],
        powerups: [],
      );
      expect(result.chainBombs.any((b) => b.id == 1), isTrue);
      expect(result.chainBombs.any((b) => b.id == 2), isTrue);
    });

    test('exploding bomb is removed from remainingBombs', () {
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

    test(
      'chain bomb is in both chainBombs and remainingBombs — caller explodes it next',
      () {
        // The explode() function does not recursively detonate chain bombs.
        // It returns them in chainBombs so the caller can call explode() on each.
        // The chain bomb stays in remainingBombs until the caller processes it.
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
        // bomb2 is also in remainingBombs — the caller removes it when processing chain
        expect(result.remainingBombs.any((b) => b.id == 1), isTrue);
      },
    );
  });

  group('BombLogic.explode — owner activeBombs', () {
    test('activeBombs is decremented after explosion', () {
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
      expect(
        result.players.firstWhere((p) => p.id == 0).activeBombs,
        equals(1),
      );
    });

    test('activeBombs does not go below zero', () {
      final grid = openGrid();
      final bomb = const Bomb(
        id: 0,
        x: 5,
        y: 5,
        ownerId: 0,
        range: 1,
        fuseMs: 0,
      );
      final owner = const BombPlayer(id: 0, x: 1, y: 1, activeBombs: 0);
      final result = BombLogic.explode(
        bomb: bomb,
        grid: grid,
        allBombs: [bomb],
        players: [owner],
        powerups: [],
      );
      expect(
        result.players.firstWhere((p) => p.id == 0).activeBombs,
        equals(0),
      );
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

    test('block is not walkable', () {
      final grid = openGrid();
      grid[5][5] = CellType.block;
      expect(BombLogic.isWalkable(grid, 5, 5), isFalse);
    });

    test('powerup cell is walkable', () {
      final grid = openGrid();
      grid[5][5] = CellType.powerup;
      expect(BombLogic.isWalkable(grid, 5, 5), isTrue);
    });

    test('out of bounds — negative coordinates', () {
      final grid = MapGenerator.generate(seed: 1);
      expect(BombLogic.isWalkable(grid, -1, 0), isFalse);
      expect(BombLogic.isWalkable(grid, 0, -1), isFalse);
    });

    test('out of bounds — beyond grid dimensions', () {
      final grid = MapGenerator.generate(seed: 1);
      expect(BombLogic.isWalkable(grid, kGridW, 0), isFalse);
      expect(BombLogic.isWalkable(grid, 0, kGridH), isFalse);
    });
  });

  group('BombLogic.collectPowerups', () {
    test('player collects extraBomb powerup', () {
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

    test('shield powerup sets hasShield to true', () {
      final player = const BombPlayer(id: 0, x: 2, y: 2, hasShield: false);
      final powerups = [
        const PowerupCell(x: 2, y: 2, type: PowerupType.shield),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.players[0].hasShield, isTrue);
    });

    test('extraBomb capped at 3', () {
      final player = const BombPlayer(
        id: 0,
        x: 3,
        y: 3,
        maxBombs: 3,
      ); // already max
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.players[0].maxBombs, equals(3)); // no change
    });

    test('blastRange capped at 6', () {
      final player = const BombPlayer(id: 0, x: 3, y: 3, range: 6); // max
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.blastRange),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.players[0].range, equals(6));
    });

    test('speed capped at 6.0', () {
      final player = const BombPlayer(id: 0, x: 3, y: 3, speed: 6.0);
      final powerups = [const PowerupCell(x: 3, y: 3, type: PowerupType.speed)];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.players[0].speed, closeTo(6.0, 0.01));
    });

    test('collecting multiple powerups at once — all applied', () {
      final player = const BombPlayer(
        id: 0,
        x: 3,
        y: 3,
        maxBombs: 1,
        range: 1,
        speed: 3.5,
      );
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
        const PowerupCell(x: 3, y: 3, type: PowerupType.blastRange),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.players[0].maxBombs, equals(2));
      expect(result.players[0].range, equals(2));
      expect(result.powerups, isEmpty);
    });

    test('ghost player does not collect powerups', () {
      final player = const BombPlayer(
        id: 0,
        x: 3,
        y: 3,
        isGhost: true,
        maxBombs: 2,
      );
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.powerups, isNotEmpty);
      expect(result.players[0].maxBombs, equals(2));
    });

    test('dead player does not collect powerups', () {
      final player = const BombPlayer(id: 0, x: 3, y: 3, isAlive: false);
      final powerups = [
        const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
      ];
      final result = BombLogic.collectPowerups(
        players: [player],
        powerups: powerups,
      );
      expect(result.powerups, isNotEmpty);
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

    test(
      'two players at same spot — first collects, powerup removed for second',
      () {
        final p1 = const BombPlayer(id: 0, x: 3, y: 3, maxBombs: 1);
        final p2 = const BombPlayer(id: 1, x: 3, y: 3, maxBombs: 1);
        final powerups = [
          const PowerupCell(x: 3, y: 3, type: PowerupType.extraBomb),
        ];
        final result = BombLogic.collectPowerups(
          players: [p1, p2],
          powerups: powerups,
        );
        // Total maxBombs gained should be exactly 1 (only one powerup)
        final gained =
            (result.players[0].maxBombs - 1) + (result.players[1].maxBombs - 1);
        expect(gained, equals(1));
        expect(result.powerups, isEmpty);
      },
    );

    test(
      'powerup at explosion tile — game logic exposes via explosionTile, collectPowerups only checks player position',
      () {
        // Powerup at (5,5), player at (3,3) — separate positions
        final player = const BombPlayer(id: 0, x: 3, y: 3);
        final explosionAtPowerup = const ExplosionTile(
          x: 5,
          y: 5,
          remainingMs: 200,
        );
        // collectPowerups does not check explosions — that's handled by explode()
        final result = BombLogic.collectPowerups(
          players: [player],
          powerups: [const PowerupCell(x: 5, y: 5, type: PowerupType.speed)],
        );
        expect(result.powerups.length, equals(1)); // player not there
        // suppress unused variable warning
        expect(explosionAtPowerup.remainingMs, greaterThan(0));
      },
    );
  });
}
