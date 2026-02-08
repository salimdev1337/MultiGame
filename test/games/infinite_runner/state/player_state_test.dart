import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/state/player_state.dart';

void main() {
  group('PlayerState', () {
    test('has exactly 4 values', () {
      expect(PlayerState.values.length, 4);
    });

    test('contains all expected states', () {
      expect(
        PlayerState.values,
        containsAll([
          PlayerState.running,
          PlayerState.jumping,
          PlayerState.sliding,
          PlayerState.dead,
        ]),
      );
    });

    test('running is the default/first state', () {
      expect(PlayerState.values.first, PlayerState.running);
    });

    test('dead is the last state', () {
      expect(PlayerState.values.last, PlayerState.dead);
    });

    test('state equality works correctly', () {
      expect(PlayerState.running == PlayerState.running, isTrue);
      expect(PlayerState.jumping == PlayerState.jumping, isTrue);
      expect(PlayerState.sliding == PlayerState.sliding, isTrue);
      expect(PlayerState.dead == PlayerState.dead, isTrue);
    });

    test('different states are not equal', () {
      expect(PlayerState.running == PlayerState.jumping, isFalse);
      expect(PlayerState.jumping == PlayerState.sliding, isFalse);
      expect(PlayerState.sliding == PlayerState.dead, isFalse);
      expect(PlayerState.running == PlayerState.dead, isFalse);
    });

    test('states have correct string names', () {
      expect(PlayerState.running.name, 'running');
      expect(PlayerState.jumping.name, 'jumping');
      expect(PlayerState.sliding.name, 'sliding');
      expect(PlayerState.dead.name, 'dead');
    });

    test('can represent a game flow: running → jumping → running → dead', () {
      final stateHistory = [
        PlayerState.running,
        PlayerState.jumping,
        PlayerState.running,
        PlayerState.dead,
      ];

      expect(stateHistory[0], PlayerState.running);
      expect(stateHistory[1], PlayerState.jumping);
      expect(stateHistory[2], PlayerState.running);
      expect(stateHistory[3], PlayerState.dead);
    });
  });
}
