import 'package:flutter/foundation.dart';

import 'ludo_enums.dart';
import 'ludo_player.dart';

// ── Bomb model ──────────────────────────────────────────────────────────────

/// An active bomb left on the track by the bomb magic face.
@immutable
class LudoBomb {
  const LudoBomb({
    required this.trackPosition,
    required this.placedBy,
    required this.turnsLeft,
  });

  /// Absolute track position (0–51 standard, 0–47 triangular).
  final int trackPosition;

  /// Which player placed the bomb — used for UI colour only.
  final LudoPlayerColor placedBy;

  /// Decrements once per player-turn; bomb is removed when it reaches 0.
  final int turnsLeft;

  LudoBomb withTick() => LudoBomb(
        trackPosition: trackPosition,
        placedBy: placedBy,
        turnsLeft: turnsLeft - 1,
      );

  @override
  bool operator ==(Object other) =>
      other is LudoBomb &&
      trackPosition == other.trackPosition &&
      placedBy == other.placedBy &&
      turnsLeft == other.turnsLeft;

  @override
  int get hashCode => Object.hash(trackPosition, placedBy, turnsLeft);
}

/// Immutable top-level game state for Ludo.
@immutable
class LudoGameState {
  const LudoGameState({
    this.phase = LudoPhase.idle,
    this.mode = LudoMode.soloVsBots,
    this.difficulty = LudoDifficulty.medium,
    this.diceMode = LudoDiceMode.classic,
    this.players = const [],
    this.currentPlayerIndex = 0,
    this.diceValue = 0,
    this.selectedTokenId,
    this.excludedColor,
    this.magicDiceFace,
    this.diceRollerColor,
    this.finishCount = 0,
    this.activeBombs = const [],
    this.turboOvershoot = false,
    this.skipMagicDiceOnNextRoll = false,
  });

  final LudoPhase phase;
  final LudoMode mode;
  final LudoDifficulty difficulty;
  final LudoDiceMode diceMode;

  /// Active player list (3 or 4 entries depending on mode).
  final List<LudoPlayer> players;

  /// Index into [players] for the player whose turn it is.
  final int currentPlayerIndex;

  /// Last dice roll result.  0 = not yet rolled this turn.
  final int diceValue;

  /// Token id currently selected by the human player (null = none).
  final int? selectedTokenId;

  /// In Free-for-All 3-player mode one colour is excluded.  Null otherwise.
  final LudoPlayerColor? excludedColor;

  /// The magic die face rolled this turn (null in classic mode or not yet rolled).
  final MagicDiceFace? magicDiceFace;

  /// Color of the player who last rolled the dice. Stays fixed until the next
  /// roll so the dice widget doesn't repaint on turn advance.
  final LudoPlayerColor? diceRollerColor;

  /// Number of players who have finished all 4 tokens.
  final int finishCount;

  /// Active bombs on the board (bomb magic face).
  final List<LudoBomb> activeBombs;

  /// True for one state emission when turbo causes all tokens to overshoot (no valid move).
  /// The UI reads this to show a brief message, then it is cleared on the next roll.
  final bool turboOvershoot;

  /// When true the next roll skips the magic die (bonus turn earned by rolling 6).
  final bool skipMagicDiceOnNextRoll;

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
            color: LudoPlayerColor.blue,
            name: 'Bot 1',
            isBot: true,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.red,
            name: 'You',
            isBot: false,
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
        const allColors = [
          LudoPlayerColor.blue,
          LudoPlayerColor.red,
          LudoPlayerColor.green,
          LudoPlayerColor.yellow,
        ];
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
          for (final c in const [
            LudoPlayerColor.blue,
            LudoPlayerColor.red,
            LudoPlayerColor.green,
            LudoPlayerColor.yellow,
          ])
            LudoPlayer.initial(color: c, name: _colorName(c), isBot: false),
        ];

      case LudoMode.twoVsTwo:
        // Red+Green = team 0, Blue+Yellow = team 1
        return [
          LudoPlayer.initial(
            color: LudoPlayerColor.blue,
            name: 'Blue',
            isBot: false,
            teamIndex: 1,
          ),
          LudoPlayer.initial(
            color: LudoPlayerColor.red,
            name: 'Red',
            isBot: false,
            teamIndex: 0,
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
    LudoDiceMode? diceMode,
    List<LudoPlayer>? players,
    int? currentPlayerIndex,
    int? diceValue,
    Object? selectedTokenId = _unset,
    Object? excludedColor = _unset,
    Object? magicDiceFace = _unset,
    Object? diceRollerColor = _unset,
    int? finishCount,
    List<LudoBomb>? activeBombs,
    bool? turboOvershoot,
    bool? skipMagicDiceOnNextRoll,
  }) {
    return LudoGameState(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      diceMode: diceMode ?? this.diceMode,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: diceValue ?? this.diceValue,
      selectedTokenId: selectedTokenId == _unset
          ? this.selectedTokenId
          : selectedTokenId as int?,
      excludedColor: excludedColor == _unset
          ? this.excludedColor
          : excludedColor as LudoPlayerColor?,
      magicDiceFace: magicDiceFace == _unset
          ? this.magicDiceFace
          : magicDiceFace as MagicDiceFace?,
      diceRollerColor: diceRollerColor == _unset
          ? this.diceRollerColor
          : diceRollerColor as LudoPlayerColor?,
      finishCount: finishCount ?? this.finishCount,
      activeBombs: activeBombs ?? this.activeBombs,
      turboOvershoot: turboOvershoot ?? this.turboOvershoot,
      skipMagicDiceOnNextRoll: skipMagicDiceOnNextRoll ?? this.skipMagicDiceOnNextRoll,
    );
  }
}
