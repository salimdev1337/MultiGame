import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

import '../logic/memory_logic.dart';
import '../models/memory_card.dart';
import '../models/memory_game_state.dart';

class MemoryNotifier extends GameStatsNotifier<MemoryGameState> {
  final Random _rng = Random();
  Timer? _checkTimer;
  Timer? _shuffleTimer;

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  MemoryGameState build() {
    ref.onDispose(_cancelTimers);
    return const MemoryGameState();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void startGame(MemoryDifficulty difficulty) {
    _cancelTimers();
    final pairs = difficulty.totalPairs;
    final cards = generateCards(pairs, _rng);
    state = MemoryGameState(
      cards: cards,
      totalPairs: pairs,
      highScore: state.highScore,
      phase: MemoryGamePhase.playing,
      difficulty: difficulty,
    );
  }

  void flipCard(int index) {
    // Only accept taps while actively playing.
    if (state.phase != MemoryGamePhase.playing) return;

    final card = state.cards[index];
    // Ignore already-revealed or matched cards.
    if (card.isFlipped || card.isMatched) return;

    final updatedCards = List<MemoryCard>.of(state.cards);
    updatedCards[index] = card.copyWith(isFlipped: true);

    if (state.firstIndex == null) {
      // First card of the pair.
      state = state.copyWith(
        cards: updatedCards,
        firstIndex: index,
      );
    } else {
      // Second card of the pair — move to checking phase.
      state = state.copyWith(
        cards: updatedCards,
        secondIndex: index,
        phase: MemoryGamePhase.checking,
        moves: state.moves + 1,
      );
      _checkMatch();
    }
  }

  void restart() => startGame(state.difficulty);

  void reset() {
    _cancelTimers();
    state = MemoryGameState(highScore: state.highScore);
  }

  // ── Internal logic ────────────────────────────────────────────────────────

  void _checkMatch() {
    final first = state.firstIndex!;
    final second = state.secondIndex!;

    if (state.cards[first].value == state.cards[second].value) {
      // ── Match ──────────────────────────────────────────────────────────
      final newStreak = state.streak + 1;
      final points = computeScore(state.streak); // score before incrementing
      final newScore = state.score + points;
      final newMatched = state.matchedPairs + 1;
      final newHigh = newScore > state.highScore ? newScore : state.highScore;

      final updatedCards = List<MemoryCard>.of(state.cards);
      updatedCards[first] = updatedCards[first].copyWith(isMatched: true);
      updatedCards[second] = updatedCards[second].copyWith(isMatched: true);

      final won = newMatched == state.totalPairs;

      state = state.copyWith(
        cards: updatedCards,
        firstIndex: null,
        secondIndex: null,
        matchedPairs: newMatched,
        score: newScore,
        streak: newStreak,
        highScore: newHigh,
        phase: won ? MemoryGamePhase.won : MemoryGamePhase.playing,
      );

      if (won) {
        saveScore('memory_game', state.score);
      }
    } else {
      // ── No match — show cards for 800 ms then shuffle ─────────────────
      _checkTimer = Timer(const Duration(milliseconds: 800), _doShuffle);
    }
  }

  void _doShuffle() {
    _checkTimer = null;
    final first = state.firstIndex!;
    final second = state.secondIndex!;

    // Flip the two mismatched cards back face-down.
    final flippedBack = List<MemoryCard>.of(state.cards);
    flippedBack[first] = flippedBack[first].copyWith(isFlipped: false);
    flippedBack[second] = flippedBack[second].copyWith(isFlipped: false);

    // Shuffle those 2 cards with 2 random face-down unmatched cards.
    final shuffled = shuffleFour(flippedBack, first, second, _rng);

    state = state.copyWith(
      cards: shuffled,
      firstIndex: null,
      secondIndex: null,
      streak: 0, // wrong guess resets streak
      phase: MemoryGamePhase.shuffling,
    );

    // After the 600 ms visual animation completes, return to playing.
    _shuffleTimer = Timer(const Duration(milliseconds: 600), () {
      _shuffleTimer = null;
      if (state.phase == MemoryGamePhase.shuffling) {
        state = state.copyWith(phase: MemoryGamePhase.playing);
      }
    });
  }

  void _cancelTimers() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _shuffleTimer?.cancel();
    _shuffleTimer = null;
  }
}

final memoryProvider =
    NotifierProvider.autoDispose<MemoryNotifier, MemoryGameState>(
  MemoryNotifier.new,
);
