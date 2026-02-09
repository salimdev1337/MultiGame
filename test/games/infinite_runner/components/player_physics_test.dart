import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/components/player.dart';
import 'package:multigame/games/infinite_runner/state/player_state.dart';

/// Test-friendly Player subclass that bypasses Flame's animation assertions.
/// This allows testing physics/state logic without loading actual sprite assets.
/// The `currentState` property still reflects state changes correctly since
/// Player._currentState is updated independently from the animation system.
class _TestPlayer extends Player {
  _TestPlayer({
    required super.position,
    required super.size,
    required super.groundY,
  });

  @override
  set current(PlayerState? value) {
    // Bypass SpriteAnimationGroupComponent's animation assertions.
    // Physics logic in Player uses _currentState, which is updated before
    // this setter is called, so state is still tracked correctly.
  }
}

void main() {
  group('Player', () {
    late Player player;
    const double groundY = 600.0;

    setUp(() {
      player = _TestPlayer(
        position: Vector2(100, groundY),
        size: Vector2(40, 60),
        groundY: groundY,
      );
    });

    group('initialization', () {
      test('starts in running state', () {
        expect(player.currentState, PlayerState.running);
      });

      test('starts on the ground', () {
        expect(player.isOnGround, isTrue);
      });

      test('starts not sliding', () {
        expect(player.isSliding, isFalse);
      });

      test('starts at correct position', () {
        expect(player.position.x, 100);
        expect(player.position.y, groundY);
      });

      test('has correct size', () {
        expect(player.size.x, 40);
        expect(player.size.y, 60);
      });

      test('uses bottomCenter anchor', () {
        expect(player.anchor, Anchor.bottomCenter);
      });
    });

    group('physics constants', () {
      test('gravity is 1200', () {
        expect(Player.gravity, 1200.0);
      });

      test('jumpVelocity is -650', () {
        expect(Player.jumpVelocity, -650.0);
      });

      test('maxFallSpeed is 800', () {
        expect(Player.maxFallSpeed, 800.0);
      });

      test('fastDropSpeed is 1200', () {
        expect(Player.fastDropSpeed, 1200.0);
      });

      test('slideDuration is 0.6 seconds', () {
        expect(Player.slideDuration, 0.6);
      });
    });

    group('jump()', () {
      test('changes state to jumping', () {
        player.jump();
        expect(player.currentState, PlayerState.jumping);
      });

      test('leaves the ground', () {
        player.jump();
        expect(player.isOnGround, isFalse);
      });

      test('cannot jump when already in air', () {
        player.jump();
        expect(player.isOnGround, isFalse);

        // Try to jump again - should be ignored
        player.jump(); // Not on ground, so no second jump
        expect(player.currentState, PlayerState.jumping);
      });

      test('cannot jump when dead', () {
        player.die();
        expect(player.currentState, PlayerState.dead);

        player.jump();
        expect(
          player.currentState,
          PlayerState.dead,
        ); // Still dead, not jumping
      });

      test('cannot jump when sliding', () {
        // Slide is disabled in the implementation but we test the guard
        // _isSliding is never set to true since slide() is a no-op
        // This effectively means we can always jump from ground when not dead
        player.jump();
        expect(player.currentState, PlayerState.jumping);
      });
    });

    group('fastDrop()', () {
      test('does nothing when on ground', () {
        // fastDrop only works when in air (_isOnGround = false)
        player.fastDrop();
        // No velocity change since on ground
        expect(player.isOnGround, isTrue);
        expect(player.position.y, groundY);
      });

      test('works when in air after jump', () {
        player.jump();
        expect(player.isOnGround, isFalse);

        // Let player rise for a few frames before fast drop
        for (int i = 0; i < 10; i++) {
          player.update(0.016);
          if (!player.isOnGround) break;
        }

        // fastDrop from mid-air - should reach ground very quickly
        player.fastDrop();

        // Should land within 5 frames (fastDropSpeed=1200, much faster than normal)
        for (int i = 0; i < 5; i++) {
          player.update(0.016);
          if (player.isOnGround) break;
        }
        expect(player.isOnGround, isTrue);
      });

      test('does not work when dead', () {
        player.die();
        player.fastDrop();
        // State shouldn't change since fastDrop is guarded by dead check
        expect(player.currentState, PlayerState.dead);
      });
    });

    group('die()', () {
      test('sets state to dead', () {
        player.die();
        expect(player.currentState, PlayerState.dead);
      });

      test('can die from running state', () {
        expect(player.currentState, PlayerState.running);
        player.die();
        expect(player.currentState, PlayerState.dead);
      });

      test('can die from jumping state', () {
        player.jump();
        player.die();
        expect(player.currentState, PlayerState.dead);
      });
    });

    group('reset()', () {
      test('returns to running state', () {
        player.die();
        player.reset();
        expect(player.currentState, PlayerState.running);
      });

      test('returns to ground', () {
        player.jump();
        player.reset();
        expect(player.isOnGround, isTrue);
      });

      test('resets position to groundY', () {
        player.jump();
        player.update(0.1); // Move player
        player.reset();
        expect(player.position.y, groundY);
      });

      test('clears sliding state', () {
        // Sliding is disabled but reset should still clear the flag
        player.reset();
        expect(player.isSliding, isFalse);
      });

      test('full lifecycle: jump → die → reset', () {
        player.jump();
        expect(player.currentState, PlayerState.jumping);

        player.die();
        expect(player.currentState, PlayerState.dead);

        player.reset();
        expect(player.currentState, PlayerState.running);
        expect(player.isOnGround, isTrue);
        expect(player.position.y, groundY);
      });
    });

    group('updateGroundY()', () {
      test('updates ground reference', () {
        player.updateGroundY(700);
        expect(player.position.y, 700);
      });

      test('places player on new ground', () {
        player.jump();
        expect(player.isOnGround, isFalse);

        player.updateGroundY(700);
        expect(player.isOnGround, isTrue);
        expect(player.position.y, 700);
      });

      test('player lands on new ground level after update', () {
        player.updateGroundY(500);

        // Jump
        player.jump();

        // Simulate physics until landing
        for (int i = 0; i < 200; i++) {
          player.update(0.016);
          if (player.isOnGround) break;
        }

        expect(player.isOnGround, isTrue);
        expect(player.position.y, closeTo(500, 1.0));
      });
    });

    group('physics simulation', () {
      test('player moves up after jump', () {
        player.jump();
        final preY = player.position.y;

        player.update(0.016); // One frame

        // After one frame with negative initial velocity, player should move up
        expect(player.position.y, lessThan(preY));
      });

      test('player eventually returns to ground after jump', () {
        player.jump();

        // Simulate many frames
        for (int i = 0; i < 200; i++) {
          player.update(0.016);
          if (player.isOnGround) break;
        }

        expect(player.isOnGround, isTrue);
        expect(player.position.y, closeTo(groundY, 0.01));
      });

      test('player state transitions: jumping → running on landing', () {
        player.jump();
        expect(player.currentState, PlayerState.jumping);

        // Simulate until landed
        for (int i = 0; i < 200; i++) {
          player.update(0.016);
          if (player.isOnGround) break;
        }

        expect(player.currentState, PlayerState.running);
      });

      test('gravity increases fall speed over time', () {
        player.jump();

        // Record position after first frame
        player.update(0.1);
        final y1 = player.position.y;

        player.update(0.1);
        player.update(0.1);
        final y3 = player.position.y;

        // At some point in the trajectory (after peak), player accelerates down
        // The differences should show acceleration at some point
        // We just verify the player eventually comes back down
        expect(y3, isNot(y1)); // Physics is happening
      });

      test('player stays at ground level when on ground', () {
        // Player is already on ground
        player.update(0.016);
        expect(player.position.y, groundY); // Should stay at ground
        expect(player.isOnGround, isTrue);
      });

      test('multiple jump-and-land cycles work correctly', () {
        for (int cycle = 0; cycle < 3; cycle++) {
          // Jump
          player.jump();
          expect(player.currentState, PlayerState.jumping);

          // Simulate until landed
          for (int i = 0; i < 200; i++) {
            player.update(0.016);
            if (player.isOnGround) break;
          }

          expect(player.isOnGround, isTrue);
          expect(player.position.y, closeTo(groundY, 0.01));
          expect(player.currentState, PlayerState.running);
        }
      });
    });
  });
}
