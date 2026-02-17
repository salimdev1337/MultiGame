import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/connect_four/logic/connect_four_logic.dart';
import 'package:multigame/games/connect_four/models/connect_four_enums.dart';
import 'package:multigame/games/connect_four/models/connect_four_state.dart';

void main() {
  // ── landingRow ────────────────────────────────────────────────────────────

  group('landingRow', () {
    test('empty column lands at row 0', () {
      final g = ConnectFourState.emptyGrid();
      expect(landingRow(g, 0), 0);
    });

    test('partially filled column lands above last piece', () {
      final g = ConnectFourState.emptyGrid();
      final g2 = dropPiece(g, 3, 0, 1);
      final g3 = dropPiece(g2, 3, 1, 2);
      expect(landingRow(g3, 3), 2);
    });

    test('full column returns -1', () {
      var g = ConnectFourState.emptyGrid();
      for (var row = 0; row < kCFRows; row++) {
        g = dropPiece(g, 0, row, 1);
      }
      expect(landingRow(g, 0), -1);
    });
  });

  // ── canDrop ───────────────────────────────────────────────────────────────

  group('canDrop', () {
    test('returns true on empty column', () {
      final g = ConnectFourState.emptyGrid();
      expect(canDrop(g, 2), isTrue);
    });

    test('returns false on full column', () {
      var g = ConnectFourState.emptyGrid();
      for (var row = 0; row < kCFRows; row++) {
        g = dropPiece(g, 5, row, 1);
      }
      expect(canDrop(g, 5), isFalse);
    });
  });

  // ── dropPiece ─────────────────────────────────────────────────────────────

  group('dropPiece', () {
    test('places piece at given cell', () {
      final g = ConnectFourState.emptyGrid();
      final next = dropPiece(g, 2, 0, 1);
      expect(next[2][0], 1);
    });

    test('does not mutate the original grid', () {
      final g = ConnectFourState.emptyGrid();
      dropPiece(g, 2, 0, 1);
      expect(g[2][0], 0);
    });

    test('multiple drops stack correctly', () {
      var g = ConnectFourState.emptyGrid();
      g = dropPiece(g, 0, landingRow(g, 0), 1);
      g = dropPiece(g, 0, landingRow(g, 0), 2);
      expect(g[0][0], 1);
      expect(g[0][1], 2);
    });
  });

  // ── checkWin ──────────────────────────────────────────────────────────────

  group('checkWin', () {
    test('horizontal win detected', () {
      var g = ConnectFourState.emptyGrid();
      for (var col = 0; col < 4; col++) {
        g = dropPiece(g, col, 0, 1);
      }
      final win = checkWin(g, 3, 0, 1);
      expect(win.length, 4);
    });

    test('vertical win detected', () {
      var g = ConnectFourState.emptyGrid();
      for (var row = 0; row < 4; row++) {
        g = dropPiece(g, 2, row, 2);
      }
      final win = checkWin(g, 2, 3, 2);
      expect(win.length, 4);
    });

    test('diagonal \\ win detected', () {
      var g = ConnectFourState.emptyGrid();
      // Place filler pieces so player 1 can build diagonal col0r0, col1r1, col2r2, col3r3
      // col0 row0
      g = dropPiece(g, 0, 0, 1);
      // col1 needs filler at row0 first
      g = dropPiece(g, 1, 0, 2);
      g = dropPiece(g, 1, 1, 1);
      // col2 needs filler at row0,row1
      g = dropPiece(g, 2, 0, 2);
      g = dropPiece(g, 2, 1, 2);
      g = dropPiece(g, 2, 2, 1);
      // col3 needs filler at row0,row1,row2
      g = dropPiece(g, 3, 0, 2);
      g = dropPiece(g, 3, 1, 2);
      g = dropPiece(g, 3, 2, 2);
      g = dropPiece(g, 3, 3, 1);
      final win = checkWin(g, 3, 3, 1);
      expect(win.length, 4);
    });

    test('no win returns empty', () {
      final g = ConnectFourState.emptyGrid();
      final next = dropPiece(g, 0, 0, 1);
      final win = checkWin(next, 0, 0, 1);
      expect(win, isEmpty);
    });

    test('three-in-a-row does NOT win', () {
      var g = ConnectFourState.emptyGrid();
      g = dropPiece(g, 0, 0, 1);
      g = dropPiece(g, 1, 0, 1);
      g = dropPiece(g, 2, 0, 1);
      final win = checkWin(g, 2, 0, 1);
      expect(win, isEmpty);
    });

    test('five-in-a-row returns 4 cells', () {
      var g = ConnectFourState.emptyGrid();
      for (var col = 0; col < 5; col++) {
        g = dropPiece(g, col, 0, 1);
      }
      final win = checkWin(g, 4, 0, 1);
      expect(win.length, 4);
    });
  });

  // ── isDraw ────────────────────────────────────────────────────────────────

  group('isDraw', () {
    test('empty grid is not a draw', () {
      final g = ConnectFourState.emptyGrid();
      expect(isDraw(g), isFalse);
    });

    test('full grid is a draw', () {
      var g = ConnectFourState.emptyGrid();
      for (var col = 0; col < kCFCols; col++) {
        for (var row = 0; row < kCFRows; row++) {
          g = dropPiece(g, col, row, (col + row) % 2 + 1);
        }
      }
      expect(isDraw(g), isTrue);
    });

    test('one empty cell is not a draw', () {
      var g = ConnectFourState.emptyGrid();
      for (var col = 0; col < kCFCols; col++) {
        for (var row = 0; row < kCFRows; row++) {
          if (col == 6 && row == 5) {
            continue; // leave top-right empty
          }
          g = dropPiece(g, col, row, 1);
        }
      }
      expect(isDraw(g), isFalse);
    });
  });

  // ── validColumns ──────────────────────────────────────────────────────────

  group('validColumns', () {
    test('all 7 columns valid on empty grid', () {
      final g = ConnectFourState.emptyGrid();
      expect(validColumns(g).length, 7);
    });

    test('full column excluded', () {
      var g = ConnectFourState.emptyGrid();
      for (var row = 0; row < kCFRows; row++) {
        g = dropPiece(g, 0, row, 1);
      }
      expect(validColumns(g), isNot(contains(0)));
      expect(validColumns(g).length, 6);
    });
  });

  // ── getBotMove ────────────────────────────────────────────────────────────

  group('getBotMove', () {
    test('easy bot wins immediately if possible', () {
      // Three in a row for bot (player 2) — bot should complete to 4
      var g = ConnectFourState.emptyGrid();
      g = dropPiece(g, 0, 0, 2);
      g = dropPiece(g, 1, 0, 2);
      g = dropPiece(g, 2, 0, 2);
      final move = getBotMove(g, ConnectFourDifficulty.easy, 2);
      expect(move, 3);
    });

    test('easy bot blocks opponent win', () {
      // Three in a row for player 1 — bot should block at col 3
      var g = ConnectFourState.emptyGrid();
      g = dropPiece(g, 0, 0, 1);
      g = dropPiece(g, 1, 0, 1);
      g = dropPiece(g, 2, 0, 1);
      final move = getBotMove(g, ConnectFourDifficulty.easy, 2);
      expect(move, 3);
    });

    test('medium bot returns a valid column', () {
      final g = ConnectFourState.emptyGrid();
      final move = getBotMove(g, ConnectFourDifficulty.medium, 2);
      expect(validColumns(g), contains(move));
    });

    test('hard bot returns a valid column', () {
      final g = ConnectFourState.emptyGrid();
      final move = getBotMove(g, ConnectFourDifficulty.hard, 2);
      expect(validColumns(g), contains(move));
    });

    test('bot returns -1 on full board', () {
      var g = ConnectFourState.emptyGrid();
      for (var col = 0; col < kCFCols; col++) {
        for (var row = 0; row < kCFRows; row++) {
          g = dropPiece(g, col, row, 1);
        }
      }
      expect(getBotMove(g, ConnectFourDifficulty.easy, 2), -1);
    });
  });
}
