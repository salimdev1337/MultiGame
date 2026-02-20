import 'dart:math';

import 'package:flutter/services.dart';

import '../models/wordle_game_state.dart';

/// Manages loading and querying the Wordle word lists.
///
/// Call [initialize] once before using any other methods.
/// Results are cached — subsequent calls to [initialize] are no-ops.
class WordDatabase {
  WordDatabase._();

  static List<String>? _answers;
  static Set<String>? _valid;

  static bool get isInitialized => _answers != null && _valid != null;

  /// Loads word lists from assets. Safe to call multiple times.
  static Future<void> initialize([AssetBundle? bundle]) async {
    if (isInitialized) {
      return;
    }
    final b = bundle ?? rootBundle;
    final answersRaw =
        await b.loadString('assets/data/wordle_answers.txt');
    final validRaw =
        await b.loadString('assets/data/wordle_valid.txt');

    _answers = answersRaw
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.length == kWordleWordLength)
        .toList();

    _valid = validRaw
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.length == kWordleWordLength)
        .toSet();

    // Answers must always be valid guesses too
    _valid!.addAll(_answers!);
  }

  /// Returns [count] words deterministically for a given [seed].
  ///
  /// Same seed always returns the same words in the same order.
  static List<String> selectWords(int seed, int count) {
    assert(isInitialized, 'WordDatabase.initialize() must be called first');
    assert(count <= _answers!.length, 'count exceeds answer pool size');

    final rng = Random(seed);
    final pool = List<String>.from(_answers!);

    // Fisher-Yates partial shuffle — only shuffle what we need
    for (var i = 0; i < count; i++) {
      final j = i + rng.nextInt(pool.length - i);
      final tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    return pool.sublist(0, count);
  }

  /// Returns true if [word] is a valid Wordle guess.
  static bool isValidGuess(String word) {
    assert(isInitialized, 'WordDatabase.initialize() must be called first');
    return _valid!.contains(word.toLowerCase());
  }

  /// Number of words in the answer pool.
  static int get answerCount {
    assert(isInitialized, 'WordDatabase.initialize() must be called first');
    return _answers!.length;
  }
}
