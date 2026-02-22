import 'package:flutter/foundation.dart';

import 'ludo_enums.dart';
import 'ludo_token.dart';

/// Immutable model representing one Ludo player.
@immutable
class LudoPlayer {
  const LudoPlayer({
    required this.color,
    required this.tokens,
    required this.isBot,
    required this.name,
    this.teamIndex = -1,
    this.consecutiveSixes = 0,
    this.finishPosition = 0,
  });

  /// This player's colour (also uniquely identifies them).
  final LudoPlayerColor color;

  /// Always exactly 4 tokens.
  final List<LudoToken> tokens;

  /// True when this player is controlled by the bot AI.
  final bool isBot;

  /// -1 = no team (solo / FFA).  0 or 1 = team index for 2v2 mode.
  final int teamIndex;

  /// Display name (e.g. "Red", "Bot 1").
  final String name;

  /// Consecutive sixes rolled (2 in a row = 6 blocked on next roll).
  final int consecutiveSixes;

  /// 0 = still playing; 1 = 1st to finish; 2 = 2nd; etc.
  final int finishPosition;

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get hasWon => tokens.every((t) => t.isFinished);
  int get tokensHome => tokens.where((t) => t.isInBase).length;
  int get tokensFinished => tokens.where((t) => t.isFinished).length;

  // ── Factory ────────────────────────────────────────────────────────────────

  /// Creates a player with 4 tokens, all in base.
  factory LudoPlayer.initial({
    required LudoPlayerColor color,
    required String name,
    required bool isBot,
    int teamIndex = -1,
  }) {
    return LudoPlayer(
      color: color,
      name: name,
      isBot: isBot,
      teamIndex: teamIndex,
      tokens: List.generate(
        4,
        (i) => LudoToken(id: i, owner: color),
      ),
    );
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  LudoPlayer copyWith({
    List<LudoToken>? tokens,
    int? consecutiveSixes,
    int? finishPosition,
  }) {
    return LudoPlayer(
      color: color,
      tokens: tokens ?? this.tokens,
      isBot: isBot,
      teamIndex: teamIndex,
      name: name,
      consecutiveSixes: consecutiveSixes ?? this.consecutiveSixes,
      finishPosition: finishPosition ?? this.finishPosition,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LudoPlayer &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          tokens == other.tokens &&
          isBot == other.isBot &&
          teamIndex == other.teamIndex &&
          name == other.name &&
          consecutiveSixes == other.consecutiveSixes &&
          finishPosition == other.finishPosition;

  @override
  int get hashCode => Object.hash(
        color,
        tokens,
        isBot,
        teamIndex,
        name,
        consecutiveSixes,
        finishPosition,
      );
}
