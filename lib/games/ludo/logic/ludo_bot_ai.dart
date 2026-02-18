import 'dart:math';

import '../models/ludo_enums.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'ludo_logic.dart';

final _rng = Random();

// ── Public dispatcher ──────────────────────────────────────────────────────

/// Selects a token ID to move based on the difficulty level.
/// Returns -1 if there are no valid moves.
int botDecide(
  LudoDifficulty difficulty,
  LudoPlayer player,
  int diceValue,
  List<LudoPlayer> all,
) {
  switch (difficulty) {
    case LudoDifficulty.easy:
      return botDecideEasy(player, diceValue, all);
    case LudoDifficulty.medium:
      return botDecideMedium(player, diceValue, all);
    case LudoDifficulty.hard:
      return botDecideHard(player, diceValue, all);
  }
}

// ── Easy bot — random valid move ──────────────────────────────────────────

/// Easy: picks a random valid token to move.
int botDecideEasy(LudoPlayer player, int diceValue, List<LudoPlayer> all) {
  final movable = computeMovableTokenIds(player, diceValue, all);
  if (movable.isEmpty) {
    return -1;
  }
  return movable[_rng.nextInt(movable.length)];
}

// ── Medium bot — heuristic priority ──────────────────────────────────────

/// Medium: capture > launch from base > advance furthest > any valid.
int botDecideMedium(LudoPlayer player, int diceValue, List<LudoPlayer> all) {
  final movable = computeMovableTokenIds(player, diceValue, all);
  if (movable.isEmpty) {
    return -1;
  }

  // 1. Prefer a token that would capture an opponent.
  final captureId = _findCapture(player, movable, diceValue, all);
  if (captureId != -1) {
    return captureId;
  }

  // 2. Prefer launching from base (free extra turn + opens up tokens).
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (token.isInBase) {
      return id;
    }
  }

  // 3. Advance the furthest-along non-finished token.
  return _advanceFurthest(player, movable);
}

// ── Hard bot — aggressive priorities ─────────────────────────────────────

/// Hard: capture > block opponent near home > advance home-column token > launch > advance furthest.
int botDecideHard(LudoPlayer player, int diceValue, List<LudoPlayer> all) {
  final movable = computeMovableTokenIds(player, diceValue, all);
  if (movable.isEmpty) {
    return -1;
  }

  // 1. Capture.
  final captureId = _findCapture(player, movable, diceValue, all);
  if (captureId != -1) {
    return captureId;
  }

  // 2. Block: move to a square adjacent to an opponent who is close to home.
  final blockId = _findBlock(player, movable, diceValue, all);
  if (blockId != -1) {
    return blockId;
  }

  // 3. Advance a token already in the home column.
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (token.isInHomeColumn) {
      return id;
    }
  }

  // 4. Launch from base.
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (token.isInBase) {
      return id;
    }
  }

  // 5. Advance furthest token.
  return _advanceFurthest(player, movable);
}

// ── Internal helpers ───────────────────────────────────────────────────────

/// Finds a token that would land on an opponent token after [diceValue] steps.
int _findCapture(
  LudoPlayer player,
  List<int> movable,
  int diceValue,
  List<LudoPlayer> all,
) {
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (!token.isOnTrack) {
      continue;
    }
    final afterMove = advanceToken(token, diceValue, player.color);
    if (afterMove.isOnTrack) {
      final targets = captureTargets(
        afterMove.trackPosition,
        player.color,
        all,
        false,
      );
      if (targets.isNotEmpty) {
        return id;
      }
    }
  }
  return -1;
}

/// Finds a token that can be placed on or near an opponent who is close to
/// finishing (> 40 relative steps along).  Used to interfere with opponents.
int _findBlock(
  LudoPlayer player,
  List<int> movable,
  int diceValue,
  List<LudoPlayer> all,
) {
  // Identify opponent tokens that are far along (rel > 40).
  final threateningPositions = <int>[];
  for (final other in all) {
    if (other.color == player.color) {
      continue;
    }
    for (final t in other.tokens) {
      if (!t.isOnTrack) {
        continue;
      }
      final rel = toRelativePosition(t.trackPosition, other.color);
      if (rel > 40) {
        threateningPositions.add(t.trackPosition);
      }
    }
  }
  if (threateningPositions.isEmpty) {
    return -1;
  }

  // Find a movable token that would land 1-2 squares behind a threat.
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (!token.isOnTrack) {
      continue;
    }
    if (wouldOvershoot(token, diceValue, player.color)) {
      continue;
    }
    final afterMove = advanceToken(token, diceValue, player.color);
    if (afterMove.isOnTrack) {
      for (final tPos in threateningPositions) {
        final dist =
            (toRelativePosition(tPos, player.color) -
                toRelativePosition(afterMove.trackPosition, player.color) +
                52) %
            52;
        if (dist <= 2) {
          return id;
        }
      }
    }
  }
  return -1;
}

/// Among the movable tokens, returns the one with the most progress.
int _advanceFurthest(LudoPlayer player, List<int> movable) {
  int bestId = movable.first;
  int bestProgress = -1;
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    final progress = _progressValue(token);
    if (progress > bestProgress) {
      bestProgress = progress;
      bestId = id;
    }
  }
  return bestId;
}

int _progressValue(LudoToken t) {
  if (t.isInBase) {
    return -1;
  }
  if (t.isInHomeColumn) {
    return 52 + t.homeColumnStep;
  }
  return t.trackPosition;
}
