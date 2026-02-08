import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/components/obstacle.dart';
import 'package:multigame/games/infinite_runner/components/player.dart';
import 'package:multigame/games/infinite_runner/systems/collision_system.dart';

/// Creates a Player for testing (without loading sprites)
Player _makePlayer({double x = 100, double y = 600}) {
  return Player(
    position: Vector2(x, y),
    size: Vector2(40, 60),
    groundY: y,
  );
}

/// Creates an Obstacle for testing (without loading sprites)
Obstacle _makeObstacle({
  double x = 100,
  double y = 600,
  ObstacleType type = ObstacleType.barrier,
  double width = 64,
  double height = 64,
}) {
  final obs = Obstacle(type: type, position: Vector2(x, y), scrollSpeed: 250);
  obs.size = Vector2(width, height);
  return obs;
}

void main() {
  group('CollisionSystem', () {
    late CollisionSystem collisionSystem;
    late bool collisionTriggered;

    setUp(() {
      collisionTriggered = false;
      collisionSystem = CollisionSystem(
        onCollision: () => collisionTriggered = true,
      );
    });

    group('initialization', () {
      test('collision not triggered initially', () {
        expect(collisionTriggered, isFalse);
      });

      test('checkCollisions with empty list does nothing', () {
        final player = _makePlayer();
        collisionSystem.checkCollisions(player, []);
        expect(collisionTriggered, isFalse);
      });
    });

    group('collision detection (overlapping)', () {
      test('detects collision when player and obstacle overlap', () {
        // Player at (100, 600), size (40, 60), bottomCenter anchor
        // Player rect: x: 80-120, y: 540-600
        //
        // Obstacle at (100, 600), size (64, 64), bottomLeft anchor
        // Obstacle rect: x: 100-164, y: 536-600
        //
        // Overlaps in both x (80-120 ∩ 100-164) and y (540-600 ∩ 536-600)
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 100, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isTrue);
      });

      test('detects collision when obstacle is directly at player position', () {
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 80, y: 600); // Centered on player

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isTrue);
      });

      test('detects collision when obstacle slightly overlaps player left side',
          () {
        // Player x range: 80-120
        // Obstacle needs to reach past x=80
        // obstacle at x=110, width=64 → x range: 110-174
        // 80 < 174 (aLeft < bRight) ✓
        // 120 > 110 (aRight > bLeft) ✓ → collision
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 110, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isTrue);
      });
    });

    group('no collision (non-overlapping)', () {
      test('no collision when obstacle is far to the right', () {
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 300, y: 600); // Far right

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isFalse);
      });

      test('no collision when obstacle has passed player (to the left)', () {
        // Player x range: 80-120
        // Obstacle at x=-100, width=64 → x range: -100 to -36
        // aLeft(80) < bRight(-36) → 80 < -36 → FALSE → no collision
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: -100, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isFalse);
      });

      test('no collision when obstacle is above player', () {
        // Player y range: 540-600 (bottom)
        // Obstacle at y=400, height=64 → y range: 336-400 (above player)
        // aTop(540) < bBottom(400) → 540 < 400 → FALSE → no collision
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 100, y: 400);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isFalse);
      });

      test('no collision when obstacle is below player (different ground)', () {
        final player = _makePlayer(x: 100, y: 600);
        // Obstacle at y=800 (below player), y range: 736-800
        // aBottom(600) > bTop(736) → 600 > 736 → FALSE → no collision
        final obstacle = _makeObstacle(x: 100, y: 800);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isFalse);
      });

      test('no collision when just barely not touching (1px gap)', () {
        // Player x range: 80-120 (player at 100, half-width 20)
        // Obstacle needs to be just to the right: x=121 → x range: 121-185
        // aRight(120) > bLeft(121) → 120 > 121 → FALSE → no collision
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 121, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);

        expect(collisionTriggered, isFalse);
      });
    });

    group('collision state management', () {
      test('collision triggered only once even with multiple calls', () {
        int callCount = 0;
        final sys = CollisionSystem(onCollision: () => callCount++);

        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 100, y: 600);

        sys.checkCollisions(player, [obstacle]);
        sys.checkCollisions(player, [obstacle]);
        sys.checkCollisions(player, [obstacle]);

        expect(callCount, 1); // Only called once
      });

      test('collision not triggered again after first hit', () {
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 100, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);
        expect(collisionTriggered, isTrue);

        // Reset the flag
        collisionTriggered = false;

        // Should NOT trigger again
        collisionSystem.checkCollisions(player, [obstacle]);
        expect(collisionTriggered, isFalse);
      });

      test('reset() allows new collision after first hit', () {
        final player = _makePlayer(x: 100, y: 600);
        final obstacle = _makeObstacle(x: 100, y: 600);

        collisionSystem.checkCollisions(player, [obstacle]);
        expect(collisionTriggered, isTrue);

        // Reset
        collisionSystem.reset();
        collisionTriggered = false;

        // Now collision should trigger again
        collisionSystem.checkCollisions(player, [obstacle]);
        expect(collisionTriggered, isTrue);
      });

      test('reset() on fresh system does nothing', () {
        expect(() => collisionSystem.reset(), returnsNormally);
        expect(collisionTriggered, isFalse);
      });
    });

    group('multiple obstacles', () {
      test('stops checking after first collision found', () {
        int callCount = 0;
        final sys = CollisionSystem(onCollision: () => callCount++);

        final player = _makePlayer(x: 100, y: 600);
        // Two colliding obstacles
        final obs1 = _makeObstacle(x: 100, y: 600);
        final obs2 = _makeObstacle(x: 110, y: 600);

        sys.checkCollisions(player, [obs1, obs2]);

        expect(callCount, 1); // Only one collision event
      });

      test('finds collision with second obstacle when first is clear', () {
        final player = _makePlayer(x: 100, y: 600);
        final safeObs = _makeObstacle(x: 300, y: 600); // Far right
        final collidingObs = _makeObstacle(x: 100, y: 600); // Collides

        collisionSystem.checkCollisions(player, [safeObs, collidingObs]);

        expect(collisionTriggered, isTrue);
      });

      test('no collision when all obstacles are clear', () {
        final player = _makePlayer(x: 100, y: 600);
        final obstacles = [
          _makeObstacle(x: 300, y: 600),
          _makeObstacle(x: 400, y: 600),
          _makeObstacle(x: 500, y: 600),
        ];

        collisionSystem.checkCollisions(player, obstacles);

        expect(collisionTriggered, isFalse);
      });
    });

    group('all obstacle types', () {
      for (final type in ObstacleType.values) {
        test('detects collision with ${type.name}', () {
          bool triggered = false;
          final sys = CollisionSystem(onCollision: () => triggered = true);

          final player = _makePlayer(x: 100, y: 600);
          final obstacle = _makeObstacle(x: 100, y: 600, type: type);

          sys.checkCollisions(player, [obstacle]);

          expect(triggered, isTrue, reason: '${type.name} should trigger');
        });
      }
    });
  });
}
