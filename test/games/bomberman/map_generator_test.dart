import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';

void main() {
  group('MapGenerator — dimensions', () {
    late List<List<CellType>> grid;

    setUp(() {
      grid = MapGenerator.generate(seed: 42);
    });

    test('grid has correct number of rows (kGridH)', () {
      expect(grid.length, equals(kGridH));
      expect(kGridH, equals(13)); // guard against constant change
    });

    test('every row has correct number of cols (kGridW)', () {
      for (final row in grid) {
        expect(row.length, equals(kGridW));
      }
      expect(kGridW, equals(15)); // guard against constant change
    });
  });

  group('MapGenerator — border walls', () {
    late List<List<CellType>> grid;
    setUp(() => grid = MapGenerator.generate(seed: 42));

    test('entire top row is walls', () {
      for (int c = 0; c < kGridW; c++) {
        expect(grid[0][c], CellType.wall, reason: 'top border at col $c');
      }
    });

    test('entire bottom row is walls', () {
      for (int c = 0; c < kGridW; c++) {
        expect(
          grid[kGridH - 1][c],
          CellType.wall,
          reason: 'bottom border at col $c',
        );
      }
    });

    test('entire left column is walls', () {
      for (int r = 0; r < kGridH; r++) {
        expect(grid[r][0], CellType.wall, reason: 'left border at row $r');
      }
    });

    test('entire right column is walls', () {
      for (int r = 0; r < kGridH; r++) {
        expect(
          grid[r][kGridW - 1],
          CellType.wall,
          reason: 'right border at row $r',
        );
      }
    });
  });

  group('MapGenerator — interior pillars', () {
    late List<List<CellType>> grid;
    setUp(() => grid = MapGenerator.generate(seed: 42));

    test('cells at even-row AND even-col interior positions are walls', () {
      for (int r = 2; r < kGridH - 1; r += 2) {
        for (int c = 2; c < kGridW - 1; c += 2) {
          expect(
            grid[r][c],
            CellType.wall,
            reason: 'pillar at ($r,$c) should be wall',
          );
        }
      }
    });

    test('odd-row interior cells are NOT pillars', () {
      // Row 1, 3, 5… should not be walls (unless border)
      expect(grid[1][1], isNot(CellType.wall));
      expect(grid[3][3], isNot(CellType.wall));
    });

    test('even-row odd-col cells are NOT pillars', () {
      expect(grid[2][1], isNot(CellType.wall)); // even row, odd col
      expect(grid[4][3], isNot(CellType.wall));
    });

    test('odd-row even-col cells are NOT pillars', () {
      expect(grid[1][2], isNot(CellType.wall)); // odd row, even col
      expect(grid[3][4], isNot(CellType.wall));
    });
  });

  group('MapGenerator — spawn safe zones', () {
    late List<List<CellType>> grid;
    setUp(() => grid = MapGenerator.generate(seed: 42));

    test('player 0 spawn (top-left): row 1 cols 1-4 are empty', () {
      for (int c = 1; c <= 4; c++) {
        expect(grid[1][c], CellType.empty, reason: 'P0 spawn row 1 col $c');
      }
    });

    test('player 0 spawn (top-left): col 1 rows 1-4 are empty', () {
      for (int r = 1; r <= 4; r++) {
        expect(grid[r][1], CellType.empty, reason: 'P0 spawn col 1 row $r');
      }
    });

    test('player 1 spawn (top-right): row 1 cols W-5 to W-2 are empty', () {
      for (int c = kGridW - 5; c <= kGridW - 2; c++) {
        expect(grid[1][c], CellType.empty, reason: 'P1 spawn row 1 col $c');
      }
    });

    test('player 1 spawn (top-right): col W-2 rows 1-4 are empty', () {
      for (int r = 1; r <= 4; r++) {
        expect(
          grid[r][kGridW - 2],
          CellType.empty,
          reason: 'P1 spawn col ${kGridW - 2} row $r',
        );
      }
    });

    test('player 2 spawn (bottom-left): row H-2 cols 1-4 are empty', () {
      for (int c = 1; c <= 4; c++) {
        expect(
          grid[kGridH - 2][c],
          CellType.empty,
          reason: 'P2 spawn row ${kGridH - 2} col $c',
        );
      }
    });

    test('player 2 spawn (bottom-left): col 1 rows H-5 to H-2 are empty', () {
      for (int r = kGridH - 5; r <= kGridH - 2; r++) {
        expect(grid[r][1], CellType.empty, reason: 'P2 spawn col 1 row $r');
      }
    });

    test(
      'player 3 spawn (bottom-right): row H-2 cols W-5 to W-2 are empty',
      () {
        for (int c = kGridW - 5; c <= kGridW - 2; c++) {
          expect(
            grid[kGridH - 2][c],
            CellType.empty,
            reason: 'P3 spawn row ${kGridH - 2} col $c',
          );
        }
      },
    );

    test(
      'player 3 spawn (bottom-right): col W-2 rows H-5 to H-2 are empty',
      () {
        for (int r = kGridH - 5; r <= kGridH - 2; r++) {
          expect(
            grid[r][kGridW - 2],
            CellType.empty,
            reason: 'P3 spawn col ${kGridW - 2} row $r',
          );
        }
      },
    );
  });

  group('MapGenerator — interior cell types', () {
    late List<List<CellType>> grid;
    setUp(() => grid = MapGenerator.generate(seed: 42));

    test('non-pillar interior cells are only block or empty', () {
      for (int r = 1; r < kGridH - 1; r++) {
        for (int c = 1; c < kGridW - 1; c++) {
          if (r % 2 == 0 && c % 2 == 0) continue; // pillar
          final cell = grid[r][c];
          expect(
            cell == CellType.block || cell == CellType.empty,
            isTrue,
            reason: 'cell ($r,$c) = $cell should be block or empty',
          );
        }
      }
    });

    test('block density is roughly 60% in randomisable interior cells', () {
      // Average over 20 maps to reduce seed variance
      int totalRandomisable = 0;
      int totalBlocks = 0;
      for (int seed = 0; seed < 20; seed++) {
        final g = MapGenerator.generate(seed: seed);
        for (int r = 1; r < kGridH - 1; r++) {
          for (int c = 1; c < kGridW - 1; c++) {
            if (r % 2 == 0 && c % 2 == 0) continue; // pillar
            if (MapGenerator.generate(seed: seed)[r][c] == CellType.wall) {
              continue; // spawn safe or pillar
            }
            // Only count cells that can be block/empty
            if (g[r][c] == CellType.block || g[r][c] == CellType.empty) {
              totalRandomisable++;
              if (g[r][c] == CellType.block) totalBlocks++;
            }
          }
        }
      }
      final ratio = totalBlocks / totalRandomisable;
      // 60% target ±20% tolerance over 20 maps (spawn zones lower the average)
      expect(ratio, greaterThan(0.40));
      expect(ratio, lessThan(0.75));
    });
  });

  group('MapGenerator — determinism and seeding', () {
    test('same seed produces identical grid', () {
      final g1 = MapGenerator.generate(seed: 99);
      final g2 = MapGenerator.generate(seed: 99);
      for (int r = 0; r < kGridH; r++) {
        for (int c = 0; c < kGridW; c++) {
          expect(g1[r][c], g2[r][c], reason: 'cell ($r,$c) should match');
        }
      }
    });

    test('seed 0 produces a valid grid', () {
      final g = MapGenerator.generate(seed: 0);
      expect(g[0][0], CellType.wall); // border
      expect(g[1][1], CellType.empty); // spawn
    });

    test('different seeds produce substantially different grids', () {
      final g1 = MapGenerator.generate(seed: 1);
      final g2 = MapGenerator.generate(seed: 2);
      int diffCount = 0;
      for (int r = 1; r < kGridH - 1; r++) {
        for (int c = 1; c < kGridW - 1; c++) {
          if (g1[r][c] != g2[r][c]) diffCount++;
        }
      }
      // At 60% block rate with different seeds, many cells should differ
      expect(diffCount, greaterThan(10));
    });

    test('null seed (unseeded) generates a valid grid structure', () {
      // No seed — just verify structural invariants hold
      final g = MapGenerator.generate();
      expect(g[0][0], CellType.wall);
      expect(g.length, kGridH);
      expect(g[0].length, kGridW);
    });
  });

  group('MapGenerator.copy', () {
    late List<List<CellType>> grid;
    setUp(() => grid = MapGenerator.generate(seed: 42));

    test('copy is a deep copy — mutating copy does not affect original', () {
      final copy = MapGenerator.copy(grid);
      copy[1][1] = CellType.wall;
      expect(grid[1][1], isNot(CellType.wall));
    });

    test('copy of copy is also independent', () {
      final copy1 = MapGenerator.copy(grid);
      final copy2 = MapGenerator.copy(copy1);
      copy2[1][1] = CellType.wall;
      expect(copy1[1][1], isNot(CellType.wall));
      expect(grid[1][1], isNot(CellType.wall));
    });

    test('copy has same dimensions as original', () {
      final copy = MapGenerator.copy(grid);
      expect(copy.length, equals(kGridH));
      for (final row in copy) {
        expect(row.length, equals(kGridW));
      }
    });

    test('copy has identical cell values', () {
      final copy = MapGenerator.copy(grid);
      for (int r = 0; r < kGridH; r++) {
        for (int c = 0; c < kGridW; c++) {
          expect(
            copy[r][c],
            equals(grid[r][c]),
            reason: 'cell ($r,$c) mismatch',
          );
        }
      }
    });
  });
}
