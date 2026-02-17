import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_frame_codec.dart';

// ─── Test helpers ─────────────────────────────────────────────────────────────

BombGameState _baseState() {
  final grid = MapGenerator.generate(seed: 42);
  return BombGameState(
    grid: grid,
    players: const [
      BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'Alice'),
      BombPlayer(id: 1, x: 13.5, y: 1.5, displayName: 'Bob'),
    ],
    bombs: const [
      Bomb(id: 0, x: 3, y: 3, ownerId: 0, range: 2, fuseMs: 2000),
    ],
    explosions: const [ExplosionTile(x: 2, y: 2, remainingMs: 200)],
    powerups: const [PowerupCell(x: 5, y: 5, type: PowerupType.speed)],
    phase: GamePhase.playing,
    countdown: 0,
    roundTimeSeconds: 120,
    round: 1,
    roundWins: [0, 0],
  );
}

BombGameState _apply(BombGameState encoded, BombGameState current) {
  final bytes = BombFrameCodec.encode(encoded, 42);
  return BombFrameCodec.applyTo(bytes, current);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('BombFrameCodec — version byte', () {
    test('first byte is 0x01', () {
      final bytes = BombFrameCodec.encode(_baseState(), 0);
      expect(bytes[0], 0x01);
    });
  });

  group('BombFrameCodec — readFrameId', () {
    test('reads back the frameId written by encode', () {
      final bytes = BombFrameCodec.encode(_baseState(), 12345);
      expect(BombFrameCodec.readFrameId(bytes), 12345);
    });

    test('frameId zero', () {
      final bytes = BombFrameCodec.encode(_baseState(), 0);
      expect(BombFrameCodec.readFrameId(bytes), 0);
    });

    test('frameId max 32-bit', () {
      final bytes = BombFrameCodec.encode(_baseState(), 0xFFFFFFFF);
      expect(BombFrameCodec.readFrameId(bytes), 0xFFFFFFFF);
    });
  });

  group('BombFrameCodec — size assertion', () {
    test('base state (2 players, 1 bomb, 1 explosion, 1 powerup) < 400 bytes',
        () {
      final bytes = BombFrameCodec.encode(_baseState(), 0);
      expect(bytes.length, lessThan(400));
    });

    test('4 players, 4 bombs, 10 explosions, 4 powerups < 400 bytes', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'P1'),
          BombPlayer(id: 1, x: 13.5, y: 1.5, displayName: 'P2'),
          BombPlayer(id: 2, x: 1.5, y: 11.5, displayName: 'P3'),
          BombPlayer(id: 3, x: 13.5, y: 11.5, displayName: 'P4'),
        ],
        bombs: const [
          Bomb(id: 0, x: 3, y: 3, ownerId: 0, range: 2, fuseMs: 2000),
          Bomb(id: 1, x: 5, y: 3, ownerId: 1, range: 3, fuseMs: 1500),
          Bomb(id: 2, x: 3, y: 7, ownerId: 2, range: 1, fuseMs: 800),
          Bomb(id: 3, x: 11, y: 7, ownerId: 3, range: 2, fuseMs: 100),
        ],
        explosions: const [
          ExplosionTile(x: 2, y: 2, remainingMs: 300),
          ExplosionTile(x: 3, y: 2, remainingMs: 250),
          ExplosionTile(x: 4, y: 2, remainingMs: 200),
          ExplosionTile(x: 2, y: 3, remainingMs: 150),
          ExplosionTile(x: 2, y: 4, remainingMs: 100),
          ExplosionTile(x: 6, y: 6, remainingMs: 90),
          ExplosionTile(x: 6, y: 7, remainingMs: 80),
          ExplosionTile(x: 6, y: 8, remainingMs: 70),
          ExplosionTile(x: 7, y: 6, remainingMs: 60),
          ExplosionTile(x: 8, y: 6, remainingMs: 50),
        ],
        powerups: const [
          PowerupCell(x: 5, y: 5, type: PowerupType.speed),
          PowerupCell(x: 6, y: 5, type: PowerupType.extraBomb),
          PowerupCell(x: 7, y: 5, type: PowerupType.blastRange),
          PowerupCell(x: 8, y: 5, type: PowerupType.shield),
        ],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 90,
        round: 2,
        roundWins: [1, 0, 0, 0],
      );
      final bytes = BombFrameCodec.encode(state, 999);
      expect(bytes.length, lessThan(400));
    });
  });

  group('BombFrameCodec — phase and header fields roundtrip', () {
    for (final phase in GamePhase.values) {
      test('phase ${phase.name} roundtrips', () {
        final state = _baseState().copyWith(phase: phase);
        final result = _apply(state, _baseState());
        expect(result.phase, phase);
      });
    }

    test('countdown roundtrips', () {
      final state = _baseState().copyWith(countdown: 3);
      expect(_apply(state, _baseState()).countdown, 3);
    });

    test('roundTimeSeconds roundtrips', () {
      final state = _baseState().copyWith(roundTimeSeconds: 77);
      expect(_apply(state, _baseState()).roundTimeSeconds, 77);
    });

    test('round roundtrips', () {
      final state = _baseState().copyWith(round: 3);
      expect(_apply(state, _baseState()).round, 3);
    });

    test('roundWins roundtrip with 4 players', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'A'),
          BombPlayer(id: 1, x: 13.5, y: 1.5, displayName: 'B'),
          BombPlayer(id: 2, x: 1.5, y: 11.5, displayName: 'C'),
          BombPlayer(id: 3, x: 13.5, y: 11.5, displayName: 'D'),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 100,
        round: 2,
        roundWins: [2, 1, 0, 1],
      );
      final result = _apply(state, state);
      expect(result.roundWins, [2, 1, 0, 1]);
    });
  });

  group('BombFrameCodec — winnerId and roundOverMessage', () {
    test('winnerId null is preserved', () {
      final state = _baseState();
      final result = _apply(state, _baseState());
      expect(result.winnerId, isNull);
    });

    test('winnerId non-null roundtrips', () {
      final state = _baseState().copyWith(
        phase: GamePhase.gameOver,
        winnerId: 1,
      );
      final result = _apply(state, _baseState());
      expect(result.winnerId, 1);
    });

    test('roundOverMessage null is preserved', () {
      final state = _baseState();
      final result = _apply(state, _baseState());
      expect(result.roundOverMessage, isNull);
    });

    test('roundOverMessage non-null roundtrips', () {
      final state = _baseState().copyWith(
        phase: GamePhase.roundOver,
        roundOverMessage: 'Alice wins the round!',
      );
      final result = _apply(state, _baseState());
      expect(result.roundOverMessage, 'Alice wins the round!');
    });

    test('both winnerId and roundOverMessage set', () {
      final state = _baseState().copyWith(
        phase: GamePhase.gameOver,
        winnerId: 0,
        roundOverMessage: 'Alice wins the match!',
      );
      final result = _apply(state, _baseState());
      expect(result.winnerId, 0);
      expect(result.roundOverMessage, 'Alice wins the match!');
    });

    test('previously set winnerId is cleared when null in new frame', () {
      final stateWithWinner = _baseState().copyWith(
        phase: GamePhase.gameOver,
        winnerId: 1,
      );
      // Current state has a winner; new frame has no winner
      final stateNoWinner = _baseState();
      final bytes = BombFrameCodec.encode(stateNoWinner, 10);
      final result = BombFrameCodec.applyTo(bytes, stateWithWinner);
      expect(result.winnerId, isNull);
    });
  });

  group('BombFrameCodec — players roundtrip', () {
    test('player count', () {
      final result = _apply(_baseState(), _baseState());
      expect(result.players.length, 2);
    });

    test('player ids', () {
      final result = _apply(_baseState(), _baseState());
      expect(result.players[0].id, 0);
      expect(result.players[1].id, 1);
    });

    test('player position precision', () {
      // Position is encoded with 1/256 precision — error < 0.004
      final result = _apply(_baseState(), _baseState());
      expect(result.players[0].x, closeTo(1.5, 1 / 256));
      expect(result.players[0].y, closeTo(1.5, 1 / 256));
    });

    test('player target position', () {
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 1),
        players: const [
          BombPlayer(
            id: 0,
            x: 2.5,
            y: 3.5,
            targetX: 3.5,
            targetY: 3.5,
            displayName: 'X',
          ),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 60,
        round: 1,
        roundWins: [0],
      );
      final result = _apply(state, state);
      expect(result.players[0].targetX, closeTo(3.5, 1 / 256));
      expect(result.players[0].targetY, closeTo(3.5, 1 / 256));
    });

    test('player displayName', () {
      final result = _apply(_baseState(), _baseState());
      expect(result.players[0].displayName, 'Alice');
      expect(result.players[1].displayName, 'Bob');
    });

    test('player bool flags: isAlive, isGhost, hasShield, isBot', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(
            id: 0,
            x: 1.5,
            y: 1.5,
            isAlive: false,
            isGhost: true,
            hasShield: false,
            isBot: false,
            displayName: 'Ghost',
          ),
          BombPlayer(
            id: 1,
            x: 5.5,
            y: 5.5,
            isAlive: true,
            isGhost: false,
            hasShield: true,
            isBot: true,
            displayName: 'Bot',
          ),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 60,
        round: 1,
        roundWins: [0, 0],
      );
      final result = _apply(state, state);
      expect(result.players[0].isAlive, false);
      expect(result.players[0].isGhost, true);
      expect(result.players[0].hasShield, false);
      expect(result.players[0].isBot, false);

      expect(result.players[1].isAlive, true);
      expect(result.players[1].isGhost, false);
      expect(result.players[1].hasShield, true);
      expect(result.players[1].isBot, true);
    });

    test('player speed precision', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(id: 0, x: 1.5, y: 1.5, speed: 7.0, displayName: 'Fast'),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 60,
        round: 1,
        roundWins: [0],
      );
      final result = _apply(state, state);
      // speed encoded as (speed*16).round() — error < 1/16 = 0.0625
      expect(result.players[0].speed, closeTo(7.0, 1 / 16));
    });

    test('player powerups roundtrip', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(
            id: 0,
            x: 1.5,
            y: 1.5,
            powerups: [
              PowerupType.extraBomb,
              PowerupType.blastRange,
              PowerupType.shield,
            ],
            displayName: 'PowerUp',
          ),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 60,
        round: 1,
        roundWins: [0],
      );
      final result = _apply(state, state);
      expect(result.players[0].powerups, [
        PowerupType.extraBomb,
        PowerupType.blastRange,
        PowerupType.shield,
      ]);
    });

    test('player integer fields (lives, maxBombs, activeBombs, range)', () {
      final grid = MapGenerator.generate(seed: 1);
      final state = BombGameState(
        grid: grid,
        players: const [
          BombPlayer(
            id: 0,
            x: 1.5,
            y: 1.5,
            lives: 3,
            maxBombs: 4,
            activeBombs: 2,
            range: 5,
            displayName: 'Heavy',
          ),
        ],
        bombs: const [],
        explosions: const [],
        powerups: const [],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 60,
        round: 1,
        roundWins: [0],
      );
      final result = _apply(state, state);
      final p = result.players[0];
      expect(p.lives, 3);
      expect(p.maxBombs, 4);
      expect(p.activeBombs, 2);
      expect(p.range, 5);
    });
  });

  group('BombFrameCodec — bombs roundtrip', () {
    test('bomb count', () {
      expect(_apply(_baseState(), _baseState()).bombs.length, 1);
    });

    test('bomb fields', () {
      final result = _apply(_baseState(), _baseState());
      final b = result.bombs[0];
      expect(b.id, 0);
      expect(b.x, 3);
      expect(b.y, 3);
      expect(b.ownerId, 0);
      expect(b.range, 2);
      expect(b.fuseMs, 2000);
      expect(b.totalFuseMs, 2500);
    });

    test('zero bombs', () {
      final state = _baseState().copyWith(bombs: []);
      expect(_apply(state, _baseState()).bombs, isEmpty);
    });

    test('multiple bombs roundtrip', () {
      final state = _baseState().copyWith(bombs: [
        const Bomb(id: 5, x: 7, y: 3, ownerId: 1, range: 3, fuseMs: 1200),
        const Bomb(id: 9, x: 2, y: 8, ownerId: 0, range: 1, fuseMs: 500),
      ]);
      final result = _apply(state, _baseState());
      expect(result.bombs.length, 2);
      expect(result.bombs[0].x, 7);
      expect(result.bombs[0].fuseMs, 1200);
      expect(result.bombs[1].x, 2);
      expect(result.bombs[1].fuseMs, 500);
    });
  });

  group('BombFrameCodec — explosions roundtrip', () {
    test('explosion count', () {
      expect(_apply(_baseState(), _baseState()).explosions.length, 1);
    });

    test('explosion fields', () {
      final result = _apply(_baseState(), _baseState());
      final e = result.explosions[0];
      expect(e.x, 2);
      expect(e.y, 2);
      expect(e.remainingMs, 200);
      expect(e.totalMs, 400);
    });

    test('zero explosions', () {
      final state = _baseState().copyWith(explosions: []);
      expect(_apply(state, _baseState()).explosions, isEmpty);
    });
  });

  group('BombFrameCodec — powerup cells roundtrip', () {
    test('powerup cell count', () {
      expect(_apply(_baseState(), _baseState()).powerups.length, 1);
    });

    test('powerup cell fields', () {
      final result = _apply(_baseState(), _baseState());
      final p = result.powerups[0];
      expect(p.x, 5);
      expect(p.y, 5);
      expect(p.type, PowerupType.speed);
    });

    test('all PowerupType values roundtrip', () {
      for (final pt in PowerupType.values) {
        final state = _baseState().copyWith(
          powerups: [PowerupCell(x: 1, y: 1, type: pt)],
        );
        final result = _apply(state, _baseState());
        expect(result.powerups[0].type, pt);
      }
    });

    test('zero powerup cells', () {
      final state = _baseState().copyWith(powerups: []);
      expect(_apply(state, _baseState()).powerups, isEmpty);
    });
  });

  group('BombFrameCodec — grid preservation', () {
    test('applyTo preserves the current grid, ignoring encoded state grid', () {
      final stateA = _baseState(); // seed 42 grid
      final stateB = BombGameState(
        grid: MapGenerator.generate(seed: 99),
        players: stateA.players,
        bombs: stateA.bombs,
        explosions: stateA.explosions,
        powerups: stateA.powerups,
        phase: stateA.phase,
        countdown: stateA.countdown,
        roundTimeSeconds: stateA.roundTimeSeconds,
        round: stateA.round,
        roundWins: stateA.roundWins,
      );
      // Encode stateB (seed 99 grid in memory, but grid not in binary frame)
      // Apply onto stateA (seed 42 grid)
      final bytes = BombFrameCodec.encode(stateB, 1);
      final result = BombFrameCodec.applyTo(bytes, stateA);
      // Grid must match stateA (the current state), not stateB
      for (int row = 0; row < kGridH; row++) {
        for (int col = 0; col < kGridW; col++) {
          expect(
            result.grid[row][col],
            stateA.grid[row][col],
            reason: 'grid[$row][$col] should be preserved from current',
          );
        }
      }
    });
  });

  group('BombFrameCodec — BombGameState convenience wrappers', () {
    test('toFrameBytes / applyFrameSyncBytes roundtrip', () {
      final original = _baseState();
      final bytes = original.toFrameBytes(frameId: 7);
      expect(BombFrameCodec.readFrameId(bytes), 7);
      final restored = original.applyFrameSyncBytes(bytes);
      expect(restored.players.length, original.players.length);
      expect(restored.phase, original.phase);
      expect(restored.round, original.round);
      // Grid preserved
      expect(restored.grid, original.grid);
    });
  });
}
