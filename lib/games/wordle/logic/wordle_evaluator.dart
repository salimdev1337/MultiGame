import '../models/wordle_enums.dart';
import '../models/wordle_game_state.dart';

/// Evaluates a Wordle guess against the answer using standard two-pass logic.
///
/// Pass 1 — mark correct positions (green).
/// Pass 2 — mark present letters (yellow), respecting duplicate letter counts.
///
/// Examples:
///   evaluateGuess('crane', 'crane') → [correct, correct, correct, correct, correct]
///   evaluateGuess('speed', 'abode') → [absent, absent, absent, correct, present]
///   evaluateGuess('aabbb', 'cabbb') → [absent, correct, absent, correct, correct]
List<TileState> evaluateGuess(String guess, String answer) {
  assert(guess.length == kWordleWordLength);
  assert(answer.length == kWordleWordLength);

  final g = guess.toLowerCase();
  final a = answer.toLowerCase();

  final result = List<TileState>.filled(kWordleWordLength, TileState.absent);

  // Remaining answer letter counts for yellow matching
  final remaining = List<int>.filled(26, 0);
  for (final ch in a.codeUnits) {
    remaining[ch - 97]++;
  }

  // Pass 1: mark correct positions, deduct from remaining pool
  for (var i = 0; i < kWordleWordLength; i++) {
    if (g[i] == a[i]) {
      result[i] = TileState.correct;
      remaining[g.codeUnitAt(i) - 97]--;
    }
  }

  // Pass 2: mark present (yellow) for non-correct positions
  for (var i = 0; i < kWordleWordLength; i++) {
    if (result[i] == TileState.correct) {
      continue;
    }
    final idx = g.codeUnitAt(i) - 97;
    if (remaining[idx] > 0) {
      result[i] = TileState.present;
      remaining[idx]--;
    }
  }

  return result;
}

/// Returns true if [evaluation] represents a fully correct guess.
bool isCorrectGuess(List<TileState> evaluation) =>
    evaluation.every((t) => t == TileState.correct);

/// Merges letter states from all submitted guesses into a per-letter best state.
/// Used to colour the on-screen keyboard.
///
/// Priority: correct > present > absent > empty (untried).
Map<String, TileState> computeKeyboardState(
    List<({String word, List<TileState> evaluation})> guesses) {
  final best = <String, TileState>{};

  for (final g in guesses) {
    for (var i = 0; i < g.word.length; i++) {
      final letter = g.word[i];
      final current = best[letter];
      final incoming = g.evaluation[i];

      if (current == null || _priority(incoming) > _priority(current)) {
        best[letter] = incoming;
      }
    }
  }

  return best;
}

int _priority(TileState t) {
  switch (t) {
    case TileState.correct:
      return 3;
    case TileState.present:
      return 2;
    case TileState.absent:
      return 1;
    case TileState.empty:
      return 0;
  }
}
