import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

import '../logic/ludo_bot_ai.dart';
import '../logic/ludo_logic.dart' as logic;
import '../models/ludo_enums.dart';
import '../models/ludo_game_state.dart';
import '../models/ludo_token.dart';

final ludoProvider = NotifierProvider.autoDispose<LudoNotifier, LudoGameState>(
  LudoNotifier.new,
);

class LudoNotifier extends GameStatsNotifier<LudoGameState> {
  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  LudoGameState build() {
    ref.onDispose(_cancelBotTimer);
    return const LudoGameState();
  }

  Timer? _botTimer;

  // ── Public API ─────────────────────────────────────────────────────────────

  void startSolo(LudoDifficulty difficulty) {
    _cancelBotTimer();
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: LudoMode.soloVsBots,
      difficulty: difficulty,
      players: LudoGameState.buildPlayers(
        mode: LudoMode.soloVsBots,
        difficulty: difficulty,
      ),
    );
    _maybeBotTurn();
  }

  void startFreeForAll({required int playerCount}) {
    _cancelBotTimer();
    final mode = playerCount == 3 ? LudoMode.freeForAll3 : LudoMode.freeForAll4;
    // For 3-player FFA exclude Yellow by default.
    const excluded = LudoPlayerColor.yellow;
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: mode,
      players: LudoGameState.buildPlayers(
        mode: mode,
        excludedColor: mode == LudoMode.freeForAll3 ? excluded : null,
      ),
      excludedColor: mode == LudoMode.freeForAll3 ? excluded : null,
    );
  }

  void startTeamVsTeam() {
    _cancelBotTimer();
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: LudoMode.twoVsTwo,
      players: LudoGameState.buildPlayers(mode: LudoMode.twoVsTwo),
    );
  }

  void goToIdle() {
    _cancelBotTimer();
    state = const LudoGameState();
  }

  /// Human presses the dice button.
  void rollDice() {
    if (state.phase != LudoPhase.rolling) {
      return;
    }
    if (state.currentPlayer.isBot) {
      return;
    }
    _executeRoll();
  }

  /// Human selects which token to move.
  void selectToken(int tokenId) {
    if (state.phase != LudoPhase.selectingToken) {
      return;
    }
    state = logic.applyMove(state, tokenId);
    _maybeBotTurn();
  }

  /// Activates a powerup from the current player's tray.
  void activatePowerup(LudoPowerupType type) {
    if (state.phase != LudoPhase.selectingToken &&
        state.phase != LudoPhase.rolling) {
      return;
    }
    final player = state.currentPlayer;
    if (!player.powerups.contains(type)) {
      return;
    }
    // Consume the powerup from inventory.
    final remaining = List<LudoPowerupType>.from(player.powerups)..remove(type);
    final updatedPlayers = state.players.map((p) {
      if (p.color == player.color) {
        return p.copyWith(powerups: remaining);
      }
      return p;
    }).toList();

    switch (type) {
      case LudoPowerupType.shield:
        // Apply shield to all own tokens that are on track.
        final shieldedPlayers = updatedPlayers.map((p) {
          if (p.color != player.color) {
            return p;
          }
          final tokens = p.tokens.map((t) {
            if (t.isOnTrack || t.isInHomeColumn) {
              return t.copyWith(shieldTurnsLeft: 2);
            }
            return t;
          }).toList();
          return p.copyWith(tokens: tokens);
        }).toList();
        state = state.copyWith(players: shieldedPlayers);

      case LudoPowerupType.doubleStep:
        // Double dice — mark pending.
        state = state.copyWith(players: updatedPlayers, pendingPowerup: type);

      case LudoPowerupType.freeze:
        // Requires target selection.
        state = state.copyWith(
          players: updatedPlayers,
          phase: LudoPhase.selectingPowerupTarget,
          pendingPowerup: type,
        );

      case LudoPowerupType.recall:
        // Requires target selection.
        state = state.copyWith(
          players: updatedPlayers,
          phase: LudoPhase.selectingPowerupTarget,
          pendingPowerup: type,
        );

      case LudoPowerupType.luckyRoll:
        // Re-roll + add to current dice.
        final bonus = logic.rollDice();
        final newDice = (state.diceValue + bonus).clamp(1, 6);
        state = state.copyWith(players: updatedPlayers, diceValue: newDice);
    }
  }

  /// Selects a target for a freeze or recall powerup.
  void selectPowerupTarget(LudoPlayerColor targetColor, int targetTokenId) {
    if (state.phase != LudoPhase.selectingPowerupTarget) {
      return;
    }
    final pending = state.pendingPowerup;
    if (pending == null) {
      return;
    }

    final updatedPlayers = state.players.map((p) {
      if (p.color != targetColor) {
        return p;
      }
      final tokens = p.tokens.map((t) {
        if (t.id != targetTokenId) {
          return t;
        }
        switch (pending) {
          case LudoPowerupType.freeze:
            return t.copyWith(isFrozen: true);
          case LudoPowerupType.recall:
            // Send token back to base (bypass safe squares).
            return LudoToken(id: t.id, owner: t.owner);
          default:
            return t;
        }
      }).toList();
      return p.copyWith(tokens: tokens);
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      phase: LudoPhase.selectingToken,
      pendingPowerup: null,
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// Rolls the dice and transitions to [LudoPhase.selectingToken] if there
  /// are movable tokens, otherwise skips the turn.
  void _executeRoll() {
    final dice = logic.rollDice();
    final player = state.currentPlayer;
    final movable = logic.computeMovableTokenIds(player, dice, state.players);

    if (movable.isEmpty) {
      // No valid moves — advance to next player.
      state = state.copyWith(
        diceValue: dice,
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
      _maybeBotTurn();
      return;
    }

    if (movable.length == 1) {
      // Auto-select the only valid token.
      state = state.copyWith(diceValue: dice, phase: LudoPhase.selectingToken);
      state = logic.applyMove(state, movable.first);
      _maybeBotTurn();
      return;
    }

    state = state.copyWith(diceValue: dice, phase: LudoPhase.selectingToken);
  }

  int _nextPlayerIndex() {
    final n = state.players.length;
    final cur = state.currentPlayerIndex;
    for (int i = 1; i <= n; i++) {
      final idx = (cur + i) % n;
      if (!state.players[idx].hasWon) {
        return idx;
      }
    }
    return (cur + 1) % n;
  }

  void _maybeBotTurn() {
    if (state.phase == LudoPhase.rolling && state.currentPlayer.isBot) {
      _botTurn();
    }
  }

  void _botTurn() {
    _cancelBotTimer();
    _botTimer = Timer(const Duration(milliseconds: 600), () {
      if (state.phase != LudoPhase.rolling) {
        return;
      }
      if (!state.currentPlayer.isBot) {
        return;
      }

      final dice = logic.rollDice();
      final player = state.currentPlayer;
      final movable = logic.computeMovableTokenIds(player, dice, state.players);

      if (movable.isEmpty) {
        state = state.copyWith(
          diceValue: dice,
          phase: LudoPhase.rolling,
          currentPlayerIndex: _nextPlayerIndex(),
        );
        _maybeBotTurn();
        return;
      }

      state = state.copyWith(diceValue: dice, phase: LudoPhase.selectingToken);

      final tokenId = botDecide(state.difficulty, player, dice, state.players);
      if (tokenId == -1) {
        state = state.copyWith(
          phase: LudoPhase.rolling,
          currentPlayerIndex: _nextPlayerIndex(),
        );
      } else {
        state = logic.applyMove(state, tokenId);
      }

      _maybeSaveScore(state);
      _maybeBotTurn();
    });
  }

  void _cancelBotTimer() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  void _maybeSaveScore(LudoGameState s) {
    if (s.phase != LudoPhase.won) {
      return;
    }
    if (s.mode != LudoMode.soloVsBots) {
      return;
    }
    // Only save when the human (Red) wins.
    final red = s.playerByColor(LudoPlayerColor.red);
    if (red != null && red.hasWon) {
      saveScore('ludo', 1);
    }
  }
}
