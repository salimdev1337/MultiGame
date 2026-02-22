import '../models/ludo_enums.dart';
import '../models/ludo_token.dart';

// ── Safe squares (absolute track positions 0-51) ───────────────────────────
const Set<int> kSafeSquares = {0, 8, 13, 21, 26, 34, 39, 47};

// ── Start positions per player (absolute track index) ─────────────────────
// Standard layout (clockwise from Red at top-left):
//   Red   (0)  = (1,6)  — exits top-left base going right along row 6
//   Green (13) = (8,1)  — exits top-right base going down along col 8
//   Yellow(26) = (13,8) — exits bottom-right base going left along row 8
//   Blue  (39) = (6,13) — exits bottom-left base going up along col 6
const Map<LudoPlayerColor, int> kStartPositions = {
  LudoPlayerColor.red: 0,
  LudoPlayerColor.green: 13,
  LudoPlayerColor.yellow: 26,
  LudoPlayerColor.blue: 39,
};

// ── Absolute track index → (col, row) on the 15×15 grid ───────────────────
// Standard Ludo board, clockwise from Red's start (col 1, row 6).
// Row 0 = top, Row 14 = bottom; Col 0 = left, Col 14 = right.
//
// Corner bases:
//   Red    = rows 0-5,  cols 0-5   (top-left)
//   Green  = rows 0-5,  cols 9-14  (top-right)
//   Blue   = rows 9-14, cols 0-5   (bottom-left)
//   Yellow = rows 9-14, cols 9-14  (bottom-right)
//
// Track lanes:
//   Left arm  (rows 6-8, cols 0-5):  row 6 = outgoing Red,  row 8 = incoming Blue
//   Top arm   (cols 6-8, rows 0-5):  col 6 = outgoing Red,  col 8 = incoming Green
//   Right arm (rows 6-8, cols 9-14): row 6 = outgoing Green, row 8 = incoming Yellow
//   Bottom arm(cols 6-8, rows 9-14): col 8 = outgoing Yellow,col 6 = incoming Blue
//
// Middle lanes (row 7 / col 7) are home columns only — tokens never share them.
const Map<int, (int col, int row)> kTrackCoords = {
  // ── Red's quadrant: exit base → right along row 6 → up left lane of top arm ─
  0:  (1,  6),   // Red's start (safe)
  1:  (2,  6),
  2:  (3,  6),
  3:  (4,  6),
  4:  (5,  6),
  5:  (6,  5),   // corner turn: right arm → top arm left lane
  6:  (6,  4),
  7:  (6,  3),
  8:  (6,  2),   // safe
  9:  (6,  1),
  10: (6,  0),
  11: (7,  0),   // across top
  12: (8,  0),   // across top
  // ── Green's quadrant: down right lane of top arm → right along row 6 ────────
  13: (8,  1),   // Green's start (safe)
  14: (8,  2),
  15: (8,  3),
  16: (8,  4),
  17: (8,  5),
  18: (9,  6),   // corner turn: top arm → right arm top lane
  19: (10, 6),
  20: (11, 6),
  21: (12, 6),   // safe
  22: (13, 6),
  23: (14, 6),
  24: (14, 7),   // down right edge
  25: (14, 8),   // down right edge
  // ── Yellow's quadrant: left along row 8 → down right lane of bottom arm ─────
  26: (13, 8),   // Yellow's start (safe)
  27: (12, 8),
  28: (11, 8),
  29: (10, 8),
  30: (9,  8),
  31: (8,  9),   // corner turn: right arm → bottom arm right lane
  32: (8,  10),
  33: (8,  11),
  34: (8,  12),  // safe
  35: (8,  13),
  36: (8,  14),
  37: (7,  14),  // across bottom
  38: (6,  14),  // across bottom
  // ── Blue's quadrant: up left lane of bottom arm → left along row 8 ──────────
  39: (6,  13),  // Blue's start (safe)
  40: (6,  12),
  41: (6,  11),
  42: (6,  10),
  43: (6,  9),
  44: (5,  8),   // corner turn: bottom arm → left arm bottom lane
  45: (4,  8),
  46: (3,  8),
  47: (2,  8),   // safe
  48: (1,  8),
  49: (0,  8),
  50: (0,  7),   // up left edge
  51: (0,  6),   // last track square before Red's home column
};

// ── Home column coords per player (steps 1-6, index 0 = step 1) ───────────
// Each list goes from the track entry inward toward the centre (7,7).
// All home columns occupy the MIDDLE lane of their respective arm (row 7 / col 7).
const Map<LudoPlayerColor, List<(int col, int row)>> kHomeColumnCoords = {
  // Red: row 7, entering from left (col 1) → inward (col 6)
  LudoPlayerColor.red: [
    (1, 7),
    (2, 7),
    (3, 7),
    (4, 7),
    (5, 7),
    (6, 7),
  ],
  // Green: col 7, entering from top (row 1) → inward (row 6)
  LudoPlayerColor.green: [
    (7, 1),
    (7, 2),
    (7, 3),
    (7, 4),
    (7, 5),
    (7, 6),
  ],
  // Yellow: row 7, entering from right (col 13) → inward (col 8)
  LudoPlayerColor.yellow: [
    (13, 7),
    (12, 7),
    (11, 7),
    (10, 7),
    (9,  7),
    (8,  7),
  ],
  // Blue: col 7, entering from bottom (row 13) → inward (row 8)
  LudoPlayerColor.blue: [
    (7, 13),
    (7, 12),
    (7, 11),
    (7, 10),
    (7,  9),
    (7,  8),
  ],
};

// ── Base slot coords per player (4 token slots in each corner base) ────────
const Map<LudoPlayerColor, List<(int col, int row)>> kBaseSlotCoords = {
  // Red — top-left base (rows 0-5, cols 0-5), slots centred around (2.5,2.5)
  LudoPlayerColor.red: [
    (2, 2),
    (3, 2),
    (2, 3),
    (3, 3),
  ],
  // Green — top-right base (rows 0-5, cols 9-14), slots centred around (11.5,2.5)
  LudoPlayerColor.green: [
    (11, 2),
    (12, 2),
    (11, 3),
    (12, 3),
  ],
  // Blue — bottom-left base (rows 9-14, cols 0-5), slots centred around (2.5,11.5)
  LudoPlayerColor.blue: [
    (2,  11),
    (3,  11),
    (2,  12),
    (3,  12),
  ],
  // Yellow — bottom-right base (rows 9-14, cols 9-14), slots centred around (11.5,11.5)
  LudoPlayerColor.yellow: [
    (11, 11),
    (12, 11),
    (11, 12),
    (12, 12),
  ],
};

/// Returns the (col, row) grid coordinate for [token] of [color].
(int col, int row) tokenGridCoord(LudoToken token, LudoPlayerColor color) {
  if (token.isFinished) {
    return kHomeColumnCoords[color]![5];
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
  return kTrackCoords[token.trackPosition] ?? (7, 7);
}

