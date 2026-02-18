import 'package:flutter/foundation.dart';

import 'ludo_enums.dart';

/// Immutable model for a single Ludo token.
///
/// Position encoding:
///   trackPosition == -1           → token still in home base (not launched)
///   trackPosition in 0..51        → on the shared 52-step track
///   trackPosition == -2            → in the coloured home column
///     homeColumnStep in 1..6       →   step within the home column
///   isFinished == true             → reached the centre (fully home)
@immutable
class LudoToken {
  const LudoToken({
    required this.id,
    required this.owner,
    this.trackPosition = -1,
    this.homeColumnStep = 0,
    this.isFinished = false,
    this.shieldTurnsLeft = 0,
    this.isFrozen = false,
  });

  /// Token index within the owning player's piece list (0–3).
  final int id;

  /// Which player owns this token.
  final LudoPlayerColor owner;

  /// -1 = base, 0-51 = track, -2 = home column sentinel.
  final int trackPosition;

  /// 0 = not in home column; 1-6 = step inside home column.
  final int homeColumnStep;

  /// True when the token has reached the centre finish zone.
  final bool isFinished;

  /// Remaining turns the shield powerup is active (0 = no shield).
  final int shieldTurnsLeft;

  /// When true this token skips its next move opportunity.
  final bool isFrozen;

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get isInBase => trackPosition == -1;
  bool get isInHomeColumn => trackPosition == -2 && !isFinished;
  bool get isOnTrack => trackPosition >= 0;

  // ── copyWith ───────────────────────────────────────────────────────────────

  LudoToken copyWith({
    int? trackPosition,
    int? homeColumnStep,
    bool? isFinished,
    int? shieldTurnsLeft,
    bool? isFrozen,
  }) {
    return LudoToken(
      id: id,
      owner: owner,
      trackPosition: trackPosition ?? this.trackPosition,
      homeColumnStep: homeColumnStep ?? this.homeColumnStep,
      isFinished: isFinished ?? this.isFinished,
      shieldTurnsLeft: shieldTurnsLeft ?? this.shieldTurnsLeft,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LudoToken &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          owner == other.owner &&
          trackPosition == other.trackPosition &&
          homeColumnStep == other.homeColumnStep &&
          isFinished == other.isFinished &&
          shieldTurnsLeft == other.shieldTurnsLeft &&
          isFrozen == other.isFrozen;

  @override
  int get hashCode => Object.hash(
        id,
        owner,
        trackPosition,
        homeColumnStep,
        isFinished,
        shieldTurnsLeft,
        isFrozen,
      );
}
