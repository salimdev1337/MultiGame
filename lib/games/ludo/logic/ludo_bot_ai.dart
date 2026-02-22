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

/// Picks the best wildcard value (1–6) for the bot.
///
/// - Hard: tries values in priority order (capture, launch, advance home col,
///   advance furthest). Returns the value yielding the best outcome.
/// - Easy/Medium: always pick 6 (or 5 if 6 is blocked by 3-sixes rule).
int botPickWildcardValue(
  LudoDifficulty difficulty,
  LudoPlayer player,
  List<LudoPlayer> all, {
  required bool canUse6,
}) {
  if (difficulty != LudoDifficulty.hard) {
    return canUse6 ? 6 : 5;
  }
  // Hard bot: evaluate each value and pick the one with the best outcome.
  final candidates = canUse6
      ? [6, 5, 4, 3, 2, 1]
      : [5, 4, 3, 2, 1];
  for (final v in candidates) {
    final movable = computeMovableTokenIds(player, v, all);
    if (movable.isEmpty) {
      continue;
    }
    // Prefer values that allow a capture.
    if (_findCapture(player, movable, v, all) != -1) {
      return v;
    }
  }
  // Prefer 6 for launch.
  if (canUse6) {
    final movable = computeMovableTokenIds(player, 6, all);
    if (movable.isNotEmpty) {
      for (final id in movable) {
        if (player.tokens.firstWhere((t) => t.id == id).isInBase) {
          return 6;
        }
      }
    }
  }
  // Otherwise pick the largest usable value.
  for (final v in candidates) {
    if (computeMovableTokenIds(player, v, all).isNotEmpty) {
      return v;
    }
  }
  return canUse6 ? 6 : 5;
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
///
/// In magic mode, the hard bot is also aware of the current magic face:
/// - After Anchor: prioritise spreading out tokens (launch new ones).
/// - After Ghost: advance the ghost-protected token aggressively.
/// - After Turbo: treat larger step as opportunity to capture / finish.
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

  // 5. Prefer advancing a ghost-protected token (already immune — safer).
  for (final id in movable) {
    final token = player.tokens.firstWhere((t) => t.id == id);
    if (token.ghostTurnsLeft > 0) {
      return id;
    }
  }

  // 6. Advance furthest token.
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
