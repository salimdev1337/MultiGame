import 'dart:math';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';

/// Generates the classic Bomberman grid layout.
///
/// Rules:
/// - Outer ring: permanent walls
/// - Even-row AND even-col interior cells: permanent wall pillars
/// - Remaining interior: 60% destructible blocks, rest empty
/// - Player spawn corners (3×3) guaranteed clear
class MapGenerator {
  static List<List<CellType>> generate({int? seed}) {
    final rng = Random(seed);

    // Build grid of size kGridH rows × kGridW cols
    final grid = List.generate(
      kGridH,
      (r) => List.generate(kGridW, (c) => _cellFor(r, c, rng)),
    );

    return grid;
  }

  static CellType _cellFor(int r, int c, Random rng) {
    // Outer border → permanent wall
    if (r == 0 || r == kGridH - 1 || c == 0 || c == kGridW - 1) {
      return CellType.wall;
    }

    // Interior pillar: both row and col are even (1-indexed: r%2==0, c%2==0)
    if (r % 2 == 0 && c % 2 == 0) {
      return CellType.wall;
    }

    // Spawn safe zones: top-left, top-right, bottom-left, bottom-right corners
    if (_isSpawnSafe(r, c)) return CellType.empty;

    // 60% blocks in remaining interior
    return rng.nextDouble() < 0.60 ? CellType.block : CellType.empty;
  }

  /// Marks spawn safe zones: 4 cells along each axis from every corner spawn.
  /// This guarantees ~3 cells of free movement in each direction from spawn.
  static bool _isSpawnSafe(int r, int c) {
    // Player 0: top-left — clear row 1 cols 1-4, col 1 rows 1-4
    if (r == 1 && c >= 1 && c <= 4) return true;
    if (c == 1 && r >= 1 && r <= 4) return true;

    // Player 1: top-right — clear row 1 cols (W-5)-(W-2), col (W-2) rows 1-4
    if (r == 1 && c >= kGridW - 5 && c <= kGridW - 2) return true;
    if (c == kGridW - 2 && r >= 1 && r <= 4) return true;

    // Player 2: bottom-left — clear row (H-2) cols 1-4, col 1 rows (H-5)-(H-2)
    if (r == kGridH - 2 && c >= 1 && c <= 4) return true;
    if (c == 1 && r >= kGridH - 5 && r <= kGridH - 2) return true;

    // Player 3: bottom-right — clear row (H-2) cols (W-5)-(W-2), col (W-2) rows (H-5)-(H-2)
    if (r == kGridH - 2 && c >= kGridW - 5 && c <= kGridW - 2) return true;
    if (c == kGridW - 2 && r >= kGridH - 5 && r <= kGridH - 2) return true;

    return false;
  }

  /// Returns a deep copy of the grid so state mutations don't share references.
  static List<List<CellType>> copy(List<List<CellType>> src) =>
      src.map((row) => List<CellType>.from(row)).toList();
}
