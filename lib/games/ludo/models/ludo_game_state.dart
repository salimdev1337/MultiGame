import 'package:flutter/foundation.dart';

import 'ludo_enums.dart';
import 'ludo_player.dart';

/// Immutable top-level game state for Ludo.
@immutable
class LudoGameState {
  const LudoGameState({
    this.phase = LudoPhase.idle,
    this.mode = LudoMode.soloVsBots,
    this.difficulty = LudoDifficulty.medium,
    this.players = const [],
    this.currentPlayerIndex = 0,
    this.diceValue = 0,
    this.selectedTokenId,
    this.pendingPowerup,
    this.excludedColor,
    this.finishCount = 0,
  });

  final LudoPhase phase;
  final LudoMode mode;
  final LudoDifficulty difficulty;

  /// Active player list (3 or 4 entries depending on mode).
  final List<LudoPlayer> players;

  /// Index into [players] for the player whose turn it is.
  final int currentPlayerIndex;

  /// Last dice roll result.  0 = not yet rolled this turn.
  final int diceValue;

  /// Token id currently selected by the human player (null = none).
  final int? selectedTokenId;

  /// Non-null while in [LudoPhase.selectingPowerupTarget] phase.
  final LudoPowerupType? pendingPowerup;

  /// In Free-for-All 3-player mode one colour is excluded.  Null otherwise.
  final LudoPlayerColor? excludedColor;

  /// Number of players who have finished all 4 tokens.
  final int finishCount;

  // ── Helpers ────────────────────────────────────────────────────────────────

  LudoPlayer get currentPlayer {
    assert(players.isNotEmpty, 'LudoGameState.players must not be empty');
    return players[currentPlayerIndex];
  }

  LudoPlayer? playerByColor(LudoPlayerColor c) {
    for (final p in players) {
      if (p.color == c) {
        return p;
      }
    }
    return null;
  }

  // ── Player builders ────────────────────────────────────────────────────────

  /// Builds the [players] list according to [mode] / [difficulty] / [excludedColor].
  static List<LudoPlayer> buildPlayers({
    required LudoMode mode,
    LudoDifficulty difficulty = LudoDifficulty.medium,
    LudoPlayerColor? excludedColor,
  }) {
    switch (mode) {
      case LudoMode.soloVsBots:
        return [
          LudoPlayer.initial(
            color: LudoPlayerColor.red,
            name: 'You',
            isBot: false,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.blue,
            name: 'Bot 1',
            isBot: true,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.green,
            name: 'Bot 2',
            isBot: true,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.yellow,
            name: 'Bot 3',
            isBot: true,
          ),
        ];

      case LudoMode.freeForAll3:
        final allColors = LudoPlayerColor.values;
        final colors = allColors
            .where((c) => c != excludedColor)
            .take(3)
            .toList();
        return [
          for (int i = 0; i < colors.length; i++)
            LudoPlayer.initial(
              color: colors[i],
              name: _colorName(colors[i]),
              isBot: false,
            ),
        ];

      case LudoMode.freeForAll4:
        return [
          for (final c in LudoPlayerColor.values)
            LudoPlayer.initial(color: c, name: _colorName(c), isBot: false),
        ];

      case LudoMode.twoVsTwo:
        // Red+Green = team 0, Blue+Yellow = team 1
        return [
          LudoPlayer.initial(
            color: LudoPlayerColor.red,
            name: 'Red',
            isBot: false,
            teamIndex: 0,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.blue,
            name: 'Blue',
            isBot: false,
            teamIndex: 1,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.green,
            name: 'Green',
            isBot: false,
            teamIndex: 0,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.yellow,
            name: 'Yellow',
            isBot: false,
            teamIndex: 1,
          ),
        ];
    }
  }

  static String _colorName(LudoPlayerColor c) {
    switch (c) {
      case LudoPlayerColor.red:
        return 'Red';
      case LudoPlayerColor.blue:
        return 'Blue';
      case LudoPlayerColor.green:
        return 'Green';
      case LudoPlayerColor.yellow:
        return 'Yellow';
    }
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  // Sentinel to allow explicitly setting nullable fields to null.
  static const _unset = Object();

  LudoGameState copyWith({
    LudoPhase? phase,
    LudoMode? mode,
    LudoDifficulty? difficulty,
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    int? diceValue,
    Object? selectedTokenId = _unset,
    Object? pendingPowerup = _unset,
    Object? excludedColor = _unset,
    int? finishCount,
  }) {
    return LudoGameState(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: diceValue ?? this.diceValue,
      selectedTokenId: selectedTokenId == _unset
          ? this.selectedTokenId
          : selectedTokenId as int?,
      pendingPowerup: pendingPowerup == _unset
          ? this.pendingPowerup
          : pendingPowerup as LudoPowerupType?,
      excludedColor: excludedColor == _unset
          ? this.excludedColor
          : excludedColor as LudoPlayerColor?,
      finishCount: finishCount ?? this.finishCount,
    );
  }
}
