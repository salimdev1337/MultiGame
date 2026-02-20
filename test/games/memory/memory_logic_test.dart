import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/memory/logic/memory_logic.dart';
import 'package:multigame/games/memory/models/memory_card.dart';
import 'package:multigame/games/memory/models/memory_game_state.dart';

void main() {
  group('generateCards', () {
    test('produces totalPairs * 2 cards', () {
      final cards = generateCards(8, Random(42));
      expect(cards.length, 16);
    });

    test('each value appears exactly twice', () {
      const pairs = 12;
      final cards = generateCards(pairs, Random(1));
      final counts = <int, int>{};
      for (final c in cards) {
        counts[c.value] = (counts[c.value] ?? 0) + 1;
      }
      expect(counts.length, pairs);
      for (final count in counts.values) {
        expect(count, 2);
      }
    });

    test('all ids are unique', () {
      final cards = generateCards(8, Random(7));
      final ids = cards.map((c) => c.id).toSet();
      expect(ids.length, cards.length);
    });

    test('cards are shuffled (not always in value order)', () {
      bool foundUnsorted = false;
      for (int seed = 0; seed < 20; seed++) {
        final cards = generateCards(8, Random(seed));
        final values = cards.map((c) => c.value).toList();
        final sorted = List<int>.of(values)..sort();
        if (values.toString() != sorted.toString()) {
          foundUnsorted = true;
          break;
        }
      }
      expect(foundUnsorted, isTrue);
    });

    test('all cards start face-down and unmatched', () {
      final cards = generateCards(6, Random(0));
      for (final c in cards) {
        expect(c.isFlipped, isFalse);
        expect(c.isMatched, isFalse);
      }
    });
  });

  // ── shuffleOnMismatch ────────────────────────────────────────────────────────

  group('shuffleOnMismatch', () {
    List<MemoryCard> makeCards(int n) =>
        List.generate(n, (i) => MemoryCard(id: i, value: i ~/ 2));

    test('returns a list of the same length', () {
      final cards = makeCards(16);
      final (result, _) = shuffleOnMismatch(cards, 0, 1, Random(0));
      expect(result.length, 16);
    });

    test('returns swap pairs list', () {
      final cards = makeCards(16);
      final (_, swapPairs) = shuffleOnMismatch(cards, 0, 1, Random(0));
      expect(swapPairs, isNotEmpty);
    });

    test('swap pairs contain card ids involved in the shuffle', () {
      final cards = makeCards(16);
      final (_, swapPairs) = shuffleOnMismatch(cards, 0, 1, Random(0));
      // The wrong cards (id 0 and id 1) must appear in some swap pair.
      final allIds = swapPairs.expand((p) => [p.$1, p.$2]).toSet();
      expect(allIds.contains(0) || allIds.contains(1), isTrue);
    });

    test('moves the two designated cards to different positions', () {
      final cards = makeCards(16);
      final (result, _) = shuffleOnMismatch(cards, 0, 1, Random(0));
      final newPos0 = result.indexWhere((c) => c.id == 0);
      final newPos1 = result.indexWhere((c) => c.id == 1);
      expect(newPos0 == 0 && newPos1 == 1, isFalse);
    });

    test('all original card ids are preserved', () {
      final cards = makeCards(16);
      final (result, _) = shuffleOnMismatch(cards, 0, 1, Random(5));
      final before = cards.map((c) => c.id).toSet();
      final after = result.map((c) => c.id).toSet();
      expect(after, before);
    });

    test('returns unchanged list when fewer than 2 eligible cards', () {
      final cards = [
        const MemoryCard(id: 0, value: 0),
        const MemoryCard(id: 1, value: 1),
        MemoryCard(id: 2, value: 2, isMatched: true),
        MemoryCard(id: 3, value: 3, isMatched: true),
      ];
      final (result, swapPairs) = shuffleOnMismatch(cards, 0, 1, Random(0));
      expect(result.map((c) => c.id).toList(), [0, 1, 2, 3]);
      expect(swapPairs, isEmpty);
    });

    test('does not use matched or flipped cards as swap targets', () {
      final cards = List.generate(10, (i) {
        if (i == 0 || i == 1) return MemoryCard(id: i, value: i ~/ 2);
        if (i == 8 || i == 9) return MemoryCard(id: i, value: i ~/ 2);
        return MemoryCard(id: i, value: i ~/ 2, isMatched: true);
      });
      final (result, _) = shuffleOnMismatch(cards, 0, 1, Random(0));
      // Matched cards at indices 2–7 must not have moved.
      for (int k = 2; k < 8; k++) {
        expect(result[k].id, k);
      }
    });

    test('easy mode (extraCount=0) swaps the two wrong cards with each other', () {
      final cards = makeCards(16);
      final (result, swapPairs) = shuffleOnMismatch(
        cards, 0, 1, Random(0),
        extraCount: 0,
      );
      // Exactly 1 swap pair containing both wrong card IDs.
      expect(swapPairs.length, 1);
      expect(swapPairs[0].$1, cards[0].id);
      expect(swapPairs[0].$2, cards[1].id);
      // The two wrong cards end up at each other's original positions.
      expect(result.indexWhere((c) => c.id == cards[0].id), 1);
      expect(result.indexWhere((c) => c.id == cards[1].id), 0);
    });

    test('medium difficulty produces more swap pairs than easy', () {
      final cards = makeCards(24); // enough eligible cards
      final (_, easyPairs) = shuffleOnMismatch(
        cards, 0, 1, Random(0),
        extraCount: MemoryDifficulty.easy.shuffleExtraCount, // 0 → 1 pair
      );
      final (_, mediumPairs) = shuffleOnMismatch(
        cards, 0, 1, Random(0),
        extraCount: MemoryDifficulty.medium.shuffleExtraCount, // 4 → 2 pairs
      );
      expect(mediumPairs.length, greaterThan(easyPairs.length));
    });

    test('hard difficulty produces more swap pairs than medium', () {
      final cards = makeCards(36);
      final (_, mediumPairs) = shuffleOnMismatch(
        cards, 0, 1, Random(0),
        extraCount: MemoryDifficulty.medium.shuffleExtraCount,
      );
      final (_, hardPairs) = shuffleOnMismatch(
        cards, 0, 1, Random(0),
        extraCount: MemoryDifficulty.hard.shuffleExtraCount,
      );
      expect(hardPairs.length, greaterThan(mediumPairs.length));
    });
  });

  // ── computeScore ────────────────────────────────────────────────────────────

  group('computeScore', () {
    test('streak 0 → 100', () => expect(computeScore(0), 100));
    test('streak 1 → 200', () => expect(computeScore(1), 200));
    test('streak 2 → 300', () => expect(computeScore(2), 300));
    test('streak 3 → 400', () => expect(computeScore(3), 400));
    test('streak 4 (capped) → 400', () => expect(computeScore(4), 400));
    test('streak 10 (capped) → 400', () => expect(computeScore(10), 400));
  });

  // ── MemoryDifficulty extension ───────────────────────────────────────────────

  group('MemoryDifficultyX', () {
    test('easy: 4×4 = 8 pairs', () {
      expect(MemoryDifficulty.easy.cols, 4);
      expect(MemoryDifficulty.easy.rows, 4);
      expect(MemoryDifficulty.easy.totalPairs, 8);
    });

    test('medium: 4×6 = 12 pairs', () {
      expect(MemoryDifficulty.medium.cols, 4);
      expect(MemoryDifficulty.medium.rows, 6);
      expect(MemoryDifficulty.medium.totalPairs, 12);
    });

    test('hard: 6×6 = 18 pairs', () {
      expect(MemoryDifficulty.hard.cols, 6);
      expect(MemoryDifficulty.hard.rows, 6);
      expect(MemoryDifficulty.hard.totalPairs, 18);
    });

    test('shuffleDuration decreases with difficulty', () {
      expect(
        MemoryDifficulty.easy.shuffleDuration >
            MemoryDifficulty.medium.shuffleDuration,
        isTrue,
      );
      expect(
        MemoryDifficulty.medium.shuffleDuration >
            MemoryDifficulty.hard.shuffleDuration,
        isTrue,
      );
    });

    test('shuffleExtraCount increases with difficulty', () {
      expect(
        MemoryDifficulty.easy.shuffleExtraCount <
            MemoryDifficulty.medium.shuffleExtraCount,
        isTrue,
      );
      expect(
        MemoryDifficulty.medium.shuffleExtraCount <
            MemoryDifficulty.hard.shuffleExtraCount,
        isTrue,
      );
    });
  });

  // ── MemoryCard ────────────────────────────────────────────────────────────────

  group('MemoryCard', () {
    test('copyWith updates only specified fields', () {
      const card = MemoryCard(id: 1, value: 3);
      final flipped = card.copyWith(isFlipped: true);
      expect(flipped.id, 1);
      expect(flipped.value, 3);
      expect(flipped.isFlipped, isTrue);
      expect(flipped.isMatched, isFalse);
    });

    test('equality holds for same values', () {
      const a = MemoryCard(id: 0, value: 0);
      const b = MemoryCard(id: 0, value: 0);
      expect(a, b);
    });

    test('equality fails for different flip state', () {
      const a = MemoryCard(id: 0, value: 0);
      final b = a.copyWith(isFlipped: true);
      expect(a, isNot(b));
    });
  });

  // ── MemoryGameState ───────────────────────────────────────────────────────────

  group('MemoryGameState', () {
    test('default phase is idle', () {
      expect(const MemoryGameState().phase, MemoryGamePhase.idle);
    });

    test('isIdle / isPlaying / isWon helpers', () {
      expect(const MemoryGameState().isIdle, isTrue);
      expect(
        const MemoryGameState(phase: MemoryGamePhase.playing).isPlaying,
        isTrue,
      );
      expect(
        const MemoryGameState(phase: MemoryGamePhase.won).isWon,
        isTrue,
      );
    });

    test('copyWith with null firstIndex clears it', () {
      final s = const MemoryGameState(
        phase: MemoryGamePhase.playing,
      ).copyWith(firstIndex: 3);
      expect(s.firstIndex, 3);
      final cleared = s.copyWith(firstIndex: null);
      expect(cleared.firstIndex, isNull);
    });

    test('default playerScores are [0, 0]', () {
      expect(const MemoryGameState().playerScores, [0, 0]);
    });

    test('default playerMatches are [0, 0]', () {
      expect(const MemoryGameState().playerMatches, [0, 0]);
    });

    test('default playerStreaks are [0, 0]', () {
      expect(const MemoryGameState().playerStreaks, [0, 0]);
    });

    test('default currentPlayer is 0', () {
      expect(const MemoryGameState().currentPlayer, 0);
    });

    test('default winner is null', () {
      expect(const MemoryGameState().winner, isNull);
    });

    test('copyWith sets winner explicitly to null', () {
      final s = const MemoryGameState().copyWith(winner: 0);
      expect(s.winner, 0);
      final cleared = s.copyWith(winner: null);
      expect(cleared.winner, isNull);
    });

    test('copyWith sets swapPairs explicitly to null', () {
      final s = const MemoryGameState()
          .copyWith(swapPairs: [(1, 2), (3, 4)]);
      expect(s.swapPairs, isNotNull);
      final cleared = s.copyWith(swapPairs: null);
      expect(cleared.swapPairs, isNull);
    });

    test('currentScore returns active player score', () {
      final s = const MemoryGameState(
        currentPlayer: 1,
        playerScores: [100, 300],
      );
      expect(s.currentScore, 300);
    });

    test('currentStreak returns active player streak', () {
      final s = const MemoryGameState(
        currentPlayer: 0,
        playerStreaks: [3, 1],
      );
      expect(s.currentStreak, 3);
    });
  });
}
