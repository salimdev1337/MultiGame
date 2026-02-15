import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';

void main() {
  group('BombMessage — encode/decode correctness', () {
    test('join message encodes and decodes correctly', () {
      final msg = BombMessage.join('Alice');
      final decoded = BombMessage.tryDecode(msg.encode());
      expect(decoded, isNotNull);
      expect(decoded!.type, BombMessageType.join);
      expect(decoded.payload['name'], 'Alice');
    });

    test('join message preserves displayName exactly', () {
      final msg = BombMessage.join('Player One');
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['name'], equals('Player One'));
    });

    test('move message encodes all fields correctly', () {
      final msg = BombMessage.move(1, -1.0, 0.5);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.type, BombMessageType.move);
      expect(decoded.payload['id'], equals(1));
      expect(decoded.payload['dx'], equals(-1.0));
      expect(decoded.payload['dy'], equals(0.5));
    });

    test('roundOver with null winner preserves null', () {
      final msg = BombMessage.roundOver(null, [1, 2]);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.type, BombMessageType.roundOver);
      expect(decoded.payload['winner'], isNull);
      expect(decoded.payload['wins'], equals([1, 2]));
    });

    test('roundOver with winnerId=0 preserves 0 (not confused with null)', () {
      final msg = BombMessage.roundOver(0, [1, 0]);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['winner'], equals(0));
    });

    test('roundOver with positive winnerId preserved', () {
      final msg = BombMessage.roundOver(3, [0, 0, 0, 3]);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['winner'], equals(3));
    });

    test('bombPlaced encodes all fields', () {
      final msg = BombMessage.bombPlaced(5, 3, 4, 0, 2);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['bombId'], equals(5));
      expect(decoded.payload['x'], equals(3));
      expect(decoded.payload['y'], equals(4));
      expect(decoded.payload['ownerId'], equals(0));
      expect(decoded.payload['range'], equals(2));
    });

    test('playerState encodes players list', () {
      final players = [
        {'id': 0, 'name': 'Alice'},
        {'id': 1, 'name': 'Bob'},
      ];
      final msg = BombMessage.playerState(players);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      final list = decoded.payload['players'] as List;
      expect(list.length, equals(2));
      expect((list[0] as Map)['name'], equals('Alice'));
    });

    test('all non-data message types roundtrip type correctly', () {
      final messages = [
        BombMessage.joined(2, 'Bob'),
        BombMessage.ready(1),
        BombMessage.start(),
        BombMessage.placeBomb(0),
        BombMessage.bombPlaced(5, 3, 3, 0, 2),
        BombMessage.playerDied(1),
        BombMessage.powerupSpawned(4, 4, 'extraBomb'),
        BombMessage.powerupTaken(0, 4, 4),
        BombMessage.rematchVote(0),
        BombMessage.rematchStart(),
        BombMessage.disconnect(2),
      ];
      for (final msg in messages) {
        final decoded = BombMessage.tryDecode(msg.encode());
        expect(decoded, isNotNull, reason: '${msg.type} should decode');
        expect(
          decoded!.type,
          equals(msg.type),
          reason: '${msg.type} type should match',
        );
        // Verify payload round-trips field-for-field
        for (final key in msg.payload.keys) {
          expect(
            decoded.payload[key],
            equals(msg.payload[key]),
            reason: '${msg.type}.$key should match',
          );
        }
      }
    });

    test('start and rematchStart have empty payloads', () {
      final start = BombMessage.tryDecode(BombMessage.start().encode())!;
      expect(start.payload, isEmpty);
      final rematch = BombMessage.tryDecode(
        BombMessage.rematchStart().encode(),
      )!;
      expect(rematch.payload, isEmpty);
    });
  });

  group('BombMessage — tryDecode error handling', () {
    test('returns null on completely invalid JSON', () {
      expect(BombMessage.tryDecode('not json'), isNull);
    });

    test('returns null on unknown message type', () {
      expect(BombMessage.tryDecode('{"type":"unknown","payload":{}}'), isNull);
    });

    test('returns null on empty string', () {
      expect(BombMessage.tryDecode(''), isNull);
    });

    test('returns null on JSON array (not an object)', () {
      expect(BombMessage.tryDecode('[1, 2, 3]'), isNull);
    });

    test('returns null on JSON missing type field', () {
      expect(BombMessage.tryDecode('{"payload":{}}'), isNull);
    });

    test('returns null on JSON with null type', () {
      expect(BombMessage.tryDecode('{"type":null,"payload":{}}'), isNull);
    });

    test('returns null on truncated JSON', () {
      expect(BombMessage.tryDecode('{"type":"join","pay'), isNull);
    });

    test('handles missing payload gracefully — defaults to empty map', () {
      // No payload field — should decode with empty payload
      final json = jsonEncode({'type': 'start'});
      final decoded = BombMessage.tryDecode(json);
      expect(decoded, isNotNull);
      expect(decoded!.payload, isEmpty);
    });
  });

  group('BombMessage — frameSync / gridUpdate', () {
    BombGameState testState() {
      return BombGameState(
        grid: MapGenerator.generate(seed: 42),
        players: const [
          BombPlayer(id: 0, x: 1.5, y: 1.5, displayName: 'Alice'),
          BombPlayer(id: 1, x: 13.5, y: 1.5, displayName: 'Bob'),
        ],
        bombs: const [
          Bomb(id: 0, x: 3, y: 3, ownerId: 0, range: 2, fuseMs: 2000),
        ],
        phase: GamePhase.playing,
        countdown: 0,
        roundTimeSeconds: 120,
        round: 2,
        roundWins: [1, 0],
      );
    }

    test('frameSync encode → decode round-trip preserves all meta fields', () {
      final state = testState();
      final msg = BombMessage.frameSync(state.toFrameJson());
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.type, BombMessageType.frameSync);

      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['round'], equals(state.round));
      expect(data['roundTimeSeconds'], equals(state.roundTimeSeconds));
      expect((data['players'] as List).length, equals(state.players.length));
      expect((data['bombs'] as List).length, equals(state.bombs.length));
      expect(data['roundWins'], equals(state.roundWins));
    });

    test('frameSync with winnerId null survives encode/decode as null', () {
      final state = testState();
      final frame = state.toFrameJson();
      expect(frame['winnerId'], isNull);

      final decoded = BombMessage.tryDecode(
        BombMessage.frameSync(frame).encode(),
      )!;
      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['winnerId'], isNull);
    });

    test('frameSync with non-null winnerId preserved correctly', () {
      final state = testState().copyWith(winnerId: 1);
      final decoded = BombMessage.tryDecode(
        BombMessage.frameSync(state.toFrameJson()).encode(),
      )!;
      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect(data['winnerId'], equals(1));
    });

    test('gridUpdate encode → decode preserves all cell fields', () {
      final cells = [
        {'x': 3, 'y': 4, 'type': CellType.empty.index},
        {'x': 5, 'y': 2, 'type': CellType.empty.index},
      ];
      final decoded = BombMessage.tryDecode(
        BombMessage.gridUpdate(cells).encode(),
      )!;
      expect(decoded.type, BombMessageType.gridUpdate);

      final cellList = (decoded.payload['cells'] as List)
          .cast<Map<String, dynamic>>();
      expect(cellList.length, equals(2));
      expect(cellList[0]['x'], equals(3));
      expect(cellList[0]['y'], equals(4));
      expect(cellList[1]['x'], equals(5));
      expect(cellList[1]['y'], equals(2));
    });

    test('gridUpdate with many cells encodes correctly', () {
      // Simulate a large explosion destroying many blocks
      final cells = List.generate(
        50,
        (i) => {
          'x': i % kGridW,
          'y': i ~/ kGridW,
          'type': CellType.empty.index,
        },
      );
      final decoded = BombMessage.tryDecode(
        BombMessage.gridUpdate(cells).encode(),
      )!;
      final cellList = (decoded.payload['cells'] as List)
          .cast<Map<String, dynamic>>();
      expect(cellList.length, equals(50));
    });

    test('frameSync with many players encodes all of them', () {
      // Simulate 4-player game state
      final state = BombGameState(
        grid: MapGenerator.generate(seed: 0),
        players: List.generate(
          4,
          (i) => BombPlayer(
            id: i,
            x: (i * 3 + 1).toDouble(),
            y: 1.0,
            displayName: 'P$i',
          ),
        ),
        roundWins: [0, 0, 0, 0],
      );
      final decoded = BombMessage.tryDecode(
        BombMessage.frameSync(state.toFrameJson()).encode(),
      )!;
      final data = decoded.payload['data'] as Map<String, dynamic>;
      expect((data['players'] as List).length, equals(4));
    });
  });

  group('BombMessage — special characters and edge values', () {
    test(
      'displayName with spaces and special chars survives encode/decode',
      () {
        final msg = BombMessage.join('Ál-ice "the" Gréat');
        final decoded = BombMessage.tryDecode(msg.encode())!;
        expect(decoded.payload['name'], equals('Ál-ice "the" Gréat'));
      },
    );

    test('move with zero deltas encodes correctly', () {
      final msg = BombMessage.move(0, 0.0, 0.0);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['dx'], equals(0.0));
      expect(decoded.payload['dy'], equals(0.0));
    });

    test('roundOver with empty wins list encodes correctly', () {
      final msg = BombMessage.roundOver(null, []);
      final decoded = BombMessage.tryDecode(msg.encode())!;
      expect(decoded.payload['wins'], isEmpty);
    });
  });
}
