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

/// Returns a random magic die face.
MagicDiceFace rollMagicDice() =>
    MagicDiceFace.values[_rng.nextInt(MagicDiceFace.values.length)];

// ── freeForAll3 portal constants ──────────────────────────────────────────
// In freeForAll3, position 26 (Yellow's start) is a portal:
//   • Red / Green tokens teleport to position 39 (Blue's start).
//   • Blue tokens enter their home column at step 1.
const int _kPortalFrom = 26;
const int _kPortalToRedGreen = 39;

// ── Magic effects ──────────────────────────────────────────────────────────

/// Applies the magic effect to state and returns the updated state.
///
/// - [ghost]    : no-op here — applied in [applyMove] to the moved token.
/// - [wildcard] : no-op here — notifier routes to selectingWildcard phase.
/// - [skip]     : no-op here — notifier handles turn advancement.
/// - [turbo]    : doubles diceValue.
/// - [bomb]     : no-op here — bomb is placed inside [applyMove] after the token moves.
LudoGameState applyMagicEffect(
  LudoGameState state,
  int normalDice,
  MagicDiceFace face,
) {
  switch (face) {
    case MagicDiceFace.turbo:
      return state.copyWith(diceValue: normalDice * 2);

    case MagicDiceFace.ghost:
    case MagicDiceFace.wildcard:
    case MagicDiceFace.skip:
    case MagicDiceFace.bomb:
      return state;
  }
}

// ── Bomb helpers ───────────────────────────────────────────────────────────

/// Decrements [turnsLeft] on every bomb and removes any that have expired.
List<LudoBomb> _tickBombs(List<LudoBomb> bombs) {
  return bombs
      .map((b) => b.withTick())
      .where((b) => b.turnsLeft > 0)
      .toList();
}

// ── Position helpers ───────────────────────────────────────────────────────

/// Converts an absolute track position to a player-relative position.
/// Relative position 0 = that player's start square.
int toRelativePosition(
  int abs,
  LudoPlayerColor color, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  final start = (startPos ?? kStartPositions)[color]!;
  return (abs - start + trackLength) % trackLength;
}

/// Converts a player-relative position back to an absolute track position.
int toAbsolutePosition(
  int rel,
  LudoPlayerColor color, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  final start = (startPos ?? kStartPositions)[color]!;
  return (rel + start) % trackLength;
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
  List<LudoPlayer> players, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  if (token.isInBase || token.isFinished) {
    return false;
  }
  return !wouldOvershoot(token, diceValue, token.owner, trackLength: trackLength, startPos: startPos);
}

/// Returns true when advancing [steps] would push the token past the finish
/// line (i.e. past home-column step 6).
bool wouldOvershoot(
  LudoToken token,
  int steps,
  LudoPlayerColor color, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  if (token.isInHomeColumn) {
    return token.homeColumnStep + steps > 6;
  }
  if (token.isOnTrack) {
    final rel = toRelativePosition(token.trackPosition, color, trackLength: trackLength, startPos: startPos);
    final stepsToEntry = (trackLength - 2) - rel;
    if (steps <= stepsToEntry) {
      return false; // stays on track — no overshoot possible
    }
    final stepsIntoColumn = steps - stepsToEntry;
    return stepsIntoColumn > 6;
  }
  return false;
}

/// True if the absolute track position is a safe square (standard 4-player board).
bool isTrackSafe(int absPos) => kSafeSquares.contains(absPos);

/// Computes the absolute track position where [token] lands after [steps].
/// Returns null when the token is already in or will enter the home column.
int? _destinationTrackPos(
  LudoToken token,
  int steps, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  if (token.isInHomeColumn) {
    return null;
  }
  final rel = toRelativePosition(token.trackPosition, token.owner, trackLength: trackLength, startPos: startPos);
  final stepsToEntry = (trackLength - 2) - rel;
  if (steps > stepsToEntry) {
    return null;
  }
  return toAbsolutePosition(rel + steps, token.owner, trackLength: trackLength, startPos: startPos);
}

// ── Token advancement ──────────────────────────────────────────────────────

/// Advances [token] by [steps] along the track/home-column, returning the
/// updated token.  Caller must ensure the move is valid (no overshoot).
LudoToken advanceToken(
  LudoToken token,
  int steps,
  LudoPlayerColor color, {
  int trackLength = 52,
  Map<LudoPlayerColor, int>? startPos,
}) {
  assert(!token.isInBase, 'Cannot advance a base token');
  assert(!token.isFinished, 'Token already finished');
  assert(
    !wouldOvershoot(token, steps, color, trackLength: trackLength, startPos: startPos),
    'Move would overshoot',
  );

  if (token.isInHomeColumn) {
    final newStep = token.homeColumnStep + steps;
    if (newStep == 6) {
      return token.copyWith(isFinished: true, homeColumnStep: 6);
    }
    return token.copyWith(homeColumnStep: newStep);
  }

  // Token is on the main track.
  final rel = toRelativePosition(token.trackPosition, color, trackLength: trackLength, startPos: startPos);
  final stepsToEntry = (trackLength - 2) - rel;

  if (steps <= stepsToEntry) {
    // Stays on track; relative 50 is the last valid resting square.
    final newAbs = toAbsolutePosition(rel + steps, color, trackLength: trackLength, startPos: startPos);
    return token.copyWith(trackPosition: newAbs);
  }

  // Enters the home column; stepsIntoColumn is always >= 1 here.
  final stepsIntoColumn = steps - stepsToEntry;
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
/// Ghost tokens (ghostTurnsLeft > 0) are immune.
/// Tokens on safe squares cannot be captured.
List<LudoToken> captureTargets(
  int trackPos,
  LudoPlayerColor mover,
  List<LudoPlayer> all,
  bool isRecallPowerup, {
  Set<int>? safeSquares,
}) {
  final targets = <LudoToken>[];
  final safeSq = safeSquares ?? kSafeSquares;
  final isSafe = safeSq.contains(trackPos) && !isRecallPowerup;
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
      if (token.ghostTurnsLeft > 0) {
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
  List<LudoPlayer> all, {
  LudoMode mode = LudoMode.soloVsBots,
  int? normalDice,
}) {
  final ids = <int>[];
  for (final token in player.tokens) {
    if (token.isFinished) {
      continue;
    }
    if (token.isInBase) {
      if (canLaunch(token, normalDice ?? diceValue)) {
        ids.add(token.id);
      }
      continue;
    }
    if (mode == LudoMode.freeForAll3) {
      if (_wouldOvershootFfa3(token, diceValue, player.color)) {
        continue;
      }
      final dest = _destinationFfa3(token, diceValue, player.color);
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
    } else {
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
  }
  return ids;
}

/// Returns the dice values (subset of 1–6) that satisfy both conditions:
///   1. At least one token has a legal move.
///   2. No on-track token that could physically move is blocked by same-color
///      stacking (i.e. every canMoveOnTrack token can reach a free square).
List<int> validDiceValues(
  LudoPlayer player,
  List<LudoPlayer> all, {
  LudoMode mode = LudoMode.soloVsBots,
}) {
  final valid = <int>[];
  outer:
  for (int v = 1; v <= 6; v++) {
    if (computeMovableTokenIds(player, v, all, mode: mode).isEmpty) {
      continue;
    }
    if (mode == LudoMode.freeForAll3) {
      for (final token in player.tokens) {
        if (token.isInBase || token.isFinished) {
          continue;
        }
        if (_wouldOvershootFfa3(token, v, player.color)) {
          continue;
        }
        final dest = _destinationFfa3(token, v, player.color);
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
    } else {
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

// ── freeForAll3 portal helpers ────────────────────────────────────────────

/// Advances [token] by [steps] applying the freeForAll3 portal at position 26.
///
/// - Red / Green: landing on or crossing abs 26 teleports to abs 39 (Blue's
///   start); remaining steps continue from there on the standard track.
/// - Blue: landing on or crossing abs 26 enters the home column at step 1;
///   remaining steps continue through the home column.
LudoToken _advanceWithFfa3Portal(
  LudoToken token,
  int steps,
  LudoPlayerColor color,
) {
  var cur = token;
  for (int i = 0; i < steps; i++) {
    if (cur.isInHomeColumn) {
      final newStep = cur.homeColumnStep + 1;
      if (newStep >= 6) {
        return cur.copyWith(isFinished: true, homeColumnStep: 6);
      }
      cur = cur.copyWith(homeColumnStep: newStep);
      continue;
    }
    final nextAbs = (cur.trackPosition + 1) % 52;
    if (nextAbs == _kPortalFrom) {
      if (color == LudoPlayerColor.blue) {
        cur = cur.copyWith(trackPosition: -2, homeColumnStep: 1);
      } else {
        cur = cur.copyWith(trackPosition: _kPortalToRedGreen);
      }
      continue;
    }
    // Red / Green standard home-column entry at relative step 51.
    if (color != LudoPlayerColor.blue) {
      final rel = toRelativePosition(cur.trackPosition, color);
      if (rel == 51) {
        cur = cur.copyWith(trackPosition: -2, homeColumnStep: 1);
        continue;
      }
    }
    cur = cur.copyWith(trackPosition: nextAbs);
  }
  return cur;
}

/// Whether advancing [steps] from [token] would overshoot home column in
/// freeForAll3 mode (i.e. the token would need to go past step 6).
bool _wouldOvershootFfa3(LudoToken token, int steps, LudoPlayerColor color) {
  if (token.isInBase || token.isFinished) {
    return false;
  }
  if (token.isInHomeColumn) {
    return token.homeColumnStep + steps > 6;
  }
  // Simulate to detect overshoot.
  var cur = token;
  for (int i = 0; i < steps; i++) {
    if (cur.isInHomeColumn) {
      return cur.homeColumnStep + (steps - i) > 6;
    }
    cur = _advanceWithFfa3Portal(cur, 1, color);
  }
  return false;
}

/// Returns the destination absolute track position after [steps] in freeForAll3
/// mode, or null if the token enters the home column.
int? _destinationFfa3(LudoToken token, int steps, LudoPlayerColor color) {
  final result = _advanceWithFfa3Portal(token, steps, color);
  if (result.isInHomeColumn || result.isFinished) {
    return null;
  }
  return result.trackPosition;
}

/// Hop path for freeForAll3 — standard board coordinates, portal jump included.
List<(double, double)> _computeTokenHopPathFfa3(
  LudoToken from,
  LudoToken to,
  LudoPlayerColor color,
) {
  if (from.isInBase && !to.isInBase) {
    final c = tokenGridCoord(to, color);
    return [(c.$1.toDouble(), c.$2.toDouble())];
  }
  if (from.trackPosition == to.trackPosition &&
      from.homeColumnStep == to.homeColumnStep &&
      from.isFinished == to.isFinished) {
    return [];
  }
  final path = <(double, double)>[];
  var cur = from;
  var prevCoord = tokenGridCoord(from, color);
  for (int i = 0; i < 14; i++) {
    if (cur.trackPosition == to.trackPosition &&
        cur.homeColumnStep == to.homeColumnStep &&
        cur.isFinished == to.isFinished) {
      break;
    }
    if (_wouldOvershootFfa3(cur, 1, color)) {
      break;
    }
    cur = _advanceWithFfa3Portal(cur, 1, color);
    final nextCoord = tokenGridCoord(cur, color);
    final corner = _cornerWaypoints[
        (prevCoord.$1, prevCoord.$2, nextCoord.$1, nextCoord.$2)];
    if (corner != null) {
      path.add((corner.$1.toDouble(), corner.$2.toDouble()));
    }
    path.add((nextCoord.$1.toDouble(), nextCoord.$2.toDouble()));
    prevCoord = nextCoord;
  }
  return path;
}

// ── Applying a move ────────────────────────────────────────────────────────

/// Applies the move for [tokenId] of the current player, returning the new
/// state.  Handles: launch, capture, ghost application, finish detection,
/// extra-turn logic, and turn advancement.
LudoGameState applyMove(LudoGameState state, int tokenId, {int? normalDice}) {
  var players = List<LudoPlayer>.from(state.players);
  final pIdx = state.currentPlayerIndex;
  var player = players[pIdx];

  final tokenIdx = player.tokens.indexWhere((t) => t.id == tokenId);
  assert(tokenIdx != -1, 'Token $tokenId not found');

  var token = player.tokens[tokenIdx];
  var extraTurn = false;

  // ── Apply dice ──────────────────────────────────────────────────────────
  final steps = state.diceValue;
  bool launched = false;

  const safeSquares = kSafeSquares;

  // Save position before the move so we can place a bomb there afterwards.
  final oldTrackPos = token.trackPosition;

  if (token.isInBase) {
    // Launch: move to start position.
    final startPos = kStartPositions[player.color]!;
    token = token.copyWith(trackPosition: startPos);
    launched = true;
    extraTurn = true; // rolling 6 to launch grants extra turn
  } else if (state.mode == LudoMode.freeForAll3) {
    token = _advanceWithFfa3Portal(token, steps, player.color);
  } else {
    token = advanceToken(token, steps, player.color);
  }

  // ── Apply ghost face: moved token gets immunity for 3 opponent turns ────
  // Initial = 4: tick 1 fires at end of the ghost player's own turn,
  // leaving 3 ticks for subsequent players to exhaust.
  if (state.magicDiceFace == MagicDiceFace.ghost && !token.isFinished) {
    token = token.copyWith(ghostTurnsLeft: 4);
  }

  // ── Check if token landed on a bomb ────────────────────────────────────
  var newActiveBombs = List<LudoBomb>.from(state.activeBombs);
  var killedByBomb = false;
  if (token.isOnTrack) {
    final bombIdx = newActiveBombs.indexWhere(
      (b) => b.trackPosition == token.trackPosition,
    );
    if (bombIdx != -1) {
      final bomb = newActiveBombs[bombIdx];
      if (bomb.placedBy == player.color) {
        // Own bomb: defuse silently — token survives.
        newActiveBombs.removeAt(bombIdx);
      } else if (token.ghostTurnsLeft > 0) {
        // Ghost token: defuse enemy bomb — token survives.
        newActiveBombs.removeAt(bombIdx);
      } else {
        // Enemy bomb: kills the token.
        newActiveBombs.removeAt(bombIdx);
        token = LudoToken(id: token.id, owner: token.owner); // reset to base
        killedByBomb = true;
      }
    }
  }

  // ── Check for captures (only on main track, only if not killed by bomb) ─
  if (!killedByBomb && token.isOnTrack) {
    final targets = captureTargets(
      token.trackPosition,
      player.color,
      players,
      false,
      safeSquares: safeSquares,
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
    }
  }

  // ── Check for finish (only if not killed by bomb) ──────────────────────
  if (!killedByBomb && token.isFinished) {
    extraTurn = true; // reaching the finish grants an extra turn
  }

  // ── Place bomb at departed square if bomb face was rolled ───────────────
  // Conditions: bomb face, token was on track (not launched), not killed by own bomb.
  if (state.magicDiceFace == MagicDiceFace.bomb &&
      !launched &&
      oldTrackPos >= 0 &&
      !killedByBomb) {
    if (!safeSquares.contains(oldTrackPos)) {
      newActiveBombs.add(LudoBomb(
        trackPosition: oldTrackPos,
        placedBy: player.color,
        turnsLeft: state.players.length * 3,
      ));
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
  // Use normalDice when provided so Turbo (which doubles diceValue) doesn't
  // suppress the extra turn the player earned by physically rolling a 6.
  if (!launched && (normalDice ?? steps) == 6) {
    extraTurn = true;
  }

  // ── Track consecutive sixes ────────────────────────────────────────────
  // Use normalDice so turbo (which doubles steps) doesn't hide a physical 6.
  var consecutiveSixes = player.consecutiveSixes;
  if ((normalDice ?? steps) == 6) {
    consecutiveSixes++;
  } else {
    consecutiveSixes = 0;
  }

  player = player.copyWith(
    tokens: updatedTokens,
    consecutiveSixes: consecutiveSixes,
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
      activeBombs: newActiveBombs,
    );
  }

  final normalDiceWasSix = (normalDice ?? steps) == 6;

  return _advanceTurn(
    state.copyWith(activeBombs: newActiveBombs),
    players,
    pIdx,
    finishCount,
    extraTurn: extraTurn,
    fromSix: normalDiceWasSix,
  );
}

/// Returns a new state with the turn advanced to the next active player,
/// or staying on the current player if [extraTurn] is true.
/// Ticks ghostTurnsLeft for ALL players once per turn advance.
LudoGameState _advanceTurn(
  LudoGameState state,
  List<LudoPlayer> players,
  int currentIdx,
  int finishCount, {
  required bool extraTurn,
  bool fromSix = false,
}) {
  // Tick down ghost immunity across ALL players after every turn advance.
  // ghostTurnsLeft counts total player-turns (any player), not just the owner's.
  final tickedPlayers = players.map((p) {
    final tokens = p.tokens.map((t) {
      if (t.ghostTurnsLeft > 0) {
        return t.copyWith(ghostTurnsLeft: t.ghostTurnsLeft - 1);
      }
      return t;
    }).toList();
    return p.copyWith(tokens: tokens);
  }).toList();

  int nextIdx;
  if (extraTurn) {
    nextIdx = currentIdx;
  } else {
    nextIdx = _nextActivePlayerIndex(tickedPlayers, currentIdx);
  }

  final tickedBombs = _tickBombs(state.activeBombs);

  return state.copyWith(
    phase: LudoPhase.rolling,
    players: tickedPlayers,
    currentPlayerIndex: nextIdx,
    diceValue: 0,
    normalDiceValue: 0,
    selectedTokenId: null,
    magicDiceFace: null,
    finishCount: finishCount,
    activeBombs: tickedBombs,
    skipMagicDiceOnNextRoll: extraTurn && fromSix,
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
List<(double col, double row)> computeTokenHopPath(
  LudoToken from,
  LudoToken to,
  LudoPlayerColor color, {
  LudoMode mode = LudoMode.soloVsBots,
}) {
  if (from.isFinished || to.isInBase) {
    return [];
  }

  if (mode == LudoMode.freeForAll3) {
    return _computeTokenHopPathFfa3(from, to, color);
  }

  // Square board path.
  if (from.isInBase && !to.isInBase) {
    final c = tokenGridCoord(to, color);
    return [(c.$1.toDouble(), c.$2.toDouble())];
  }
  if (from.trackPosition == to.trackPosition &&
      from.homeColumnStep == to.homeColumnStep &&
      from.isFinished == to.isFinished) {
    return [];
  }
  final path = <(double, double)>[];
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
    // Insert a corner waypoint when the step crosses a board outer corner.
    final corner = _cornerWaypoints[
        (prevCoord.$1, prevCoord.$2, nextCoord.$1, nextCoord.$2)];
    if (corner != null) {
      path.add((corner.$1.toDouble(), corner.$2.toDouble()));
    }
    path.add((nextCoord.$1.toDouble(), nextCoord.$2.toDouble()));
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
