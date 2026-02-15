import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/bomberman/logic/map_generator.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';

void main() {
  group('MapGenerator', () {
    late List<List<CellType>> grid;

    setUp(() {
      grid = MapGenerator.generate(seed: 42);
    });

    test('grid has correct dimensions', () {
      expect(grid.length, equals(kGridH));
      for (final row in grid) {
        expect(row.length, equals(kGridW));
      }
    });

    test('outer border is all permanent walls', () {
      for (int c = 0; c < kGridW; c++) {
        expect(grid[0][c], CellType.wall, reason: 'top border at col $c');
        expect(
          grid[kGridH - 1][c],
          CellType.wall,
          reason: 'bottom border at col $c',
        );
      }
      for (int r = 0; r < kGridH; r++) {
        expect(grid[r][0], CellType.wall, reason: 'left border at row $r');
        expect(
          grid[r][kGridW - 1],
          CellType.wall,
          reason: 'right border at row $r',
        );
      }
    });

    test('interior pillars at even-row, even-col are walls', () {
      for (int r = 2; r < kGridH - 1; r += 2) {
        for (int c = 2; c < kGridW - 1; c += 2) {
          expect(
            grid[r][c],
            CellType.wall,
            reason: 'pillar at ($r, $c) should be wall',
          );
        }
      }
    });

    test('spawn corners are clear (empty)', () {
      // Player 0 spawn: (1,1), (1,2), (2,1)
      expect(grid[1][1], CellType.empty);
      expect(grid[1][2], CellType.empty);
      expect(grid[2][1], CellType.empty);

      // Player 1 spawn: top-right
      expect(grid[1][kGridW - 2], CellType.empty);
      expect(grid[1][kGridW - 3], CellType.empty);
      expect(grid[2][kGridW - 2], CellType.empty);
    });

    test('interior non-pillar cells are block or empty only', () {
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

    test('generate with different seeds produces different grids', () {
      final grid1 = MapGenerator.generate(seed: 1);
      final grid2 = MapGenerator.generate(seed: 2);
      bool different = false;
      for (int r = 0; r < kGridH && !different; r++) {
        for (int c = 0; c < kGridW && !different; c++) {
          if (grid1[r][c] != grid2[r][c]) different = true;
        }
      }
      expect(different, isTrue);
    });

    test('generate with same seed produces identical grids', () {
      final g1 = MapGenerator.generate(seed: 99);
      final g2 = MapGenerator.generate(seed: 99);
      for (int r = 0; r < kGridH; r++) {
        for (int c = 0; c < kGridW; c++) {
          expect(g1[r][c], g2[r][c], reason: 'cell ($r,$c) should match');
        }
      }
    });

    test('copy returns independent copy', () {
      final copy = MapGenerator.copy(grid);
      copy[1][1] = CellType.wall;
      expect(grid[1][1], isNot(CellType.wall));
    });
  });
}
