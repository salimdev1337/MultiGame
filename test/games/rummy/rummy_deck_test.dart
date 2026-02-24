import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rummy/logic/rummy_deck.dart';

void main() {
  group('generateDeck', () {
    test('has 108 cards total', () {
      final deck = generateDeck();
      expect(deck.length, 108);
    });

    test('has exactly 4 jokers', () {
      final deck = generateDeck();
      final jokers = deck.where((c) => c.isJoker).toList();
      expect(jokers.length, 4);
    });

    test('has 104 non-joker cards (2×52)', () {
      final deck = generateDeck();
      final nonJokers = deck.where((c) => !c.isJoker).toList();
      expect(nonJokers.length, 104);
    });

    test('all card IDs are unique', () {
      final deck = generateDeck();
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, deck.length);
    });

    test('has all 4 suits, ranks 1–13, in both decks', () {
      final deck = generateDeck();
      final nonJokers = deck.where((c) => !c.isJoker).toList();
      for (var suit = 0; suit <= 3; suit++) {
        for (var rank = 1; rank <= 13; rank++) {
          final count = nonJokers
              .where((c) => c.suit == suit && c.rank == rank)
              .length;
          expect(count, 2, reason: 'suit=$suit rank=$rank should appear twice');
        }
      }
    });
  });

  group('shuffle', () {
    test('returns same number of cards', () {
      final deck = generateDeck();
      final shuffled = shuffle(deck);
      expect(shuffled.length, deck.length);
    });

    test('preserves all cards', () {
      final deck = generateDeck();
      final shuffled = shuffle(deck);
      final originalIds = deck.map((c) => c.id).toSet();
      final shuffledIds = shuffled.map((c) => c.id).toSet();
      expect(shuffledIds, originalIds);
    });
  });

  group('dealHands', () {
    test('deals correct number of cards to each player', () {
      final deck = shuffle(generateDeck());
      final result = dealHands(deck, 4, 14);
      for (final hand in result.hands) {
        expect(hand.length, 14);
      }
    });

    test('remaining pile has correct size', () {
      final deck = shuffle(generateDeck());
      final result = dealHands(deck, 4, 14);
      expect(result.remaining.length, 108 - 4 * 14);
    });

    test('no card dealt twice', () {
      final deck = shuffle(generateDeck());
      final result = dealHands(deck, 4, 14);
      final all = [...result.hands.expand((h) => h), ...result.remaining];
      final ids = all.map((c) => c.id).toSet();
      expect(ids.length, all.length);
    });
  });
}
