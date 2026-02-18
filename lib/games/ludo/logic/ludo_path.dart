import '../models/ludo_enums.dart';
import '../models/ludo_token.dart';

// ── Safe squares (absolute track positions 0-51) ───────────────────────────
const Set<int> kSafeSquares = {0, 8, 13, 21, 26, 34, 39, 47};

// ── Start positions per player (absolute track index) ─────────────────────
// Each start square is adjacent to the player's corner base on the board:
//   Red (0)    = (6,14) — just right of the bottom-left base
//   Yellow (13) = (1,6)  — just below the top-left base
//   Blue (26)  = (8,1)  — just left of the top-right base
//   Green (39) = (13,8) — just above the bottom-right base
const Map<LudoPlayerColor, int> kStartPositions = {
  LudoPlayerColor.red: 0,
  LudoPlayerColor.yellow: 13,
  LudoPlayerColor.blue: 26,
  LudoPlayerColor.green: 39,
};

// ── Absolute track index → (col, row) on the 15×15 grid ───────────────────
// Standard Ludo board, clockwise from Red's start (column 6, row 14).
// Row 0 = top, Row 14 = bottom; Col 0 = left, Col 14 = right.
const Map<int, (int col, int row)> kTrackCoords = {
  // Red home column approach + right side going up
  0: (6, 14),
  1: (6, 13),
  2: (6, 12),
  3: (6, 11),
  4: (6, 10),
  5: (5, 9),
  // Top-left quadrant (going left along row 8)
  6: (4, 9),
  7: (3, 9),
  8: (2, 9),
  9: (1, 9),
  10: (0, 9),
  // Turn up
  11: (0, 8),
  12: (0, 7),
  // Top-left corner going right
  13: (1, 6),
  14: (2, 6),
  15: (3, 6),
  16: (4, 6),
  17: (5, 6),
  18: (5, 5),
  // Going up through Blue start
  19: (5, 4),
  20: (5, 3),
  21: (5, 2),
  22: (5, 1),
  23: (5, 0),
  // Turn right
  24: (6, 0),
  25: (7, 0),
  // Top-right corner going down
  26: (8, 1),
  27: (8, 2),
  28: (8, 3),
  29: (8, 4),
  30: (8, 5),
  31: (9, 5),
  // Going right along row 5
  32: (10, 5),
  33: (11, 5),
  34: (12, 5),
  35: (13, 5),
  36: (14, 5),
  // Turn down
  37: (14, 6),
  38: (14, 7),
  // Right side going down
  39: (13, 8),
  40: (12, 8),
  41: (11, 8),
  42: (10, 8),
  43: (9, 8),
  44: (9, 9),
  // Going down through Yellow start
  45: (9, 10),
  46: (9, 11),
  47: (9, 12),
  48: (9, 13),
  49: (9, 14),
  // Turn left
  50: (8, 14),
  51: (7, 14),
};

// ── Home column coords per player (steps 1-6, index 0 = step 1) ───────────
// Each list goes from the track entry inward toward the centre.
const Map<LudoPlayerColor, List<(int col, int row)>> kHomeColumnCoords = {
  LudoPlayerColor.red: [
    (1, 8),
    (2, 8),
    (3, 8),
    (4, 8),
    (5, 8),
    (6, 8),
  ],
  LudoPlayerColor.blue: [
    (8, 1),
    (8, 2),
    (8, 3),
    (8, 4),
    (8, 5),
    (8, 6),
  ],
  LudoPlayerColor.green: [
    (13, 6),
    (12, 6),
    (11, 6),
    (10, 6),
    (9, 6),
    (8, 6),
  ],
  LudoPlayerColor.yellow: [
    (6, 13),
    (6, 12),
    (6, 11),
    (6, 10),
    (6, 9),
    (6, 8),
  ],
};

// ── Base slot coords per player (4 token slots in each corner base) ────────
const Map<LudoPlayerColor, List<(int col, int row)>> kBaseSlotCoords = {
  LudoPlayerColor.red: [
    (2, 11),
    (3, 11),
    (2, 12),
    (3, 12),
  ],
  LudoPlayerColor.blue: [
    (11, 2),
    (12, 2),
    (11, 3),
    (12, 3),
  ],
  LudoPlayerColor.green: [
    (11, 11),
    (12, 11),
    (11, 12),
    (12, 12),
  ],
  LudoPlayerColor.yellow: [
    (2, 2),
    (3, 2),
    (2, 3),
    (3, 3),
  ],
};

/// Returns the (col, row) grid coordinate for [token] of [color].
(int col, int row) tokenGridCoord(LudoToken token, LudoPlayerColor color) {
  if (token.isFinished) {
    // Centre of the board
    return (7, 7);
  }
  if (token.isInBase) {
    final slots = kBaseSlotCoords[color]!;
    return slots[token.id.clamp(0, 3)];
  }
  if (token.isInHomeColumn) {
    final col = kHomeColumnCoords[color]!;
    final step = token.homeColumnStep.clamp(1, 6);
    return col[step - 1];
  }
  // On the shared track
  return kTrackCoords[token.trackPosition] ?? (7, 7);
}
