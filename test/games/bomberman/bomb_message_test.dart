import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';

void main() {
  group('BombMessage', () {
    test('join message encodes and decodes correctly', () {
      final msg = BombMessage.join('Alice');
      final decoded = BombMessage.tryDecode(msg.encode());
      expect(decoded, isNotNull);
      expect(decoded!.type, BombMessageType.join);
      expect(decoded.payload['name'], 'Alice');
    });

    test('move message encodes and decodes correctly', () {
      final msg = BombMessage.move(1, -1.0, 0.0);
      final decoded = BombMessage.tryDecode(msg.encode());
      expect(decoded!.type, BombMessageType.move);
      expect(decoded.payload['id'], 1);
      expect(decoded.payload['dx'], -1.0);
      expect(decoded.payload['dy'], 0.0);
    });

    test('roundOver message with null winner decodes correctly', () {
      final msg = BombMessage.roundOver(null, [1, 2]);
      final decoded = BombMessage.tryDecode(msg.encode());
      expect(decoded!.type, BombMessageType.roundOver);
      expect(decoded.payload['winner'], isNull);
      expect(decoded.payload['wins'], [1, 2]);
    });

    test('tryDecode returns null on invalid JSON', () {
      expect(BombMessage.tryDecode('not json'), isNull);
    });

    test('tryDecode returns null on unknown type', () {
      expect(BombMessage.tryDecode('{"type":"unknown","payload":{}}'), isNull);
    });

    test('all message types roundtrip without loss', () {
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
          msg.type,
          reason: '${msg.type} type should match',
        );
      }
    });
  });
}
