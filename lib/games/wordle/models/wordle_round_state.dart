import 'package:flutter/foundation.dart';
import 'wordle_enums.dart';

/// A single submitted guess with its tile evaluation.
@immutable
class WordleGuess {
  const WordleGuess({required this.word, required this.evaluation});

  final String word;
  final List<TileState> evaluation;

  Map<String, dynamic> toJson() => {
        'word': word,
        'evaluation': evaluation.map((t) => t.name).toList(),
      };

  factory WordleGuess.fromJson(Map<String, dynamic> json) => WordleGuess(
        word: json['word'] as String,
        evaluation: (json['evaluation'] as List)
            .map((t) => TileState.values.byName(t as String))
            .toList(),
      );
}

/// One player's state within a single round.
@immutable
class WordlePlayerRound {
  const WordlePlayerRound({
    this.guesses = const [],
    this.isSolved = false,
  });

  final List<WordleGuess> guesses;
  final bool isSolved;

  int get attemptsUsed => guesses.length;
  bool get isExhausted => attemptsUsed >= 6;
  bool get isFinished => isSolved || isExhausted;

  WordlePlayerRound copyWith({
    List<WordleGuess>? guesses,
    bool? isSolved,
  }) {
    return WordlePlayerRound(
      guesses: guesses ?? this.guesses,
      isSolved: isSolved ?? this.isSolved,
    );
  }

  WordlePlayerRound addGuess(WordleGuess guess, {required bool solved}) {
    return WordlePlayerRound(
      guesses: [...guesses, guess],
      isSolved: solved,
    );
  }
}
