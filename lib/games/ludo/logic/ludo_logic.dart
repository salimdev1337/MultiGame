import 'dart:math';

import '../models/ludo_enums.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_player.dart';
import '../models/ludo_token.dart';
import 'ludo_path.dart';

final _rng = Random();

// ── Dice ───────────────────────────────────────────────────────────────────

/// Returns a random dice value between 1 and 6 (inclusive).
int rollDice() => _rng.nextInt(6) + 1;

/// Picks a random powerup type.
LudoPowerupType randomPowerup() {
  final values = LudoPowerupType.values;
  return values[_rng.nextInt(values.length)];
}

/// Returns a random magic die face.
MagicDiceFace rollMagicDice() =>
    MagicDiceFace.values[_rng.nextInt(MagicDiceFace.values.length)];

/// Applies the magic effect to state and returns the updated state.
/// [skip] is a no-op here — the notifier handles turn advancement for skip.
LudoGameState applyMagicEffect(
  LudoGameState state,
  int normalDice,
  MagicDiceFace face,
) {
  switch (face) {
    case MagicDiceFace.turbo:
      return state.copyWith(diceValue: normalDice * 2);

    case MagicDiceFace.wildcard:
      return state.copyWith(diceValue: 6);

    case MagicDiceFace.shield:
      final pIdx = state.currentPlayerIndex;
      final updatedPlayers = state.players.asMap().entries.map((e) {
        if (e.key != pIdx) {
          return e.value;
        }
        final p = e.value;
        final tokens = p.tokens.map((t) {
          if (t.isOnTrack || t.isInHomeColumn) {
            return t.copyWith(shieldTurnsLeft: 2);
          }
          return t;
        }).toList();
        return p.copyWith(tokens: tokens);
      }).toList();
      return state.copyWith(players: updatedPlayers);

    case MagicDiceFace.swap:
      return state.copyWith(
        players: _applySwap(state.players, state.currentPlayerIndex),
      );

    case MagicDiceFace.blast:
      return state.copyWith(
        players: _applyBlast(state.players, state.currentPlayerIndex),
      );

    case MagicDiceFace.skip:
      return state;
  }
}

List<LudoPlayer> _applySwap(List<LudoPlayer> players, int currentIdx) {
  final current = players[currentIdx];

  LudoToken? ownBest;
  int ownBestRel = -1;
  for (final t in current.tokens) {
    if (!t.isOnTrack) {
      continue;
    }
    final rel = toRelativePosition(t.trackPosition, current.color);
    if (rel > ownBestRel) {
      ownBestRel = rel;
      ownBest = t;
    }
  }
  if (ownBest == null) {
    return players;
  }

  LudoToken? oppBest;
  int oppBestRel = -1;
  int oppBestIdx = -1;
  for (int i = 0; i < players.length; i++) {
    if (i == currentIdx) {
      continue;
    }
    final opp = players[i];
    for (final t in opp.tokens) {
      if (!t.isOnTrack) {
        continue;
      }
      final rel = toRelativePosition(t.trackPosition, opp.color);
      if (rel > oppBestRel) {
        oppBestRel = rel;
        oppBest = t;
        oppBestIdx = i;
      }
    }
  }
  if (oppBest == null || oppBestIdx == -1) {
    return players;
  }

  final ownPos = ownBest.trackPosition;
  final oppPos = oppBest.trackPosition;
  final capturedOwnBest = ownBest;
  final capturedOppBest = oppBest;

  final updatedPlayers = List<LudoPlayer>.from(players);
  updatedPlayers[currentIdx] = current.copyWith(
    tokens: current.tokens.map((t) {
      if (t.id == capturedOwnBest.id) {
        return t.copyWith(trackPosition: oppPos);
      }
      return t;
    }).toList(),
  );
  final opp = players[oppBestIdx];
  updatedPlayers[oppBestIdx] = opp.copyWith(
    tokens: opp.tokens.map((t) {
      if (t.id == capturedOppBest.id) {
        return t.copyWith(trackPosition: ownPos);
      }
      return t;
    }).toList(),
  );
  return updatedPlayers;
}

List<LudoPlayer> _applyBlast(List<LudoPlayer> players, int currentIdx) {
  LudoToken? target;
  int targetRel = -1;
  int targetPlayerIdx = -1;

  for (int i = 0; i < players.length; i++) {
    if (i == currentIdx) {
      continue;
    }
    final opp = players[i];
    for (final t in opp.tokens) {
      if (!t.isOnTrack) {
        continue;
      }
      final rel = toRelativePosition(t.trackPosition, opp.color);
      if (rel > targetRel) {
        targetRel = rel;
        target = t;
        targetPlayerIdx = i;
      }
    }
  }

  if (target == null || targetPlayerIdx == -1) {
    return players;
  }

  final opp = players[targetPlayerIdx];
  final capturedTarget = target;
  final LudoToken newToken;
  if (targetRel < 6) {
    newToken = LudoToken(id: capturedTarget.id, owner: capturedTarget.owner);
  } else {
    final newAbs = toAbsolutePosition(targetRel - 6, opp.color);
    newToken = capturedTarget.copyWith(trackPosition: newAbs);
  }

  final updatedPlayers = List<LudoPlayer>.from(players);
  updatedPlayers[targetPlayerIdx] = opp.copyWith(
    tokens: opp.tokens.map((t) {
      if (t.id == capturedTarget.id) {
        return newToken;
      }
      return t;
    }).toList(),
  );
  return updatedPlayers;
}

// ── Position helpers ───────────────────────────────────────────────────────

/// Converts an absolute track position to a player-relative position.
/// Relative position 0 = that player's start square.
int toRelativePosition(int abs, LudoPlayerColor color) {
  final start = kStartPositions[color]!;
  return (abs - start + 52) % 52;
}

/// Converts a player-relative position back to an absolute track position.
int toAbsolutePosition(int rel, LudoPlayerColor color) {
  final start = kStartPositions[color]!;
  return (rel + start) % 52;
}

// ── Movement validity ──────────────────────────────────────────────────────

/// A token in base needs a 6 to be launched.
bool canLaunch(LudoToken token, int diceValue) {
  if (!token.isInBase || token.isFinished) {
    return false;
  }
  return diceValue == 6;
}

/// Whether a token already on the track or in the home column can move.
/// Returns false if the token would overshoot the finish, or is frozen.
bool canMoveOnTrack(
  LudoToken token,
  int diceValue,
  List<LudoPlayer> players,
) {
  if (token.isInBase || token.isFinished) {
    return false;
  }
  if (token.isFrozen) {
    return false;
  }
  return !wouldOvershoot(token, diceValue, token.owner);
}

/// Returns true when advancing [steps] would push the token past the finish
/// line (i.e. past home-column step 6).
bool wouldOvershoot(LudoToken token, int steps, LudoPlayerColor color) {
  if (token.isInHomeColumn) {
    return token.homeColumnStep + steps > 6;
  }
  if (token.isOnTrack) {
    final rel = toRelativePosition(token.trackPosition, color);
    // Relative position 50 = last valid track square; rel 51 is forbidden.
    // From rel 50, 1 step crosses into home column step 1.
    final stepsToEntry = 51 - rel; // steps to cross into home col step 1
    if (steps < stepsToEntry) {
      return false; // stays on track — no overshoot possible
    }
    final stepsIntoColumn = steps - stepsToEntry;
    return stepsIntoColumn > 6;
  }
  return false;
}

/// True if the absolute track position is a safe square.
bool isTrackSafe(int absPos) => kSafeSquares.contains(absPos);

/// Computes the absolute track position where [token] lands after [steps].
/// Returns null when the token is already in or will enter the home column
/// (stacking is always allowed in the private home lane).
int? _destinationTrackPos(LudoToken token, int steps) {
  if (token.isInHomeColumn) {
    return null;
  }
  final rel = toRelativePosition(token.trackPosition, token.owner);
  final stepsToEntry = 51 - rel;
  if (steps >= stepsToEntry) {
    return null;
  }
  return toAbsolutePosition(rel + steps, token.owner);
}

// ── Token advancement ──────────────────────────────────────────────────────

/// Advances [token] by [steps] along the track/home-column, returning the
/// updated token.  Caller must ensure the move is valid (no overshoot).
LudoToken advanceToken(LudoToken token, int steps, LudoPlayerColor color) {
  assert(!token.isInBase, 'Cannot advance a base token');
  assert(!token.isFinished, 'Token already finished');
  assert(!wouldOvershoot(token, steps, color), 'Move would overshoot');

  if (token.isInHomeColumn) {
    final newStep = token.homeColumnStep + steps;
    if (newStep == 6) {
      return token.copyWith(isFinished: true, homeColumnStep: 6);
    }
    return token.copyWith(homeColumnStep: newStep);
  }

  // Token is on the main track.
  final rel = toRelativePosition(token.trackPosition, color);
  final stepsToEntry = 51 - rel;

  if (steps < stepsToEntry) {
    // Stays on track.
    final newAbs = toAbsolutePosition(rel + steps, color);
    return token.copyWith(trackPosition: newAbs);
  }

  // Enters the home column.
  final stepsIntoColumn = steps - stepsToEntry;
  if (stepsIntoColumn == 0) {
    // Lands exactly at step 1 of the home column.
    return token.copyWith(trackPosition: -2, homeColumnStep: 1);
  }
  if (stepsIntoColumn == 6) {
    return token.copyWith(
      trackPosition: -2,
      homeColumnStep: 6,
      isFinished: true,
    );
  }
  return token.copyWith(
    trackPosition: -2,
    homeColumnStep: stepsIntoColumn,
  );
}

// ── Capture ────────────────────────────────────────────────────────────────

/// Returns the list of opponent tokens at [trackPos] that can be captured.
/// Shielded tokens are immune unless [isRecallPowerup] is true.
/// Tokens on safe squares cannot be captured (unless recall).
List<LudoToken> captureTargets(
  int trackPos,
  LudoPlayerColor mover,
  List<LudoPlayer> all,
  bool isRecallPowerup,
) {
  final targets = <LudoToken>[];
  final isSafe = isTrackSafe(trackPos) && !isRecallPowerup;
  if (isSafe) {
    return targets;
  }
  for (final player in all) {
    if (player.color == mover) {
      continue;
    }
    for (final token in player.tokens) {
      if (!token.isOnTrack) {
        continue;
      }
      if (token.trackPosition != trackPos) {
        continue;
      }
      if (token.shieldTurnsLeft > 0 && !isRecallPowerup) {
        continue;
      }
      targets.add(token);
    }
  }
  return targets;
}

// ── Movable tokens ─────────────────────────────────────────────────────────

/// Returns the list of token IDs the current player can legally move.
List<int> computeMovableTokenIds(
  LudoPlayer player,
  int diceValue,
  List<LudoPlayer> all,
) {
  final ids = <int>[];
  for (final token in player.tokens) {
    if (token.isFinished) {
      continue;
    }
    if (token.isInBase) {
      if (canLaunch(token, diceValue)) {
        ids.add(token.id);
      }
      continue;
    }
    if (canMoveOnTrack(token, diceValue, all)) {
      final dest = _destinationTrackPos(token, diceValue);
      if (dest != null) {
        final blocked = player.tokens.any(
          (t) =>
              t.id != token.id &&
              !t.isFinished &&
              t.isOnTrack &&
              t.trackPosition == dest,
        );
        if (blocked) {
          continue;
        }
      }
      ids.add(token.id);
    }
  }
  return ids;
}

/// Returns the dice values (subset of 1–6) that satisfy both conditions:
///   1. At least one token has a legal move.
///   2. No on-track token that could physically move is blocked by same-color
///      stacking (i.e. every canMoveOnTrack token can reach a free square).
List<int> validDiceValues(LudoPlayer player, List<LudoPlayer> all) {
  final valid = <int>[];
  outer:
  for (int v = 1; v <= 6; v++) {
    if (computeMovableTokenIds(player, v, all).isEmpty) {
      continue;
    }
    // Reject v if any on-track token would be stacking-blocked.
    for (final token in player.tokens) {
      if (!canMoveOnTrack(token, v, all)) {
        continue;
      }
      final dest = _destinationTrackPos(token, v);
      if (dest == null) {
        continue;
      }
      final stacked = player.tokens.any(
        (t) =>
            t.id != token.id &&
            !t.isFinished &&
            t.isOnTrack &&
            t.trackPosition == dest,
      );
      if (stacked) {
        continue outer;
      }
    }
    valid.add(v);
  }
  return valid;
}

/// Picks a random value from [values]. [values] must be non-empty.
int rollDiceFrom(List<int> values) {
  assert(values.isNotEmpty, 'rollDiceFrom called with empty list');
  return values[_rng.nextInt(values.length)];
}

// ── Applying a move ────────────────────────────────────────────────────────

/// Applies the move for [tokenId] of the current player, returning the new
/// state.  Handles: launch, capture, powerup award, finish detection,
/// extra-turn logic, and turn advancement.
LudoGameState applyMove(LudoGameState state, int tokenId) {
  var players = List<LudoPlayer>.from(state.players);
  final pIdx = state.currentPlayerIndex;
  var player = players[pIdx];

  final tokenIdx = player.tokens.indexWhere((t) => t.id == tokenId);
  assert(tokenIdx != -1, 'Token $tokenId not found');

  var token = player.tokens[tokenIdx];
  var extraTurn = false;
  var powerupsEarned = List<LudoPowerupType>.from(player.powerups);

  // ── Apply dice ──────────────────────────────────────────────────────────
  final steps = state.diceValue;
  bool launched = false;

  if (token.isInBase) {
    // Launch: move to start position.
    final startPos = kStartPositions[player.color]!;
    token = token.copyWith(trackPosition: startPos, isFrozen: false);
    launched = true;
    extraTurn = true; // rolling 6 to launch grants extra turn
  } else {
    token = advanceToken(token, steps, player.color);
  }

  // ── Check for captures (only on main track) ────────────────────────────
  if (token.isOnTrack) {
    final targets = captureTargets(
      token.trackPosition,
      player.color,
      players,
      false,
    );
    if (targets.isNotEmpty) {
      extraTurn = true; // capture grants extra turn
      // Send captured tokens back to base.
      for (final target in targets) {
        final ownerIdx = players.indexWhere((p) => p.color == target.owner);
        if (ownerIdx == -1) {
          continue;
        }
        final ownerPlayer = players[ownerIdx];
        final updatedTokens = ownerPlayer.tokens.map((t) {
          if (t.id == target.id) {
            return LudoToken(id: t.id, owner: t.owner);
          }
          return t;
        }).toList();
        players[ownerIdx] = ownerPlayer.copyWith(tokens: updatedTokens);
      }
      // Award powerup for capture.
      if (powerupsEarned.length < 3) {
        powerupsEarned.add(randomPowerup());
      }
    }
  }

  // ── Check for finish powerup award ────────────────────────────────────
  if (token.isFinished) {
    if (powerupsEarned.length < 3) {
      powerupsEarned.add(randomPowerup());
    }
  }

  // ── Update the moved token in the player list ──────────────────────────
  final updatedTokens = player.tokens.map((t) {
    if (t.id == token.id) {
      return token;
    }
    return t;
  }).toList();

  // ── Check for finish position ────────────────────────────────────────
  var finishCount = state.finishCount;
  var finishPosition = player.finishPosition;
  final allFinished = updatedTokens.every((t) => t.isFinished);
  if (allFinished && player.finishPosition == 0) {
    finishCount++;
    finishPosition = finishCount;
  }

  // ── Extra turn for rolling 6 (dice, not launch) ───────────────────────
  if (!launched && steps == 6) {
    extraTurn = true;
  }

  // ── Three-consecutive-sixes rule ─────────────────────────────────────
  var consecutiveSixes = player.consecutiveSixes;
  if (steps == 6) {
    consecutiveSixes++;
  } else {
    consecutiveSixes = 0;
  }

  if (consecutiveSixes >= 3) {
    // Forfeit: send furthest-along token back to base.
    extraTurn = false;
    consecutiveSixes = 0;
    final furthest = _furthestToken(updatedTokens);
    if (furthest != null) {
      final resetTokens = updatedTokens.map((t) {
        if (t.id == furthest.id) {
          return LudoToken(id: t.id, owner: t.owner);
        }
        return t;
      }).toList();
      player = player.copyWith(
        tokens: resetTokens,
        consecutiveSixes: consecutiveSixes,
        powerups: powerupsEarned,
        finishPosition: finishPosition,
      );
    } else {
      player = player.copyWith(
        tokens: updatedTokens,
        consecutiveSixes: consecutiveSixes,
        powerups: powerupsEarned,
        finishPosition: finishPosition,
      );
    }
    players[pIdx] = player;
    return _advanceTurn(state, players, pIdx, finishCount, extraTurn: false);
  }

  player = player.copyWith(
    tokens: updatedTokens,
    consecutiveSixes: consecutiveSixes,
    powerups: powerupsEarned,
    finishPosition: finishPosition,
  );
  players[pIdx] = player;

  // ── Check overall win condition ────────────────────────────────────────
  final winner = checkWinner(state.copyWith(players: players));
  if (winner != null || checkTeamWinner(state.copyWith(players: players)) != null) {
    return state.copyWith(
      players: players,
      phase: LudoPhase.won,
      finishCount: finishCount,
      selectedTokenId: null,
    );
  }

  return _advanceTurn(
    state,
    players,
    pIdx,
    finishCount,
    extraTurn: extraTurn,
  );
}

/// Returns a new state with the turn advanced to the next active player,
/// or staying on the current player if [extraTurn] is true.
LudoGameState _advanceTurn(
  LudoGameState state,
  List<LudoPlayer> players,
  int currentIdx,
  int finishCount, {
  required bool extraTurn,
}) {
  int nextIdx;
  if (extraTurn) {
    nextIdx = currentIdx;
  } else {
    nextIdx = _nextActivePlayerIndex(players, currentIdx);
  }

  return state.copyWith(
    phase: LudoPhase.rolling,
    players: players,
    currentPlayerIndex: nextIdx,
    diceValue: 0,
    selectedTokenId: null,
    magicDiceFace: null,
    finishCount: finishCount,
  );
}

/// Returns the index of the next player who has not finished all tokens.
int _nextActivePlayerIndex(List<LudoPlayer> players, int currentIdx) {
  final n = players.length;
  for (int i = 1; i <= n; i++) {
    final idx = (currentIdx + i) % n;
    if (!players[idx].hasWon) {
      return idx;
    }
  }
  return (currentIdx + 1) % n;
}

/// Returns the furthest-advanced non-finished token, or null if all are in base.
LudoToken? _furthestToken(List<LudoToken> tokens) {
  LudoToken? best;
  int bestProgress = -1;
  for (final t in tokens) {
    if (t.isFinished) {
      continue;
    }
    final progress = _progressValue(t);
    if (progress > bestProgress) {
      bestProgress = progress;
      best = t;
    }
  }
  return best;
}

/// Comparable progress value for a token (higher = further along).
int _progressValue(LudoToken t) {
  if (t.isInBase) {
    return -1;
  }
  if (t.isInHomeColumn) {
    return 52 + t.homeColumnStep;
  }
  return t.trackPosition;
}

// ── Tick down effects ──────────────────────────────────────────────────────

/// Decrements shield and clears freeze on all players' tokens for the
/// current player's tokens after their turn.
LudoGameState tickDownEffects(LudoGameState state) {
  final pIdx = state.currentPlayerIndex;
  final players = state.players.asMap().entries.map((entry) {
    final i = entry.key;
    final player = entry.value;
    if (i != pIdx) {
      return player;
    }
    final updatedTokens = player.tokens.map((t) {
      var shield = t.shieldTurnsLeft;
      if (shield > 0) {
        shield--;
      }
      return t.copyWith(shieldTurnsLeft: shield, isFrozen: false);
    }).toList();
    return player.copyWith(tokens: updatedTokens);
  }).toList();
  return state.copyWith(players: players);
}

// ── Win conditions ────────────────────────────────────────────────────────

/// Returns the winning player colour (solo/FFA: first to finish all 4 tokens),
/// or null if no winner yet.
LudoPlayerColor? checkWinner(LudoGameState state) {
  for (final player in state.players) {
    if (player.hasWon) {
      return player.color;
    }
  }
  return null;
}

/// Returns the winning team index (0 or 1) for 2v2 mode, or null if ongoing.
int? checkTeamWinner(LudoGameState state) {
  if (state.mode != LudoMode.twoVsTwo) {
    return null;
  }
  for (final teamIdx in [0, 1]) {
    final teamPlayers = state.players.where((p) => p.teamIndex == teamIdx);
    if (teamPlayers.every((p) => p.hasWon)) {
      return teamIdx;
    }
  }
  return null;
}

// ── Token hop path (animation) ───────────────────────────────────────────

// The 4 outer-corner diagonal transitions on the 15×15 Ludo track plus the
// 4 diagonal steps when each player enters their home column.
// kTrackCoords jumps diagonally at outer corners and at home-col entries;
// these intermediate cells restore the missing visual step.
const _cornerWaypoints = <(int, int, int, int), (int, int)>{
  // Track outer corners — corner cells are coloured decorations, tokens skip them.
  // Home column entries (last track cell → home col step 1)
  (0, 6, 1, 7):   (0, 7),   // Red   home entry
  (8, 0, 7, 1):   (7, 0),   // Green home entry
  (14, 8, 13, 7): (14, 7),  // Yellow home entry
  (6, 14, 7, 13): (7, 14),  // Blue  home entry
};

/// Returns a list of (col, row) board coordinates stepped one square at a
/// time from [from]'s position toward [to]'s position for [color].
/// Used to drive the per-square hop animation. Returns empty on no movement.
List<(int col, int row)> computeTokenHopPath(
  LudoToken from,
  LudoToken to,
  LudoPlayerColor color,
) {
  if (from.isFinished || to.isInBase) {
    return [];
  }
  // Launch from base: single hop to the start position.
  if (from.isInBase && !to.isInBase) {
    return [tokenGridCoord(to, color)];
  }
  if (from.trackPosition == to.trackPosition &&
      from.homeColumnStep == to.homeColumnStep &&
      from.isFinished == to.isFinished) {
    return [];
  }
  final path = <(int col, int row)>[];
  var cur = from;
  var prevCoord = tokenGridCoord(from, color);
  for (int i = 0; i < 12; i++) {
    if (cur.trackPosition == to.trackPosition &&
        cur.homeColumnStep == to.homeColumnStep &&
        cur.isFinished == to.isFinished) {
      break;
    }
    if (wouldOvershoot(cur, 1, color)) {
      break;
    }
    cur = advanceToken(cur, 1, color);
    final nextCoord = tokenGridCoord(cur, color);
    // Insert a corner waypoint when the step crosses a board outer corner
    // (both col and row change = diagonal jump in kTrackCoords).
    final corner = _cornerWaypoints[
        (prevCoord.$1, prevCoord.$2, nextCoord.$1, nextCoord.$2)];
    if (corner != null) {
      path.add(corner);
    }
    path.add(nextCoord);
    prevCoord = nextCoord;
  }
  return path;
}

// ── Steps to finish ───────────────────────────────────────────────────────

/// Rough number of steps the token still needs to reach the centre.
/// Base = 58 (52 track + 6 home col), on track = remaining, in home col = remaining.
int stepsToFinish(LudoToken token) {
  if (token.isFinished) {
    return 0;
  }
  if (token.isInBase) {
    return 58; // 52 track steps + 6 home column steps
  }
  if (token.isInHomeColumn) {
    return 6 - token.homeColumnStep;
  }
  // On track: relative position tells how far they have gone.
  // They have 52 - rel track steps remaining, then 6 home column steps.
  // We don't have color here — use approximate distance.
  return 52 - token.trackPosition + 6;
}
