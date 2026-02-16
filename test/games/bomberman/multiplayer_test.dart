/// Bomberman Multiplayer Frame Sequence Number Tests
///
/// Covers toFrameJson frameId parameter, sequence ordering, applyFrameSync
/// with various frameIds, and BombMessage encode/decode preserving frameId.
///
/// Does NOT duplicate tests already in bomb_sync_test.dart (round-trip
/// correctness, grid preservation, winnerId handling, CellType/GamePhase/
/// PowerupType enum serialization, gridUpdate messages).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';

/// Minimal valid state for serialization tests — mirrors the helper in
/// bomb_sync_test.dart so each file is self-contained.
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
  group('toFrameJson frameId parameter', () {
    test('toFrameJson default frameId is 0', () {
      final state = _testState();
      final frame = state.toFrameJson();
      expect(frame['frameId'], 0);
    });

    test('toFrameJson includes the supplied frameId', () {
      final state = _testState();
      final frame = state.toFrameJson(frameId: 42);
      expect(frame['frameId'], 42);
    });

    test('toFrameJson with frameId 1 is different from frameId 2', () {
      final state = _testState();
      final frame1 = state.toFrameJson(frameId: 1);
      final frame2 = state.toFrameJson(frameId: 2);
      expect(frame1['frameId'], isNot(frame2['frameId']));
    });

    test('toFrameJson with large frameId preserves the value exactly', () {
      final state = _testState();
      const bigId = 999999;
      final frame = state.toFrameJson(frameId: bigId);
      expect(frame['frameId'], bigId);
    });
  });

  group('Frame sequence ordering (pure logic)', () {
    test('a lower frameId is numerically less than a higher one', () {
      final state = _testState();
      final earlierFrame = state.toFrameJson(frameId: 10);
      final laterFrame = state.toFrameJson(frameId: 11);

      final earlierId = earlierFrame['frameId'] as int;
      final laterId = laterFrame['frameId'] as int;

      expect(earlierId, lessThan(laterId));
    });

    test('consecutive frameIds increment by 1', () {
      final state = _testState();
      const start = 100;

      for (int i = 0; i < 5; i++) {
        final frame = state.toFrameJson(frameId: start + i);
        expect(frame['frameId'], start + i);
      }
    });

    test('frameId zero is the smallest non-negative sequence number', () {
      final state = _testState();
      final zeroFrame = state.toFrameJson(frameId: 0);
      final oneFrame = state.toFrameJson(frameId: 1);

      expect(zeroFrame['frameId'] as int, lessThan(oneFrame['frameId'] as int));
    });
  });

  group('applyFrameSync with frameId', () {
    test('applyFrameSync applies frame data regardless of frameId value', () {
      final state = _testState();
      // The guest state might have been on frameId 5 previously; receiving
      // frameId 99 (or any value) must still apply the payload.
      final hostFrame = state
          .copyWith(roundTimeSeconds: 90, phase: GamePhase.playing)
          .toFrameJson(frameId: 99);

      final restored = state.applyFrameSync(hostFrame);

      expect(restored.roundTimeSeconds, 90);
      expect(restored.phase, GamePhase.playing);
    });

    test('applyFrameSync with frameId 0 still applies correctly', () {
      final original = _testState();
      final modified = original.copyWith(
        round: 2,
        roundWins: [1, 0],
        roundTimeSeconds: 60,
      );
      final frame = modified.toFrameJson(frameId: 0);

      final restored = original.applyFrameSync(frame);

      expect(restored.round, 2);
      expect(restored.roundWins, [1, 0]);
      expect(restored.roundTimeSeconds, 60);
    });

    test('applyFrameSync does not expose frameId on the resulting state', () {
      // BombGameState has no frameId field — the value is informational only
      // and is not stored on the state object itself.
      final state = _testState();
      final frame = state.toFrameJson(frameId: 77);
      final restored = state.applyFrameSync(frame);

      // Verify the restored object is a BombGameState (not a Map) —
      // it simply does not carry the frameId forward.
      expect(restored, isA<BombGameState>());
      expect(restored.roundTimeSeconds, state.roundTimeSeconds);
    });
  });

  group('BombMessage frameSync encode/decode preserves frameId', () {
    test('frameId is preserved through frameSync encode → decode', () {
      final state = _testState();
      const expectedFrameId = 123;
      final frameJson = state.toFrameJson(frameId: expectedFrameId);

      final msg = BombMessage.frameSync(frameJson);
      final encoded = msg.encode();
      final decoded = BombMessage.tryDecode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.type, BombMessageType.frameSync);

      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['frameId'], expectedFrameId);
    });

    test('frameId 0 (default) survives encode → decode', () {
      final state = _testState();
      final frameJson = state.toFrameJson(); // default frameId = 0

      final encoded = BombMessage.frameSync(frameJson).encode();
      final decoded = BombMessage.tryDecode(encoded);

      expect(decoded, isNotNull);
      final data = decoded!.payload['data'] as Map<String, dynamic>;
      expect(data['frameId'], 0);
    });

    test('sequential frameIds survive encode → decode in order', () {
      final state = _testState();

      for (int id = 0; id < 5; id++) {
        final frameJson = state.toFrameJson(frameId: id);
        final encoded = BombMessage.frameSync(frameJson).encode();
        final decoded = BombMessage.tryDecode(encoded)!;
        final data = decoded.payload['data'] as Map<String, dynamic>;
        expect(data['frameId'], id, reason: 'frameId $id mismatch after encode/decode');
      }
    });

    test('two messages with different frameIds are distinguishable after decode', () {
      final state = _testState();

      final encoded1 = BombMessage.frameSync(state.toFrameJson(frameId: 10)).encode();
      final encoded2 = BombMessage.frameSync(state.toFrameJson(frameId: 20)).encode();

      final decoded1 = BombMessage.tryDecode(encoded1)!;
      final decoded2 = BombMessage.tryDecode(encoded2)!;

      final id1 = (decoded1.payload['data'] as Map<String, dynamic>)['frameId'] as int;
      final id2 = (decoded2.payload['data'] as Map<String, dynamic>)['frameId'] as int;

      expect(id1, lessThan(id2));
    });
  });
}
