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
    // Relative position 51 = last track square before home column.
    // Steps to enter home column = 52 - rel; each step in home column adds 1.
    final stepsToEntry = 51 - rel + 1; // steps to cross into home col step 1
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
  final stepsToEntry = 51 - rel + 1;

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
      ids.add(token.id);
    }
  }
  return ids;
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
