import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/infinite_runner/components/obstacle.dart';

void main() {
  group('ObstacleType', () {
    group('enum values', () {
      test('has exactly 4 obstacle types', () {
        expect(ObstacleType.values.length, 4);
      });

      test('contains all expected types', () {
        expect(
          ObstacleType.values,
          containsAll([
            ObstacleType.barrier,
            ObstacleType.box,
            ObstacleType.tallBarrier,
            ObstacleType.highObstacle,
          ]),
        );
      });
    });

    group('sprite paths', () {
      test('barrier maps to correct sprite', () {
        expect(ObstacleType.barrier.spritePath, 'platformIndustrial_066.png');
      });

      test('box maps to correct sprite', () {
        expect(ObstacleType.box.spritePath, 'platformIndustrial_067.png');
      });

      test('tallBarrier maps to correct sprite', () {
        expect(
          ObstacleType.tallBarrier.spritePath,
          'platformIndustrial_068.png',
        );
      });

      test('highObstacle maps to correct sprite', () {
        expect(
          ObstacleType.highObstacle.spritePath,
          'platformIndustrial_069.png',
        );
      });

      test('all sprite paths are non-empty', () {
        for (final type in ObstacleType.values) {
          expect(type.spritePath, isNotEmpty, reason: '${type.name} path');
        }
      });

      test('all sprite paths are PNG files', () {
        for (final type in ObstacleType.values) {
          expect(
            type.spritePath,
            endsWith('.png'),
            reason: '${type.name} should be PNG',
          );
        }
      });
    });

    group('base dimensions', () {
      test('all types have 64 base width', () {
        for (final type in ObstacleType.values) {
          expect(type.baseWidth, 64.0, reason: '${type.name} baseWidth');
        }
      });

      test('all types have 64 base height', () {
        for (final type in ObstacleType.values) {
          expect(type.baseHeight, 64.0, reason: '${type.name} baseHeight');
        }
      });

      test('base dimensions are positive', () {
        for (final type in ObstacleType.values) {
          expect(type.baseWidth, greaterThan(0));
          expect(type.baseHeight, greaterThan(0));
        }
      });
    });

    group('requiresJump', () {
      test('barrier requires jump', () {
        expect(ObstacleType.barrier.requiresJump, isTrue);
      });

      test('box requires jump', () {
        expect(ObstacleType.box.requiresJump, isTrue);
      });

      test('tallBarrier requires jump', () {
        expect(ObstacleType.tallBarrier.requiresJump, isTrue);
      });

      test('highObstacle does NOT require jump', () {
        expect(ObstacleType.highObstacle.requiresJump, isFalse);
      });
    });

    group('requiresSlide', () {
      test('barrier does NOT require slide', () {
        expect(ObstacleType.barrier.requiresSlide, isFalse);
      });

      test('box does NOT require slide', () {
        expect(ObstacleType.box.requiresSlide, isFalse);
      });

      test('tallBarrier does NOT require slide', () {
        expect(ObstacleType.tallBarrier.requiresSlide, isFalse);
      });

      test('highObstacle requires slide', () {
        expect(ObstacleType.highObstacle.requiresSlide, isTrue);
      });
    });

    group('action exclusivity', () {
      test('requiresJump and requiresSlide are mutually exclusive', () {
        for (final type in ObstacleType.values) {
          final bothRequired = type.requiresJump && type.requiresSlide;
          expect(
            bothRequired,
            isFalse,
            reason: '${type.name} cannot require both jump and slide',
          );
        }
      });

      test('every obstacle requires exactly one action', () {
        for (final type in ObstacleType.values) {
          final eitherRequired = type.requiresJump || type.requiresSlide;
          expect(
            eitherRequired,
            isTrue,
            reason: '${type.name} must require jump or slide',
          );
        }
      });

      test('3 obstacles require jump and 1 requires slide', () {
        final jumpCount = ObstacleType.values
            .where((t) => t.requiresJump)
            .length;
        final slideCount = ObstacleType.values
            .where((t) => t.requiresSlide)
            .length;
        expect(jumpCount, 3);
        expect(slideCount, 1);
      });
    });

    group('random()', () {
      test('returns a valid ObstacleType', () {
        for (int i = 0; i < 50; i++) {
          final type = ObstacleType.random();
          expect(ObstacleType.values.contains(type), isTrue);
        }
      });

      test('produces all obstacle types over many calls', () {
        final types = <ObstacleType>{};
        for (int i = 0; i < 1000; i++) {
          types.add(ObstacleType.random());
        }
        // Should eventually generate all 4 types
        expect(types.length, 4);
      });

      test('is not always the same type', () {
        final types = <ObstacleType>{};
        for (int i = 0; i < 20; i++) {
          types.add(ObstacleType.random());
        }
        // With 20 calls, highly unlikely to always be the same
        expect(types.length, greaterThan(1));
      });
    });
  });
}
