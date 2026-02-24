import 'dart:math';

import '../models/playing_card.dart';

/// Generates a full Rummy deck: 2×52 standard cards + 4 printed jokers = 108.
List<PlayingCard> generateDeck() {
  final cards = <PlayingCard>[];
  for (var deckNum = 1; deckNum <= 2; deckNum++) {
    for (var suit = 0; suit <= 3; suit++) {
      for (var rank = 1; rank <= 13; rank++) {
        cards.add(PlayingCard(
          id: 'd${deckNum}_s${suit}_r$rank',
          suit: suit,
          rank: rank,
          isJoker: false,
        ));
      }
    }
  }
  // 4 printed jokers
  for (var j = 1; j <= 4; j++) {
    cards.add(PlayingCard(
      id: 'joker_$j',
      suit: suitJoker,
      rank: rankJoker,
      isJoker: true,
    ));
  }
  return cards;
}

/// Returns a new shuffled copy of [deck].
List<PlayingCard> shuffle(List<PlayingCard> deck, {Random? rng}) {
  final copy = List<PlayingCard>.from(deck);
  copy.shuffle(rng ?? Random());
  return copy;
}

/// Deals [handSize] cards to [playerCount] players from a pre-shuffled [deck].
/// Returns the dealt hands and remaining draw pile.
({List<List<PlayingCard>> hands, List<PlayingCard> remaining})
    dealHands(List<PlayingCard> deck, int playerCount, int handSize) {
  final hands = List.generate(playerCount, (_) => <PlayingCard>[]);
  var idx = 0;
  for (var round = 0; round < handSize; round++) {
    for (var p = 0; p < playerCount; p++) {
      hands[p].add(deck[idx++]);
    }
  }
  return (hands: hands, remaining: deck.sublist(idx));
}
