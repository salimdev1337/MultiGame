import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/components/obstacle.dart';
import 'package:multigame/games/infinite_runner/systems/obstacle_pool.dart';
import 'package:multigame/games/infinite_runner/systems/spawn_system.dart';

void main() {
  group('SpawnSystem', () {
    late ObstaclePool pool;
    late SpawnSystem spawnSystem;

    setUp(() {
      pool = ObstaclePool(scrollSpeed: 250);
      spawnSystem = SpawnSystem(
        gameWidth: 800,
        groundY: 600,
        obstaclePool: pool,
      );
    });

    group('initialization', () {
      test('gameWidth is set correctly', () {
        expect(spawnSystem.gameWidth, 800);
      });

      test('groundY is set correctly', () {
        expect(spawnSystem.groundY, 600);
      });

      test('obstaclePool is assigned', () {
        expect(spawnSystem.obstaclePool, same(pool));
      });

      test('spawn constants are correct', () {
        expect(SpawnSystem.minSpawnDistance, 350.0);
        expect(SpawnSystem.maxSpawnDistance, 600.0);
        expect(SpawnSystem.spawnX, 100.0);
      });
    });

    group('update() spawning behavior', () {
      test('spawns obstacle when distance threshold is reached', () {
        // dt=1.0, speed=350: distance = 350 = minSpawnDistance → spawns
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
      });

      test('spawned obstacle has correct type and speed', () {
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
        expect(ObstacleType.values.contains(obs!.type), isTrue);
        expect(obs.scrollSpeed, 250); // Pool's scroll speed
      });

      test('spawned obstacle position is at expected spawn X', () {
        // spawnPositionX = gameWidth + spawnX = 800 + 100 = 900
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
        expect(obs!.position.x, 900.0);
      });

      test('spawned obstacle Y position is at groundY', () {
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
        expect(obs!.position.y, 600.0);
      });

      test('does not spawn when distance not reached', () {
        // Small increments that won't reach 350
        for (int i = 0; i < 100; i++) {
          // 100 * 0.001 * 250 = 25, far less than 350
          final obs = spawnSystem.update(0.001, 250, []);
          expect(obs, isNull);
        }
      });

      test('does not spawn when obstacle too close to spawn position', () {
        // spawnPositionX = gameWidth + spawnX = 800 + 100 = 900
        // Obstacle at 900 means distance = 0, which is < minSpawnDistance(350)
        final nearbyObs = Obstacle(
          type: ObstacleType.barrier,
          position: Vector2(900, 600),
          scrollSpeed: 250,
        );

        final result = spawnSystem.update(1.0, 350, [nearbyObs]);
        expect(result, isNull);
      });

      test('spawns when obstacle is far enough away', () {
        // Obstacle at position 0 (left side), spawn at 900
        // Distance = 900 - 0 = 900 > 350 → safe to spawn
        final farObs = Obstacle(
          type: ObstacleType.barrier,
          position: Vector2(0, 600),
          scrollSpeed: 250,
        );

        final result = spawnSystem.update(1.0, 350, [farObs]);
        expect(result, isNotNull);
      });

      test('handles empty obstacle list', () {
        final obs = spawnSystem.update(1.0, 600, []);
        expect(obs, isNotNull);
      });
    });

    group('obstacle type variety', () {
      test('avoids consecutive duplicate obstacle types', () {
        final types = <ObstacleType>[];

        // Collect 15 spawned obstacle types
        for (int i = 0; i < 200 && types.length < 15; i++) {
          // Use large dt to ensure frequent spawns
          final obs = spawnSystem.update(1.0, 600, []);
          if (obs != null) {
            types.add(obs.type);
          }
        }

        expect(types.length, greaterThanOrEqualTo(10));

        // No consecutive duplicates
        for (int i = 1; i < types.length; i++) {
          expect(
            types[i],
            isNot(equals(types[i - 1])),
            reason:
                'Position $i: ${types[i].name} should differ from ${types[i - 1].name}',
          );
        }
      });

      test('produces varied obstacle types over many spawns', () {
        final uniqueTypes = <ObstacleType>{};

        for (int i = 0; i < 500; i++) {
          final obs = spawnSystem.update(1.0, 600, []);
          if (obs != null) {
            uniqueTypes.add(obs.type);
          }
        }

        // Over 500 updates, should see all 4 types
        expect(uniqueTypes.length, 4);
      });
    });

    group('reset()', () {
      test('after reset, first spawn happens at minSpawnDistance', () {
        // Advance some distance
        for (int i = 0; i < 10; i++) {
          spawnSystem.update(0.1, 250, []);
        }

        // Reset
        spawnSystem.reset();

        // Now first spawn should require minSpawnDistance again
        // With dt=1.0 and speed=350, distance = 350 = minSpawnDistance
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
      });

      test('reset clears last obstacle type memory', () {
        // First spawn
        final type1 = spawnSystem.update(1.0, 350, [])?.type;
        expect(type1, isNotNull);

        // Reset clears memory
        spawnSystem.reset();

        // After reset, any type can appear (including type1)
        final types = <ObstacleType>{};
        for (int i = 0; i < 50; i++) {
          spawnSystem.reset();
          final obs = spawnSystem.update(1.0, 350, []);
          if (obs != null) types.add(obs.type);
        }
        // Should eventually see type1 again since memory was cleared
        expect(types, contains(type1));
      });
    });

    group('updateDimensions()', () {
      test('updates gameWidth', () {
        spawnSystem.updateDimensions(1200, 700);
        expect(spawnSystem.gameWidth, 1200);
      });

      test('updates groundY', () {
        spawnSystem.updateDimensions(1200, 700);
        expect(spawnSystem.groundY, 700);
      });

      test('spawns at new spawn position after dimension update', () {
        spawnSystem.updateDimensions(1000, 700);

        // New spawnPositionX = 1000 + 100 = 1100
        final obs = spawnSystem.update(1.0, 350, []);
        expect(obs, isNotNull);
        expect(obs!.position.x, 1100.0); // Updated spawn X
        expect(obs.position.y, 700.0); // Updated groundY
      });
    });

    group('_canSpawnSafely edge cases', () {
      test('safely handles multiple obstacles with varied positions', () {
        final obstacles = [
          Obstacle(
            type: ObstacleType.barrier,
            position: Vector2(200, 600),
            scrollSpeed: 250,
          ),
          Obstacle(
            type: ObstacleType.box,
            position: Vector2(400, 600),
            scrollSpeed: 250,
          ),
          Obstacle(
            type: ObstacleType.tallBarrier,
            position: Vector2(600, 600),
            scrollSpeed: 250,
          ),
        ];

        // Rightmost at 600, spawn at 900, distance = 300 < 350 → blocked
        final result = spawnSystem.update(1.0, 350, obstacles);
        expect(result, isNull);
      });

      test('uses rightmost obstacle for safe spawn check', () {
        final obstacles = [
          Obstacle(
            type: ObstacleType.barrier,
            position: Vector2(100, 600),
            scrollSpeed: 250,
          ),
          Obstacle(
            type: ObstacleType.box,
            position: Vector2(800, 600),
            scrollSpeed: 250,
          ), // Rightmost
        ];

        // Rightmost at 800, spawn at 900, distance = 100 < 350 → blocked
        final result = spawnSystem.update(1.0, 350, obstacles);
        expect(result, isNull);
      });
    });
  });
}
