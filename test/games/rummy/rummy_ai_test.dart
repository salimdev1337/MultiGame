import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/rummy/logic/rummy_ai.dart';
import 'package:multigame/games/rummy/logic/rummy_deck.dart';
import 'package:multigame/games/rummy/models/playing_card.dart';
import 'package:multigame/games/rummy/models/rummy_game_state.dart';
import 'package:multigame/games/rummy/models/rummy_player.dart';

PlayingCard c(int suit, int rank) => PlayingCard(
      id: 's${suit}_r$rank',
      suit: suit,
      rank: rank,
      isJoker: false,
    );

RummyPlayer bot({required List<PlayingCard> hand}) => RummyPlayer(
      id: 1,
      name: 'Bot',
      isHuman: false,
      hand: hand,
      melds: const [],
      score: 0,
      isEliminated: false,
    );

RummyGameState baseState(List<PlayingCard> botHand) {
  final deck = shuffle(generateDeck());
  return RummyGameState(
    players: [
      RummyPlayer(
        id: 0,
        name: 'You',
        isHuman: true,
        hand: deck.sublist(0, 14),
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
      bot(hand: botHand),
      RummyPlayer(
        id: 2,
        name: 'Bot2',
        isHuman: false,
        hand: deck.sublist(28, 42),
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
      RummyPlayer(
        id: 3,
        name: 'Bot3',
        isHuman: false,
        hand: deck.sublist(42, 56),
        melds: const [],
        score: 0,
        isEliminated: false,
      ),
    ],
    drawPile: deck.sublist(56),
    discardPile: [deck[55]],
    phase: RummyPhase.playing,
    currentPlayerIndex: 1,
  );
}

void main() {
  group('Easy AI decisions', () {
    test('always includes a draw decision', () {
      final hand = [c(0, 3), c(1, 7), c(2, 11)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      final hasDrawDeck = decisions.any((d) => d is DrawFromDeck);
      expect(hasDrawDeck, isTrue);
    });

    test('includes a discard decision', () {
      final hand = [c(0, 3), c(1, 7), c(2, 11)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      final hasDiscard = decisions.any((d) => d is DiscardCard);
      expect(hasDiscard, isTrue);
    });

    test('decisions are non-empty', () {
      final hand = [c(0, 2), c(1, 5), c(2, 9), c(3, 13)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      expect(decisions, isNotEmpty);
    });
  });

  group('Medium AI decisions', () {
    test('produces non-empty decisions', () {
      final hand = [c(0, 4), c(1, 8), c(2, 12), c(3, 2)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.medium, bot(hand: hand), state.topDiscard, state, 1);
      expect(decisions, isNotEmpty);
    });

    test('includes a discard or declare decision', () {
      final hand = [c(0, 4), c(1, 8), c(2, 12), c(3, 2)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.medium, bot(hand: hand), state.topDiscard, state, 1);
      final terminal = decisions.any(
          (d) => d is DiscardCard || d is DeclareWin);
      expect(terminal, isTrue);
    });
  });

  group('Hard AI decisions', () {
    test('produces non-empty decisions', () {
      final hand = [c(0, 6), c(0, 7), c(0, 8), c(1, 3), c(2, 9)];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.hard, bot(hand: hand), state.topDiscard, state, 1);
      expect(decisions, isNotEmpty);
    });
  });

  group('AI opening minimum', () {
    test('easy AI lays melds when already open (no minimum check)', () {
      // Two sets worth 42 pts — below 71 minimum but bot is already open.
      final hand = [
        c(0, 5), c(1, 5), c(2, 5), // set: 15 pts
        c(0, 9), c(1, 9), c(2, 9), // set: 27 pts
        c(0, 2),
      ];
      final openBot = RummyPlayer(
        id: 1,
        name: 'Bot',
        isHuman: false,
        hand: hand,
        melds: const [],
        score: 0,
        isEliminated: false,
        isOpen: true,
      );
      final state = baseState(hand);
      final decisions =
          aiDecide(AiDifficulty.easy, openBot, state.topDiscard, state, 1);
      final hasLayMeld = decisions.any((d) => d is LayMeld);
      expect(hasLayMeld, isTrue);
    });

    test('easy AI withholds melds when total is below minimum', () {
      // Two sets worth 42 pts total — below 71 minimum, bot not open.
      final hand = [
        c(0, 5), c(1, 5), c(2, 5), // 15 pts
        c(0, 9), c(1, 9), c(2, 9), // 27 pts
        c(0, 2),
      ];
      final state = baseState(hand);
      final decisions =
          aiDecide(AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      final hasLayMeld = decisions.any((d) => d is LayMeld);
      expect(hasLayMeld, isFalse);
    });

    test('easy AI lays melds when combined value meets minimum', () {
      // Four Kings (K=10 each) + four Queens (Q=10 each) = 80 pts >= 71.
      final hand = [
        c(0, 13), c(1, 13), c(2, 13), c(3, 13), // 4-card set: 40 pts
        c(0, 12), c(1, 12), c(2, 12), c(3, 12), // 4-card set: 40 pts
        c(0, 2),
      ];
      final state = baseState(hand);
      final decisions =
          aiDecide(AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      final hasLayMeld = decisions.any((d) => d is LayMeld);
      expect(hasLayMeld, isTrue);
    });
  });
}
