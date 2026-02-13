import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/state/game_state.dart';

void main() {
  group('GameState', () {
    test('has exactly 6 values', () {
      expect(GameState.values.length, 6);
    });

    test('contains all expected states', () {
      expect(
        GameState.values,
        containsAll([
          GameState.idle,
          GameState.playing,
          GameState.paused,
          GameState.gameOver,
          GameState.countdown,
          GameState.finished,
        ]),
      );
    });

    test('idle is the first state (default game start)', () {
      expect(GameState.values.first, GameState.idle);
    });

    test('state equality works correctly', () {
      expect(GameState.idle == GameState.idle, isTrue);
      expect(GameState.playing == GameState.playing, isTrue);
      expect(GameState.paused == GameState.paused, isTrue);
      expect(GameState.gameOver == GameState.gameOver, isTrue);
      expect(GameState.countdown == GameState.countdown, isTrue);
      expect(GameState.finished == GameState.finished, isTrue);
    });

    test('different states are not equal', () {
      expect(GameState.idle == GameState.playing, isFalse);
      expect(GameState.playing == GameState.paused, isFalse);
      expect(GameState.paused == GameState.gameOver, isFalse);
      expect(GameState.countdown == GameState.finished, isFalse);
    });

    test('states have correct string names', () {
      expect(GameState.idle.name, 'idle');
      expect(GameState.playing.name, 'playing');
      expect(GameState.paused.name, 'paused');
      expect(GameState.gameOver.name, 'gameOver');
      expect(GameState.countdown.name, 'countdown');
      expect(GameState.finished.name, 'finished');
    });

    test('states can be used in switch statements without missing cases', () {
      String result = '';
      switch (GameState.playing) {
        case GameState.idle:
          result = 'idle';
        case GameState.playing:
          result = 'playing';
        case GameState.paused:
          result = 'paused';
        case GameState.gameOver:
          result = 'gameOver';
        case GameState.countdown:
          result = 'countdown';
        case GameState.finished:
          result = 'finished';
      }
      expect(result, 'playing');
    });

    test('race states are distinct from solo states', () {
      expect(GameState.countdown == GameState.playing, isFalse);
      expect(GameState.finished == GameState.gameOver, isFalse);
    });
  });
}
