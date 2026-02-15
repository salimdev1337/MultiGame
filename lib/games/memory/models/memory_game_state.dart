import 'package:flutter/foundation.dart';
import 'memory_card.dart';

enum MemoryGamePhase { idle, playing, checking, shuffling, won }

enum MemoryDifficulty { easy, medium, hard }

extension MemoryDifficultyX on MemoryDifficulty {
  String get label {
    switch (this) {
      case MemoryDifficulty.easy:
        return 'Easy';
      case MemoryDifficulty.medium:
        return 'Medium';
      case MemoryDifficulty.hard:
        return 'Hard';
    }
  }

  int get cols {
    switch (this) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 4;
      case MemoryDifficulty.hard:
        return 6;
    }
  }

  int get rows {
    switch (this) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 6;
      case MemoryDifficulty.hard:
        return 6;
    }
  }

  int get totalPairs => (cols * rows) ~/ 2;
}

@immutable
class MemoryGameState {
  const MemoryGameState({
    this.cards = const [],
    this.firstIndex,
    this.secondIndex,
    this.matchedPairs = 0,
    this.totalPairs = 8,
    this.score = 0,
    this.streak = 0,
    this.moves = 0,
    this.highScore = 0,
    this.phase = MemoryGamePhase.idle,
    this.difficulty = MemoryDifficulty.easy,
  });

  final List<MemoryCard> cards;

  /// Index into [cards] of the first tapped (face-up, unmatched) card.
  final int? firstIndex;

  /// Index into [cards] of the second tapped card (only set while checking).
  final int? secondIndex;

  final int matchedPairs;
  final int totalPairs;
  final int score;

  /// Consecutive correct matches — drives the streak multiplier.
  final int streak;

  /// Total pair-attempt count.
  final int moves;

  final int highScore;
  final MemoryGamePhase phase;
  final MemoryDifficulty difficulty;

  bool get isIdle => phase == MemoryGamePhase.idle;
  bool get isPlaying => phase == MemoryGamePhase.playing;
  bool get isWon => phase == MemoryGamePhase.won;

  MemoryGameState copyWith({
    List<MemoryCard>? cards,
    Object? firstIndex = _sentinel,
    Object? secondIndex = _sentinel,
    int? matchedPairs,
    int? totalPairs,
    int? score,
    int? streak,
    int? moves,
    int? highScore,
    MemoryGamePhase? phase,
    MemoryDifficulty? difficulty,
  }) {
    return MemoryGameState(
      cards: cards ?? this.cards,
      firstIndex:
          firstIndex == _sentinel ? this.firstIndex : firstIndex as int?,
      secondIndex:
          secondIndex == _sentinel ? this.secondIndex : secondIndex as int?,
      matchedPairs: matchedPairs ?? this.matchedPairs,
      totalPairs: totalPairs ?? this.totalPairs,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      moves: moves ?? this.moves,
      highScore: highScore ?? this.highScore,
      phase: phase ?? this.phase,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

/// Sentinel value used to distinguish "pass null explicitly" from "omit".
const Object _sentinel = Object();
