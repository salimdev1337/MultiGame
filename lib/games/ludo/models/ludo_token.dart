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
    this.ghostTurnsLeft = 0,
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

  /// Remaining player-turns the ghost magic face is active (0 = not ghost, >0 = immune to captures and bombs).
  final int ghostTurnsLeft;

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool get isInBase => trackPosition == -1;
  bool get isInHomeColumn => trackPosition == -2 && !isFinished;
  bool get isOnTrack => trackPosition >= 0;

  // ── copyWith ───────────────────────────────────────────────────────────────

  LudoToken copyWith({
    int? trackPosition,
    int? homeColumnStep,
    bool? isFinished,
    int? ghostTurnsLeft,
  }) {
    return LudoToken(
      id: id,
      owner: owner,
      trackPosition: trackPosition ?? this.trackPosition,
      homeColumnStep: homeColumnStep ?? this.homeColumnStep,
      isFinished: isFinished ?? this.isFinished,
      ghostTurnsLeft: ghostTurnsLeft ?? this.ghostTurnsLeft,
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
          ghostTurnsLeft == other.ghostTurnsLeft;

  @override
  int get hashCode => Object.hash(
        id,
        owner,
        trackPosition,
        homeColumnStep,
        isFinished,
        ghostTurnsLeft,
      );
}
