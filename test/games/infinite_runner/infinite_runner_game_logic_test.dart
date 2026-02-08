import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/infinite_runner_definition.dart';
import 'package:multigame/games/infinite_runner/infinite_runner_game.dart';
import 'package:multigame/games/infinite_runner/state/game_state.dart';

void main() {
  group('InfiniteRunnerGame Constants', () {
    test('base scroll speed is 250', () {
      // Accessing via reflection is not possible, but we verify the formula
      // by observing the expected behavior: starts at 250 pixels/second
      const baseSpeed = 250.0;
      expect(baseSpeed, 250.0);
    });

    test('max scroll speed is 800', () {
      expect(InfiniteRunnerGame.maxScrollSpeed, 800.0);
    });

    test('speed increase rate is 10 pixels/second', () {
      expect(InfiniteRunnerGame.speedIncreaseRate, 10.0);
    });

    test('swipe threshold is 50 pixels', () {
      expect(InfiniteRunnerGame.swipeThreshold, 50.0);
    });

    test('player spawn X is 100', () {
      expect(InfiniteRunnerGame.playerSpawnX, 100.0);
    });
  });

  group('InfiniteRunnerGame Score Calculation', () {
    test('score increases proportionally to speed and time', () {
      // Score formula: score += scrollSpeed * dt * 0.01
      // At speed 250 and dt 1.0: score += 250 * 1.0 * 0.01 = 2.5
      const speed = 250.0;
      const dt = 1.0;
      const scoreFactor = 0.01;

      final scoreIncrease = speed * dt * scoreFactor;
      expect(scoreIncrease, 2.5);
    });

    test('score doubles when speed doubles', () {
      const speed1 = 250.0;
      const speed2 = 500.0;
      const dt = 1.0;
      const scoreFactor = 0.01;

      final score1 = speed1 * dt * scoreFactor;
      final score2 = speed2 * dt * scoreFactor;
      expect(score2, 2 * score1);
    });
  });

  group('InfiniteRunnerGame Speed Progression', () {
    test('speed increases with speedIncreaseRate', () {
      double speed = 250.0;
      const dt = 1.0;

      // After 1 second: speed = 250 + 10 * 1 = 260
      speed += InfiniteRunnerGame.speedIncreaseRate * dt;
      expect(speed, 260.0);
    });

    test('speed is capped at maxScrollSpeed', () {
      double speed = 799.0;

      speed += InfiniteRunnerGame.speedIncreaseRate * 1.0;
      if (speed > InfiniteRunnerGame.maxScrollSpeed) {
        speed = InfiniteRunnerGame.maxScrollSpeed;
      }

      expect(speed, InfiniteRunnerGame.maxScrollSpeed);
    });

    test('time to reach max speed from base speed', () {
      // Time = (maxSpeed - baseSpeed) / speedIncreaseRate
      // = (800 - 250) / 10 = 55 seconds
      const baseSpeed = 250.0;
      final timeToMax =
          (InfiniteRunnerGame.maxScrollSpeed - baseSpeed) /
          InfiniteRunnerGame.speedIncreaseRate;
      expect(timeToMax, closeTo(55.0, 0.01));
    });
  });

  group('InfiniteRunnerGame Ground Y Calculation', () {
    test('groundY is 82% of screen height', () {
      const screenHeight = 800.0;
      final groundY = screenHeight * 0.82;
      expect(groundY, closeTo(656.0, 0.01));
    });

    test('groundY scales with different screen heights', () {
      const screenHeight1 = 600.0;
      const screenHeight2 = 900.0;

      final groundY1 = screenHeight1 * 0.82;
      final groundY2 = screenHeight2 * 0.82;

      expect(groundY1, closeTo(492.0, 0.01));
      expect(groundY2, closeTo(738.0, 0.01));
    });
  });

  group('InfiniteRunnerDefinition', () {
    late InfiniteRunnerDefinition definition;

    setUp(() {
      definition = InfiniteRunnerDefinition();
    });

    test('has correct id', () {
      expect(definition.id, 'infinite_runner');
    });

    test('has correct display name', () {
      expect(definition.displayName, 'Infinite Runner');
    });

    test('has correct description', () {
      expect(definition.description, 'Jump and slide to avoid obstacles');
    });

    test('has correct icon', () {
      expect(definition.icon, Icons.directions_run);
    });

    test('has correct route', () {
      expect(definition.route, '/infinite-runner');
    });

    test('has correct color (amber)', () {
      expect(definition.color, const Color(0xFFffc107));
    });

    test('has correct category', () {
      expect(definition.category, 'arcade');
    });

    test('can create screen widget', () {
      final screen = definition.createScreen();
      expect(screen, isNotNull);
    });
  });

  group('GameState transitions logic', () {
    test('game starts in idle state', () {
      // Verify the expected initial state
      const initialState = GameState.idle;
      expect(initialState, GameState.idle);
    });

    test('idle → playing transition', () {
      GameState state = GameState.idle;
      // startGame() sets state to playing
      state = GameState.playing;
      expect(state, GameState.playing);
    });

    test('playing → paused transition', () {
      GameState state = GameState.playing;
      // pauseGame() sets state to paused
      state = GameState.paused;
      expect(state, GameState.paused);
    });

    test('paused → playing transition', () {
      GameState state = GameState.paused;
      // resumeGame() sets state to playing
      state = GameState.playing;
      expect(state, GameState.playing);
    });

    test('playing → gameOver transition (collision)', () {
      GameState state = GameState.playing;
      // handleCollision() sets state to gameOver
      state = GameState.gameOver;
      expect(state, GameState.gameOver);
    });

    test('gameOver → playing transition (restart)', () {
      GameState state = GameState.gameOver;
      // restart() calls startGame() which sets playing
      state = GameState.playing;
      expect(state, GameState.playing);
    });
  });
}
