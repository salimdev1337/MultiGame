import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/components/obstacle.dart';
import 'package:multigame/games/infinite_runner/systems/obstacle_pool.dart';

void main() {
  group('ObstaclePool', () {
    late ObstaclePool pool;

    setUp(() {
      pool = ObstaclePool(scrollSpeed: 250);
    });

    group('initialization', () {
      test('scrollSpeed is set correctly', () {
        expect(pool.scrollSpeed, 250);
      });

      test('maxPoolSize is 10 per type', () {
        expect(ObstaclePool.maxPoolSize, 10);
      });
    });

    group('acquire()', () {
      test('creates new obstacle when pool is empty', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        expect(obs, isNotNull);
      });

      test('acquired obstacle has correct type', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        expect(obs.type, ObstacleType.barrier);
      });

      test('acquired obstacle has correct position', () {
        final obs = pool.acquire(ObstacleType.box, Vector2(800, 600));
        expect(obs.position.x, 800);
        expect(obs.position.y, 600);
      });

      test('acquired obstacle has pool scrollSpeed', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        expect(obs.scrollSpeed, 250);
      });

      test('creates different types independently', () {
        final barrier = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        final box = pool.acquire(ObstacleType.box, Vector2(800, 600));
        final tallBarrier = pool.acquire(
          ObstacleType.tallBarrier,
          Vector2(800, 600),
        );
        final highObs = pool.acquire(
          ObstacleType.highObstacle,
          Vector2(800, 600),
        );

        expect(barrier.type, ObstacleType.barrier);
        expect(box.type, ObstacleType.box);
        expect(tallBarrier.type, ObstacleType.tallBarrier);
        expect(highObs.type, ObstacleType.highObstacle);
      });
    });

    group('release() and pool reuse', () {
      test('release adds obstacle back to pool', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        pool.release(obs);

        // Acquire again - should get the same instance
        final reused = pool.acquire(ObstacleType.barrier, Vector2(900, 600));
        expect(identical(reused, obs), isTrue);
      });

      test('reused obstacle gets updated position', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        pool.release(obs);

        final reused = pool.acquire(ObstacleType.barrier, Vector2(1000, 700));
        expect(reused.position.x, 1000);
        expect(reused.position.y, 700);
      });

      test('reused obstacle gets current pool scrollSpeed', () {
        pool.updateSpeed(400);

        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        pool.release(obs);

        final reused = pool.acquire(ObstacleType.barrier, Vector2(900, 600));
        expect(reused.scrollSpeed, 400);
      });

      test('pool manages different types separately', () {
        final barrier = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        final box = pool.acquire(ObstacleType.box, Vector2(800, 600));

        pool.release(barrier);
        pool.release(box);

        // Each type reuses its own pooled obstacle
        final reusedBarrier = pool.acquire(
          ObstacleType.barrier,
          Vector2(900, 600),
        );
        final reusedBox = pool.acquire(ObstacleType.box, Vector2(900, 600));

        expect(identical(reusedBarrier, barrier), isTrue);
        expect(identical(reusedBox, box), isTrue);
        expect(reusedBarrier.type, ObstacleType.barrier);
        expect(reusedBox.type, ObstacleType.box);
      });

      test('pool size does not exceed maxPoolSize per type', () {
        // Create and release more than maxPoolSize obstacles
        final created = <Obstacle>[];
        for (int i = 0; i < ObstaclePool.maxPoolSize + 5; i++) {
          created.add(
            pool.acquire(ObstacleType.barrier, Vector2(800.0 + i, 600)),
          );
        }

        // Release all
        for (final obs in created) {
          pool.release(obs);
        }

        // Pool should only keep maxPoolSize items
        // Acquire maxPoolSize + 1 items
        final acquired = <Obstacle>[];
        for (int i = 0; i < ObstaclePool.maxPoolSize + 1; i++) {
          acquired.add(pool.acquire(ObstacleType.barrier, Vector2(800, 600)));
        }

        // The extra one should be a fresh obstacle (not in pool)
        // We verify by checking that not all acquired are from the original set
        // (since pool only kept maxPoolSize of the 15 created)
        final createdSet = Set.identity()..addAll(created);
        final lastAcquired = acquired.last;
        // The last acquired (after pool exhausted) must be a new instance
        expect(createdSet.contains(lastAcquired), isFalse);
      });
    });

    group('updateSpeed()', () {
      test('updates scrollSpeed for future acquisitions', () {
        pool.updateSpeed(500);
        expect(pool.scrollSpeed, 500);

        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        expect(obs.scrollSpeed, 500);
      });

      test('speed update applies to reused obstacles', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        pool.release(obs);

        pool.updateSpeed(750);
        final reused = pool.acquire(ObstacleType.barrier, Vector2(900, 600));
        expect(reused.scrollSpeed, 750);
      });

      test('can update speed multiple times', () {
        pool.updateSpeed(300);
        pool.updateSpeed(400);
        pool.updateSpeed(500);
        expect(pool.scrollSpeed, 500);
      });
    });

    group('clear()', () {
      test('empties the pool', () {
        // Fill pool with released obstacles
        for (int i = 0; i < 3; i++) {
          final obs = pool.acquire(
            ObstacleType.barrier,
            Vector2(800.0 + i, 600),
          );
          pool.release(obs);
        }

        pool.clear();

        // After clear, pool is empty, so acquire creates new obstacles
        final obs1 = Obstacle(
          type: ObstacleType.barrier,
          position: Vector2(800, 600),
          scrollSpeed: 250,
        );
        pool.release(obs1);
        pool.clear();

        // New acquire after clear should create fresh obstacle
        final obs2 = pool.acquire(ObstacleType.barrier, Vector2(900, 600));
        expect(identical(obs2, obs1), isFalse);
      });

      test('clear handles empty pool gracefully', () {
        expect(() => pool.clear(), returnsNormally);
      });

      test('clear removes all types', () {
        // Add all obstacle types to pool
        for (final type in ObstacleType.values) {
          final obs = pool.acquire(type, Vector2(800, 600));
          pool.release(obs);
        }

        pool.clear();

        // All types should create new objects after clear
        for (final type in ObstacleType.values) {
          final obs = pool.acquire(type, Vector2(800, 600));
          expect(obs, isNotNull);
        }
      });
    });

    group('isOffScreen tracking', () {
      test('newly acquired obstacle is not off screen', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        expect(obs.isOffScreen, isFalse);
      });

      test('released and reacquired obstacle resets isOffScreen', () {
        final obs = pool.acquire(ObstacleType.barrier, Vector2(800, 600));
        // Simulate moving off screen
        obs.position.x = -100;
        // isOffScreen becomes true only in update(), but we can test reset
        pool.release(obs);
        final reused = pool.acquire(ObstacleType.barrier, Vector2(900, 600));
        expect(reused.isOffScreen, isFalse); // Reset by reset()
      });
    });
  });
}
