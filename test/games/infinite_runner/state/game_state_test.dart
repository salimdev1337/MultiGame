import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/state/game_state.dart';

void main() {
  group('GameState', () {
    test('has exactly 4 values', () {
      expect(GameState.values.length, 4);
    });

    test('contains all expected states', () {
      expect(
        GameState.values,
        containsAll([
          GameState.idle,
          GameState.playing,
          GameState.paused,
          GameState.gameOver,
        ]),
      );
    });

    test('idle is the first state (default game start)', () {
      expect(GameState.values.first, GameState.idle);
    });

    test('gameOver is the last state', () {
      expect(GameState.values.last, GameState.gameOver);
    });

    test('state equality works correctly', () {
      expect(GameState.idle == GameState.idle, isTrue);
      expect(GameState.playing == GameState.playing, isTrue);
      expect(GameState.paused == GameState.paused, isTrue);
      expect(GameState.gameOver == GameState.gameOver, isTrue);
    });

    test('different states are not equal', () {
      expect(GameState.idle == GameState.playing, isFalse);
      expect(GameState.playing == GameState.paused, isFalse);
      expect(GameState.paused == GameState.gameOver, isFalse);
      expect(GameState.idle == GameState.gameOver, isFalse);
    });

    test('states have correct string names', () {
      expect(GameState.idle.name, 'idle');
      expect(GameState.playing.name, 'playing');
      expect(GameState.paused.name, 'paused');
      expect(GameState.gameOver.name, 'gameOver');
    });

    test('states can be used in switch statements', () {
      String result = '';
      switch (GameState.playing) {
        case GameState.idle:
          result = 'idle';
          break;
        case GameState.playing:
          result = 'playing';
          break;
        case GameState.paused:
          result = 'paused';
          break;
        case GameState.gameOver:
          result = 'gameOver';
          break;
      }
      expect(result, 'playing');
    });
  });
}
