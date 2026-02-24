import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rummy/logic/rummy_logic.dart';
import 'package:multigame/games/rummy/models/playing_card.dart';
import 'package:multigame/games/rummy/models/rummy_game_state.dart';
import 'package:multigame/games/rummy/models/rummy_meld.dart';
import 'package:multigame/games/rummy/models/rummy_player.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

PlayingCard c(int suit, int rank) => PlayingCard(
      id: 's${suit}_r$rank',
      suit: suit,
      rank: rank,
      isJoker: false,
    );

const PlayingCard joker = PlayingCard(
  id: 'joker_1',
  suit: suitJoker,
  rank: rankJoker,
  isJoker: true,
);

// ── cardPointValue ─────────────────────────────────────────────────────────────

void main() {
  group('cardPointValue', () {
    test('Ace = 10', () => expect(cardPointValue(c(0, 1)), 10));
    test('2 = 2', () => expect(cardPointValue(c(0, 2)), 2));
    test('7 = 7', () => expect(cardPointValue(c(0, 7)), 7));
    test('10 = 10', () => expect(cardPointValue(c(0, 10)), 10));
    test('Jack = 10', () => expect(cardPointValue(c(0, 11)), 10));
    test('Queen = 10', () => expect(cardPointValue(c(0, 12)), 10));
    test('King = 10', () => expect(cardPointValue(c(0, 13)), 10));
    test('Joker = 10', () => expect(cardPointValue(joker), 10));
  });

  // ── validateMeld — sets ─────────────────────────────────────────────────────

  group('validateMeld — sets', () {
    test('3 same rank diff suits = set', () {
      final cards = [c(0, 7), c(1, 7), c(2, 7)];
      expect(validateMeld(cards), MeldType.set);
    });

    test('4 same rank diff suits = set', () {
      final cards = [c(0, 7), c(1, 7), c(2, 7), c(3, 7)];
      expect(validateMeld(cards), MeldType.set);
    });

    test('3 same rank same suit = not valid', () {
      final cards = [c(0, 7), c(0, 7), c(0, 7)];
      expect(validateMeld(cards), isNull);
    });

    test('joker fills set slot', () {
      final cards = [c(0, 5), c(1, 5), joker];
      expect(validateMeld(cards), MeldType.set);
    });

    test('2 cards = not valid', () {
      expect(validateMeld([c(0, 7), c(1, 7)]), isNull);
    });

    test('5 same rank = not valid (set max 4)', () {
      final cards = [c(0, 7), c(1, 7), c(2, 7), c(3, 7), joker];
      // 5 cards exceeds set limit
      expect(validateMeld(cards), isNull);
    });
  });

  // ── validateMeld — runs ─────────────────────────────────────────────────────

  group('validateMeld — runs', () {
    test('3 consecutive same suit = run', () {
      final cards = [c(0, 5), c(0, 6), c(0, 7)];
      expect(validateMeld(cards), MeldType.run);
    });

    test('5 consecutive same suit = run', () {
      final cards = [c(1, 3), c(1, 4), c(1, 5), c(1, 6), c(1, 7)];
      expect(validateMeld(cards), MeldType.run);
    });

    test('joker fills run gap', () {
      final cards = [c(0, 5), joker, c(0, 7)];
      expect(validateMeld(cards), MeldType.run);
    });

    test('different suits = not run', () {
      final cards = [c(0, 5), c(1, 6), c(0, 7)];
      expect(validateMeld(cards), isNull);
    });

    test('non-consecutive = not run', () {
      final cards = [c(0, 5), c(0, 7), c(0, 9)];
      expect(validateMeld(cards), isNull);
    });
  });

  // ── deadwoodValue ───────────────────────────────────────────────────────────

  group('deadwoodValue', () {
    test('empty hand = 0', () {
      expect(deadwoodValue([]), 0);
    });

    test('sums point values correctly', () {
      final hand = [c(0, 3), c(0, 7), c(1, 13), joker];
      expect(deadwoodValue(hand), 3 + 7 + 10 + 10);
    });
  });

  // ── canDeclare ──────────────────────────────────────────────────────────────

  group('canDeclare', () {
    RummyMeld meld(List<PlayingCard> cards) =>
        RummyMeld(type: MeldType.set, cards: cards);

    test('0 melds = cannot declare', () {
      expect(canDeclare([]), isFalse);
    });

    test('1 meld = cannot declare', () {
      expect(canDeclare([meld([c(0, 1), c(1, 1), c(2, 1)])]), isFalse);
    });

    test('2 melds = can declare', () {
      expect(
        canDeclare([
          meld([c(0, 1), c(1, 1), c(2, 1)]),
          meld([c(0, 5), c(0, 6), c(0, 7)]),
        ]),
        isTrue,
      );
    });
  });

  // ── nextActivePlayer ────────────────────────────────────────────────────────

  group('nextActivePlayer', () {
    RummyPlayer player(int id, {bool eliminated = false}) => RummyPlayer(
          id: id,
          name: 'P$id',
          isHuman: false,
          hand: const [],
          melds: const [],
          score: 0,
          isEliminated: eliminated,
        );

    test('simple clockwise', () {
      final players = [player(0), player(1), player(2), player(3)];
      expect(nextActivePlayer(players, 0), 1);
      expect(nextActivePlayer(players, 2), 3);
      expect(nextActivePlayer(players, 3), 0);
    });

    test('skips eliminated players', () {
      final players = [
        player(0),
        player(1, eliminated: true),
        player(2),
        player(3),
      ];
      expect(nextActivePlayer(players, 0), 2);
    });

    test('wraps around', () {
      final players = [
        player(0),
        player(1, eliminated: true),
        player(2, eliminated: true),
        player(3),
      ];
      expect(nextActivePlayer(players, 3), 0);
    });
  });

  // ── computeRoundPenalties ───────────────────────────────────────────────────

  group('computeRoundPenalties', () {
    RummyPlayer makePlayer({
      required int id,
      required List<PlayingCard> hand,
      required List<RummyMeld> melds,
      bool isEliminated = false,
    }) =>
        RummyPlayer(
          id: id,
          name: 'P$id',
          isHuman: id == 0,
          hand: hand,
          melds: melds,
          score: 0,
          isEliminated: isEliminated,
        );

    test('no melds = flat 100', () {
      final state = RummyGameState(
        players: [
          makePlayer(id: 0, hand: [], melds: []), // declarer
          makePlayer(id: 1, hand: [c(0, 5), c(1, 3)], melds: []),
        ],
      );
      final penalties = computeRoundPenalties(state, 0);
      expect(penalties[1], 100);
    });

    test('has melds = deadwood only', () {
      final meld = RummyMeld(
        type: MeldType.set,
        cards: [c(0, 7), c(1, 7), c(2, 7)],
      );
      final state = RummyGameState(
        players: [
          makePlayer(id: 0, hand: [], melds: []), // declarer
          makePlayer(
              id: 1, hand: [c(0, 5), c(0, 9)], melds: [meld]),
        ],
      );
      final penalties = computeRoundPenalties(state, 0);
      expect(penalties[1], 5 + 9);
    });

    test('eliminated player skipped', () {
      final state = RummyGameState(
        players: [
          makePlayer(id: 0, hand: [], melds: []),
          makePlayer(id: 1, hand: [c(0, 5)], melds: [],
              isEliminated: true),
          makePlayer(id: 2, hand: [c(0, 3)], melds: []),
        ],
      );
      final penalties = computeRoundPenalties(state, 0);
      expect(penalties.containsKey(1), isFalse);
      expect(penalties[2], 100);
    });
  });

  // ── checkDiscardPenalty ─────────────────────────────────────────────────────

  group('checkDiscardPenalty', () {
    final discardedCard = c(0, 8);

    test('fires when drawn card used in meld', () {
      final meld = RummyMeld(
        type: MeldType.run,
        cards: [c(0, 6), c(0, 7), discardedCard],
      );
      final player = RummyPlayer(
        id: 1,
        name: 'P1',
        isHuman: false,
        hand: [],
        melds: [meld],
        score: 0,
        isEliminated: false,
      );
      final state = RummyGameState(
        lastDiscardByPlayer: 0,
        lastDiscardedCard: discardedCard,
      );
      expect(
        checkDiscardPenalty(state, 1, discardedCard, player),
        isTrue,
      );
    });

    test('does not fire when drawn card not in any meld', () {
      final player = RummyPlayer(
        id: 1,
        name: 'P1',
        isHuman: false,
        hand: [discardedCard],
        melds: [],
        score: 0,
        isEliminated: false,
      );
      final state = RummyGameState(
        lastDiscardByPlayer: 0,
        lastDiscardedCard: discardedCard,
      );
      expect(
        checkDiscardPenalty(state, 1, discardedCard, player),
        isFalse,
      );
    });

    test('does not fire when lastDiscardByPlayer is null', () {
      final player = RummyPlayer(
        id: 1,
        name: 'P1',
        isHuman: false,
        hand: [],
        melds: [],
        score: 0,
        isEliminated: false,
      );
      final state = const RummyGameState();
      expect(
        checkDiscardPenalty(state, 1, discardedCard, player),
        isFalse,
      );
    });
  });
}
