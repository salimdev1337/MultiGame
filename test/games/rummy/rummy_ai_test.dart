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

  group('AI declares when possible', () {
    test('easy AI declares with 2+ valid melds in hand', () {
      // Hand that clearly forms 2 sets.
      final hand = [
        c(0, 5), c(1, 5), c(2, 5), // set
        c(0, 9), c(1, 9), c(2, 9), // set
        c(0, 2),
      ];
      final state = baseState(hand);
      final decisions = aiDecide(
          AiDifficulty.easy, bot(hand: hand), state.topDiscard, state, 1);
      final hasDeclare = decisions.any((d) => d is DeclareWin);
      expect(hasDeclare, isTrue);
    });
  });
}
