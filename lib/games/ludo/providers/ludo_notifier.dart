import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

import '../logic/ludo_bot_ai.dart';
import '../logic/ludo_logic.dart' as logic;
import '../models/ludo_enums.dart';
import '../models/ludo_game_state.dart';

final ludoProvider = NotifierProvider.autoDispose<LudoNotifier, LudoGameState>(
  LudoNotifier.new,
);

class LudoNotifier extends GameStatsNotifier<LudoGameState> {
  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  LudoGameState build() {
    ref.onDispose(() {
      _botTimer?.cancel();
      _pendingMoveTimer?.cancel();
    });
    return const LudoGameState();
  }

  static const _kMoveDelayMs = 1000;

  Timer? _botTimer;
  Timer? _pendingMoveTimer;
  int _normalDice = 0;

  // ── Public API ─────────────────────────────────────────────────────────────

  void startSolo(
    LudoDifficulty difficulty, {
    LudoDiceMode diceMode = LudoDiceMode.classic,
  }) {
    _cancelBotTimer();
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: LudoMode.soloVsBots,
      difficulty: difficulty,
      diceMode: diceMode,
      players: LudoGameState.buildPlayers(
        mode: LudoMode.soloVsBots,
        difficulty: difficulty,
      ),
    );
    _maybeBotTurn();
  }

  void startFreeForAll({
    required int playerCount,
    LudoDiceMode diceMode = LudoDiceMode.classic,
  }) {
    _cancelBotTimer();
    final mode = playerCount == 3 ? LudoMode.freeForAll3 : LudoMode.freeForAll4;
    const excluded = LudoPlayerColor.yellow;
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: mode,
      diceMode: diceMode,
      players: LudoGameState.buildPlayers(
        mode: mode,
        excludedColor: mode == LudoMode.freeForAll3 ? excluded : null,
      ),
      excludedColor: mode == LudoMode.freeForAll3 ? excluded : null,
    );
  }

  void startTeamVsTeam({LudoDiceMode diceMode = LudoDiceMode.classic}) {
    _cancelBotTimer();
    state = LudoGameState(
      phase: LudoPhase.rolling,
      mode: LudoMode.twoVsTwo,
      diceMode: diceMode,
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
    state = logic.applyMove(state, tokenId, normalDice: _normalDice);
    _maybeBotTurn();
  }

  /// Human picks a dice value 1–6 when the Wildcard magic face is rolled.
  /// Excludes 6 if the player has already rolled 2 consecutive sixes.
  void selectWildcardValue(int value) {
    if (state.phase != LudoPhase.selectingWildcard) {
      return;
    }
    // Enforce 3-sixes prevention: block selecting 6 after 2 consecutive sixes.
    final player = state.currentPlayer;
    final effectiveValue = (player.consecutiveSixes >= 2 && value == 6) ? 5 : value;

    _normalDice = effectiveValue;
    state = state.copyWith(diceValue: effectiveValue, normalDiceValue: effectiveValue, phase: LudoPhase.rolling);

    final movable = logic.computeMovableTokenIds(player, effectiveValue, state.players);
    if (movable.isEmpty) {
      state = _tickBombs(state);
      state = state.copyWith(
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
      _maybeBotTurn();
      return;
    }
    if (movable.length == 1) {
      state = state.copyWith(phase: LudoPhase.selectingToken);
      final tokenToMove = movable.first;
      _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
        if (state.phase != LudoPhase.selectingToken) {
          return;
        }
        state = logic.applyMove(state, tokenToMove, normalDice: _normalDice);
        _maybeBotTurn();
      });
      return;
    }
    state = state.copyWith(phase: LudoPhase.selectingToken);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _executeRoll() {
    state = state.copyWith(turboOvershoot: false);
    final player = state.currentPlayer;

    if (state.diceMode == LudoDiceMode.classic) {
      var valid = logic.validDiceValues(player, state.players, mode: state.mode);
      // Prevent 3rd consecutive 6 in classic mode.
      if (player.consecutiveSixes >= 2) {
        valid = valid.where((v) => v != 6).toList();
      }
      if (valid.isEmpty) {
        state = _tickBombs(state);
        state = state.copyWith(
          phase: LudoPhase.rolling,
          currentPlayerIndex: _nextPlayerIndex(),
        );
        _maybeBotTurn();
        return;
      }
      final normalDice = logic.rollDiceFrom(valid);
      _normalDice = normalDice;
      state = state.copyWith(
        diceValue: normalDice,
        normalDiceValue: normalDice,
        diceRollerColor: player.color,
      );
      final movable =
          logic.computeMovableTokenIds(player, normalDice, state.players, mode: state.mode);
      if (movable.length == 1) {
        state = state.copyWith(phase: LudoPhase.selectingToken);
        final tokenToMove = movable.first;
        _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
          if (state.phase != LudoPhase.selectingToken) {
            return;
          }
          state = logic.applyMove(state, tokenToMove, normalDice: _normalDice);
          _maybeBotTurn();
        });
        return;
      }
      state = state.copyWith(phase: LudoPhase.selectingToken);
      return;
    }

    // Magic mode: use validDiceValues for the normal die (prevents dead rolls).
    var valid = logic.validDiceValues(player, state.players, mode: state.mode);
    // Prevent 3rd consecutive 6 in magic mode.
    if (player.consecutiveSixes >= 2) {
      valid = valid.where((v) => v != 6).toList();
    }
    if (valid.isEmpty) {
      state = _tickBombs(state);
      state = state.copyWith(
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
      _maybeBotTurn();
      return;
    }
    final skipMagic = state.skipMagicDiceOnNextRoll;
    if (skipMagic) {
      state = state.copyWith(skipMagicDiceOnNextRoll: false);
    }
    final normalDice = logic.rollDiceFrom(valid);
    _normalDice = normalDice;
    final magic = skipMagic ? null : logic.rollMagicDice();
    final effectiveDice = _applyMagicAndGetEffectiveDice(normalDice, magic);
    if (effectiveDice == null) {
      return;
    }
    final movable = logic.computeMovableTokenIds(
      player,
      effectiveDice,
      state.players,
      mode: state.mode,
      normalDice: _normalDice,
    );
    if (movable.isEmpty) {
      state = _tickBombs(state);
      state = state.copyWith(
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
        turboOvershoot: magic == MagicDiceFace.turbo,
      );
      _maybeBotTurn();
      return;
    }
    if (movable.length == 1) {
      state = state.copyWith(phase: LudoPhase.selectingToken);
      final tokenToMove = movable.first;
      _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
        if (state.phase != LudoPhase.selectingToken) {
          return;
        }
        state = logic.applyMove(state, tokenToMove, normalDice: _normalDice);
        _maybeBotTurn();
      });
      return;
    }
    state = state.copyWith(phase: LudoPhase.selectingToken);
  }

  /// Applies the magic effect (if any) and returns the effective dice value.
  /// Returns null if the turn was resolved (skip/wildcard routes elsewhere).
  int? _applyMagicAndGetEffectiveDice(int normalDice, MagicDiceFace? magic) {
    final rollerColor = state.currentPlayer.color;
    if (magic == null) {
      state = state.copyWith(diceValue: normalDice, normalDiceValue: normalDice, diceRollerColor: rollerColor);
      return normalDice;
    }

    if (magic == MagicDiceFace.skip) {
      state = _tickBombs(state);
      state = state.copyWith(
        diceValue: normalDice,
        normalDiceValue: normalDice,
        magicDiceFace: magic,
        diceRollerColor: rollerColor,
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
      _maybeBotTurn();
      return null;
    }

    if (magic == MagicDiceFace.wildcard) {
      state = state.copyWith(
        diceValue: normalDice,
        normalDiceValue: normalDice,
        magicDiceFace: magic,
        diceRollerColor: rollerColor,
        phase: LudoPhase.selectingWildcard,
      );
      // Bots resolve wildcard immediately.
      if (state.currentPlayer.isBot) {
        _botResolveWildcard(normalDice);
      }
      return null;
    }

    final effectiveDice = magic == MagicDiceFace.turbo ? normalDice * 2 : normalDice;
    state = state.copyWith(
      diceValue: effectiveDice,
      normalDiceValue: normalDice,
      magicDiceFace: magic,
      diceRollerColor: rollerColor,
    );
    return effectiveDice;
  }

  /// Bot immediately resolves the wildcard face by picking an optimal value.
  void _botResolveWildcard(int normalDice) {
    final player = state.currentPlayer;
    final canUse6 = player.consecutiveSixes < 2;
    final chosen = botPickWildcardValue(
      state.difficulty,
      player,
      state.players,
      canUse6: canUse6,
    );
    final movable = logic.computeMovableTokenIds(player, chosen, state.players, mode: state.mode);
    _normalDice = chosen;
    state = state.copyWith(diceValue: chosen, normalDiceValue: chosen, phase: LudoPhase.rolling);
    if (movable.isEmpty) {
      state = _tickBombs(state);
      state = state.copyWith(
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
      _maybeBotTurn();
      return;
    }
    state = state.copyWith(phase: LudoPhase.selectingToken);
    final tokenId = botDecide(state.difficulty, player, chosen, state.players);
    if (tokenId == -1) {
      state = state.copyWith(
        phase: LudoPhase.rolling,
        currentPlayerIndex: _nextPlayerIndex(),
      );
    } else {
      state = logic.applyMove(state, tokenId, normalDice: _normalDice);
    }
    _maybeSaveScore(state);
    _maybeBotTurn();
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

  /// Ticks down all active bombs by one turn and removes any that have expired.
  LudoGameState _tickBombs(LudoGameState s) {
    final ticked = s.activeBombs
        .map((b) => b.withTick())
        .where((b) => b.turnsLeft > 0)
        .toList();
    return s.copyWith(activeBombs: ticked);
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

      state = state.copyWith(turboOvershoot: false);
      final player = state.currentPlayer;

      if (state.diceMode == LudoDiceMode.classic) {
        var valid = logic.validDiceValues(player, state.players, mode: state.mode);
        if (player.consecutiveSixes >= 2) {
          valid = valid.where((v) => v != 6).toList();
        }
        if (valid.isEmpty) {
          state = _tickBombs(state);
          state = state.copyWith(
            phase: LudoPhase.rolling,
            currentPlayerIndex: _nextPlayerIndex(),
          );
          _maybeBotTurn();
          return;
        }
        final normalDice = logic.rollDiceFrom(valid);
        _normalDice = normalDice;
        state = state.copyWith(
          diceValue: normalDice,
          normalDiceValue: normalDice,
          diceRollerColor: player.color,
          phase: LudoPhase.selectingToken,
        );
        final tokenId =
            botDecide(state.difficulty, player, normalDice, state.players);
        _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
          if (state.phase != LudoPhase.selectingToken) {
            return;
          }
          if (!state.currentPlayer.isBot) {
            return;
          }
          if (tokenId == -1) {
            state = state.copyWith(
              phase: LudoPhase.rolling,
              currentPlayerIndex: _nextPlayerIndex(),
            );
          } else {
            state = logic.applyMove(state, tokenId, normalDice: _normalDice);
          }
          _maybeSaveScore(state);
          _maybeBotTurn();
        });
        return;
      }

      // Magic mode.
      var valid = logic.validDiceValues(player, state.players, mode: state.mode);
      if (player.consecutiveSixes >= 2) {
        valid = valid.where((v) => v != 6).toList();
      }
      if (valid.isEmpty) {
        state = _tickBombs(state);
        state = state.copyWith(
          phase: LudoPhase.rolling,
          currentPlayerIndex: _nextPlayerIndex(),
        );
        _maybeBotTurn();
        return;
      }
      final skipMagic = state.skipMagicDiceOnNextRoll;
      if (skipMagic) {
        state = state.copyWith(skipMagicDiceOnNextRoll: false);
      }
      final normalDice = logic.rollDiceFrom(valid);
      _normalDice = normalDice;
      final magic = skipMagic ? null : logic.rollMagicDice();
      final effectiveDice = _applyMagicAndGetEffectiveDice(normalDice, magic);
      if (effectiveDice == null) {
        return;
      }

      final movable = logic.computeMovableTokenIds(
        player,
        effectiveDice,
        state.players,
        mode: state.mode,
        normalDice: _normalDice,
      );
      if (movable.isEmpty) {
        _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
          state = _tickBombs(state);
          state = state.copyWith(
            phase: LudoPhase.rolling,
            currentPlayerIndex: _nextPlayerIndex(),
            turboOvershoot: magic == MagicDiceFace.turbo,
          );
          _maybeBotTurn();
        });
        return;
      }

      state = state.copyWith(phase: LudoPhase.selectingToken);

      final tokenId =
          botDecide(state.difficulty, player, effectiveDice, state.players);
      _pendingMoveTimer = Timer(const Duration(milliseconds: _kMoveDelayMs), () {
        if (state.phase != LudoPhase.selectingToken) {
          return;
        }
        if (!state.currentPlayer.isBot) {
          return;
        }
        if (tokenId == -1) {
          state = state.copyWith(
            phase: LudoPhase.rolling,
            currentPlayerIndex: _nextPlayerIndex(),
          );
        } else {
          state = logic.applyMove(state, tokenId, normalDice: _normalDice);
        }
        _maybeSaveScore(state);
        _maybeBotTurn();
      });
    });
  }

  void _cancelBotTimer() {
    _botTimer?.cancel();
    _botTimer = null;
    _pendingMoveTimer?.cancel();
    _pendingMoveTimer = null;
  }

  void _maybeSaveScore(LudoGameState s) {
    if (s.phase != LudoPhase.won) {
      return;
    }
    if (s.mode != LudoMode.soloVsBots) {
      return;
    }
    final red = s.playerByColor(LudoPlayerColor.red);
    if (red != null && red.hasWon) {
      saveScore('ludo', 1);
    }
  }
}
