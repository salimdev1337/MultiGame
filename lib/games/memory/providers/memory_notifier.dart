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
  bool _isDisposed = false;

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  MemoryGameState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _cancelTimers();
    });
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
      currentPlayer: 0,
      playerScores: const [0, 0],
      playerMatches: const [0, 0],
      playerStreaks: const [0, 0],
    );
  }

  void flipCard(int cardId) {
    if (state.phase != MemoryGamePhase.playing) return;

    final index = state.cards.indexWhere((c) => c.id == cardId);
    if (index == -1) return;

    final card = state.cards[index];
    if (card.isFlipped || card.isMatched) return;

    final updatedCards = List<MemoryCard>.of(state.cards);
    updatedCards[index] = card.copyWith(isFlipped: true);

    if (state.firstIndex == null) {
      state = state.copyWith(cards: updatedCards, firstIndex: index);
    } else {
      state = state.copyWith(
        cards: updatedCards,
        secondIndex: index,
        phase: MemoryGamePhase.checking,
        moves: state.moves + 1,
      );
      _checkMatch();
    }
  }

  /// Called by the UI when the shuffle arc animation finishes.
  /// Flips wrong cards back face-down at their new positions, then switches turn.
  void onShuffleAnimationComplete() {
    if (state.phase != MemoryGamePhase.shuffling) return;

    // Determine which card IDs to flip back face-down.
    // Easy (1 pair): both wrong cards are the two IDs in that single pair.
    // Medium/Hard (2+ pairs): each pair's first ID is a wrong card.
    final updatedCards = List<MemoryCard>.of(state.cards);
    final pairs = state.swapPairs;
    if (pairs != null && pairs.isNotEmpty) {
      final wrongIds = pairs.length == 1
          ? [pairs[0].$1, pairs[0].$2]
          : [pairs[0].$1, pairs[1].$1];
      for (final wrongId in wrongIds) {
        final idx = updatedCards.indexWhere((c) => c.id == wrongId);
        if (idx != -1) {
          updatedCards[idx] = updatedCards[idx].copyWith(isFlipped: false);
        }
      }
    }

    state = state.copyWith(
      cards: updatedCards,
      phase: MemoryGamePhase.playing,
      currentPlayer: 1 - state.currentPlayer,
      swapPairs: null,
    );
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
      // ── Match: current player scores and keeps their turn ────────────────
      final p = state.currentPlayer;
      final points = computeScore(state.playerStreaks[p]);

      final newScores = List<int>.of(state.playerScores);
      newScores[p] += points;

      final newMatches = List<int>.of(state.playerMatches);
      newMatches[p] += 1;

      final newStreaks = List<int>.of(state.playerStreaks);
      newStreaks[p] += 1;

      final newHigh =
          newScores[p] > state.highScore ? newScores[p] : state.highScore;

      final updatedCards = List<MemoryCard>.of(state.cards);
      updatedCards[first] = updatedCards[first].copyWith(isMatched: true);
      updatedCards[second] = updatedCards[second].copyWith(isMatched: true);

      final newMatchedPairs = state.matchedPairs + 1;
      final won = newMatchedPairs == state.totalPairs;

      int? winner;
      if (won) {
        // Score is the primary win condition — streak multipliers make it
        // meaningful. Falls back to tie only when scores are truly equal.
        if (newScores[0] > newScores[1]) {
          winner = 0;
        } else if (newScores[1] > newScores[0]) {
          winner = 1;
        } else {
          winner = -1; // true tie
        }
      }

      state = state.copyWith(
        cards: updatedCards,
        firstIndex: null,
        secondIndex: null,
        matchedPairs: newMatchedPairs,
        playerScores: newScores,
        playerMatches: newMatches,
        playerStreaks: newStreaks,
        highScore: newHigh,
        phase: won ? MemoryGamePhase.won : MemoryGamePhase.playing,
        winner: won ? winner : null,
        // currentPlayer unchanged — correct match grants another turn.
      );

      if (won) {
        final bestScore = newScores.reduce((a, b) => a > b ? a : b);
        saveScore('memory_game', bestScore);
      }
    } else {
      // ── No match — show cards for 800 ms then shuffle ─────────────────
      _checkTimer = Timer(const Duration(milliseconds: 800), _doShuffle);
    }
  }

  void _doShuffle() {
    _checkTimer = null;
    if (_isDisposed) return;
    final first = state.firstIndex!;
    final second = state.secondIndex!;

    // Capture wrong card IDs before any mutation.
    final wrongId1 = state.cards[first].id;
    final wrongId2 = state.cards[second].id;

    // For shuffle logic only: treat wrong cards as face-down so they
    // are eligible swap targets in the position computation.
    final forShuffle = List<MemoryCard>.of(state.cards);
    forShuffle[first] = forShuffle[first].copyWith(isFlipped: false);
    forShuffle[second] = forShuffle[second].copyWith(isFlipped: false);

    // Reset current player's streak — wrong guess penalty.
    final newStreaks = List<int>.of(state.playerStreaks);
    newStreaks[state.currentPlayer] = 0;

    final (shuffled, swapPairs) = shuffleOnMismatch(
      forShuffle,
      first,
      second,
      _rng,
      extraCount: state.difficulty.shuffleExtraCount,
    );

    // Keep wrong cards face-up in state — they "freeze" visually during the
    // arc animation and only flip back in onShuffleAnimationComplete().
    final withFaceUp = List<MemoryCard>.of(shuffled);
    for (final wrongId in [wrongId1, wrongId2]) {
      final idx = withFaceUp.indexWhere((c) => c.id == wrongId);
      if (idx != -1) {
        withFaceUp[idx] = withFaceUp[idx].copyWith(isFlipped: true);
      }
    }

    state = state.copyWith(
      cards: withFaceUp,
      firstIndex: null,
      secondIndex: null,
      playerStreaks: newStreaks,
      phase: MemoryGamePhase.shuffling,
      swapPairs: swapPairs,
    );
  }

  void _cancelTimers() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
}

final memoryProvider =
    NotifierProvider.autoDispose<MemoryNotifier, MemoryGameState>(
  MemoryNotifier.new,
);
