import 'package:flutter/foundation.dart';
import 'memory_card.dart';

enum MemoryGamePhase { idle, playing, checking, shuffling, won }

enum MemoryDifficulty { easy, medium, hard }

extension MemoryDifficultyX on MemoryDifficulty {
  String get label => switch (this) {
        MemoryDifficulty.easy => 'Easy',
        MemoryDifficulty.medium => 'Medium',
        MemoryDifficulty.hard => 'Hard',
      };

  int get cols => switch (this) {
        MemoryDifficulty.easy => 4,
        MemoryDifficulty.medium => 4,
        MemoryDifficulty.hard => 6,
      };

  int get rows => switch (this) {
        MemoryDifficulty.easy => 4,
        MemoryDifficulty.medium => 6,
        MemoryDifficulty.hard => 6,
      };

  int get totalPairs => (cols * rows) ~/ 2;

  /// Duration of the shuffle arc animation — scales with difficulty.
  Duration get shuffleDuration => switch (this) {
        MemoryDifficulty.easy => const Duration(milliseconds: 600),
        MemoryDifficulty.medium => const Duration(milliseconds: 400),
        MemoryDifficulty.hard => const Duration(milliseconds: 260),
      };

  /// Extra random cards added to shuffle pool beyond the 2 wrong ones.
  /// Must be even. Easy: 2 swaps, medium: 3 swaps, hard: 4 swaps.
  int get shuffleExtraCount => switch (this) {
        MemoryDifficulty.easy => 2,
        MemoryDifficulty.medium => 4,
        MemoryDifficulty.hard => 6,
      };
}

@immutable
class MemoryGameState {
  const MemoryGameState({
    this.cards = const [],
    this.firstIndex,
    this.secondIndex,
    this.matchedPairs = 0,
    this.totalPairs = 8,
    this.moves = 0,
    this.highScore = 0,
    this.phase = MemoryGamePhase.idle,
    this.difficulty = MemoryDifficulty.easy,
    this.currentPlayer = 0,
    this.playerScores = const [0, 0],
    this.playerMatches = const [0, 0],
    this.playerStreaks = const [0, 0],
    this.winner,
    this.swapPairs,
  });

  final List<MemoryCard> cards;

  /// Index into [cards] of the first tapped (face-up, unmatched) card.
  final int? firstIndex;

  /// Index into [cards] of the second tapped card (only set while checking).
  final int? secondIndex;

  final int matchedPairs;
  final int totalPairs;

  /// Total pair-attempt count.
  final int moves;

  final int highScore;
  final MemoryGamePhase phase;
  final MemoryDifficulty difficulty;

  /// Index of the active player: 0 = P1, 1 = P2.
  final int currentPlayer;

  /// Scores for [P1, P2].
  final List<int> playerScores;

  /// Matched pair counts for [P1, P2].
  final List<int> playerMatches;

  /// Consecutive correct matches for [P1, P2] — drives streak multiplier.
  final List<int> playerStreaks;

  /// null while playing · 0 = P1 wins · 1 = P2 wins · -1 = tie.
  final int? winner;

  /// Card ID pairs animating during shuffle phase — drives arc animation.
  /// null when not animating.
  final List<(int, int)>? swapPairs;

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isIdle => phase == MemoryGamePhase.idle;
  bool get isPlaying => phase == MemoryGamePhase.playing;
  bool get isWon => phase == MemoryGamePhase.won;

  int get currentScore => playerScores[currentPlayer];
  int get currentStreak => playerStreaks[currentPlayer];

  MemoryGameState copyWith({
    List<MemoryCard>? cards,
    Object? firstIndex = _sentinel,
    Object? secondIndex = _sentinel,
    int? matchedPairs,
    int? totalPairs,
    int? moves,
    int? highScore,
    MemoryGamePhase? phase,
    MemoryDifficulty? difficulty,
    int? currentPlayer,
    List<int>? playerScores,
    List<int>? playerMatches,
    List<int>? playerStreaks,
    Object? winner = _sentinel,
    Object? swapPairs = _sentinel,
  }) {
    return MemoryGameState(
      cards: cards ?? this.cards,
      firstIndex:
          firstIndex == _sentinel ? this.firstIndex : firstIndex as int?,
      secondIndex:
          secondIndex == _sentinel ? this.secondIndex : secondIndex as int?,
      matchedPairs: matchedPairs ?? this.matchedPairs,
      totalPairs: totalPairs ?? this.totalPairs,
      moves: moves ?? this.moves,
      highScore: highScore ?? this.highScore,
      phase: phase ?? this.phase,
      difficulty: difficulty ?? this.difficulty,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      playerScores: playerScores ?? this.playerScores,
      playerMatches: playerMatches ?? this.playerMatches,
      playerStreaks: playerStreaks ?? this.playerStreaks,
      winner: winner == _sentinel ? this.winner : winner as int?,
      swapPairs: swapPairs == _sentinel
          ? this.swapPairs
          : swapPairs as List<(int, int)>?,
    );
  }
}

/// Sentinel value used to distinguish "pass null explicitly" from "omit".
const Object _sentinel = Object();
