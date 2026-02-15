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
      // Run several seeds; at least one should differ from sorted order.
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

  // ── shuffleFour ─────────────────────────────────────────────────────────────

  group('shuffleFour', () {
    List<MemoryCard> makeCards(int n) =>
        List.generate(n, (i) => MemoryCard(id: i, value: i ~/ 2));

    test('returns a list of the same length', () {
      final cards = makeCards(16);
      final result = shuffleFour(cards, 0, 1, Random(0));
      expect(result.length, 16);
    });

    test('moves the two designated cards to different positions', () {
      final cards = makeCards(16);
      // Ensure cards at 0 and 1 are face-down unmatched (they already are)
      final result = shuffleFour(cards, 0, 1, Random(0));
      // Cards originally at 0 and 1 should now be somewhere else
      // (their ids were 0 and 1)
      final newPos0 = result.indexWhere((c) => c.id == 0);
      final newPos1 = result.indexWhere((c) => c.id == 1);
      // At least one of them must have moved
      expect(newPos0 == 0 && newPos1 == 1, isFalse);
    });

    test('all original card ids are preserved', () {
      final cards = makeCards(16);
      final result = shuffleFour(cards, 0, 1, Random(5));
      final before = cards.map((c) => c.id).toSet();
      final after = result.map((c) => c.id).toSet();
      expect(after, before);
    });

    test('returns unchanged list when fewer than 2 eligible cards', () {
      // Create 4 cards where 2 are matched and 2 are the swap targets
      final cards = [
        const MemoryCard(id: 0, value: 0),
        const MemoryCard(id: 1, value: 1),
        MemoryCard(id: 2, value: 2, isMatched: true),
        MemoryCard(id: 3, value: 3, isMatched: true),
      ];
      // Only cards 0 and 1 are eligible, but they ARE i and j → 0 eligible others
      final result = shuffleFour(cards, 0, 1, Random(0));
      expect(result.map((c) => c.id).toList(), [0, 1, 2, 3]);
    });

    test('does not use matched or flipped cards as swap targets', () {
      // Make a deck where all others are matched except two
      final cards = List.generate(10, (i) {
        if (i == 0 || i == 1) return MemoryCard(id: i, value: i ~/ 2);
        if (i == 8 || i == 9) return MemoryCard(id: i, value: i ~/ 2);
        return MemoryCard(id: i, value: i ~/ 2, isMatched: true);
      });
      // i=0, j=1 — only 8 and 9 are eligible
      final result = shuffleFour(cards, 0, 1, Random(0));
      // Confirm matched cards didn't move
      for (int k = 2; k < 8; k++) {
        expect(result[k].id, k);
      }
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
  });
}
