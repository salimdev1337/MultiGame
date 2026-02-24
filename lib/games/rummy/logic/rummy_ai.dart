import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../models/rummy_meld.dart';
import '../models/rummy_player.dart';
import 'rummy_logic.dart';

// ── Decision types ────────────────────────────────────────────────────────────

sealed class AiDecision {}

class DrawFromDeck extends AiDecision {}

class DrawFromDiscard extends AiDecision {
  DrawFromDiscard(this.card);
  final PlayingCard card;
}

class LayMeld extends AiDecision {
  LayMeld(this.meld);
  final RummyMeld meld;
}

class DiscardCard extends AiDecision {
  DiscardCard(this.card);
  final PlayingCard card;
}

class DeclareWin extends AiDecision {}

// ── Public AI entry point ─────────────────────────────────────────────────────

/// Returns a sequence of decisions for the AI's full turn.
List<AiDecision> aiDecide(
  AiDifficulty difficulty,
  RummyPlayer self,
  PlayingCard? topDiscard,
  RummyGameState state,
  int selfIndex,
) {
  switch (difficulty) {
    case AiDifficulty.easy:
      return _easyDecide(self, topDiscard);
    case AiDifficulty.medium:
      return _mediumDecide(self, topDiscard, state, selfIndex);
    case AiDifficulty.hard:
      return _hardDecide(self, topDiscard, state, selfIndex);
  }
}

// ── Easy AI ───────────────────────────────────────────────────────────────────

List<AiDecision> _easyDecide(RummyPlayer self, PlayingCard? topDiscard) {
  final decisions = <AiDecision>[];

  // Always draw from deck.
  decisions.add(DrawFromDeck());

  // Try to form melds from hand (naive: try all combos of 3+).
  final hand = List<PlayingCard>.from(self.hand);
  final foundMelds = _extractMelds(hand);
  decisions.addAll(foundMelds.map(LayMeld.new));

  // Declare if >= 2 melds placed.
  if (self.melds.length + foundMelds.length >= kRummyMinMeldsToDeclare) {
    decisions.add(DeclareWin());
    return decisions;
  }

  // Discard highest-value card.
  final remaining = _removeUsedCards(hand, foundMelds);
  if (remaining.isNotEmpty) {
    remaining.sort((a, b) => cardPointValue(b).compareTo(cardPointValue(a)));
    decisions.add(DiscardCard(remaining.first));
  }

  return decisions;
}

// ── Medium AI ─────────────────────────────────────────────────────────────────

List<AiDecision> _mediumDecide(
  RummyPlayer self,
  PlayingCard? topDiscard,
  RummyGameState state,
  int selfIndex,
) {
  final decisions = <AiDecision>[];

  // Draw from discard if it improves our hand toward a meld.
  if (topDiscard != null && _improvesHand(self.hand, topDiscard)) {
    decisions.add(DrawFromDiscard(topDiscard));
  } else {
    decisions.add(DrawFromDeck());
  }

  // Try to form melds.
  final hand = List<PlayingCard>.from(self.hand);
  final foundMelds = _extractMelds(hand);
  decisions.addAll(foundMelds.map(LayMeld.new));

  if (self.melds.length + foundMelds.length >= kRummyMinMeldsToDeclare) {
    decisions.add(DeclareWin());
    return decisions;
  }

  // Discard — avoid handing easy melds to next player.
  final remaining = _removeUsedCards(hand, foundMelds);
  if (remaining.isNotEmpty) {
    final nextIdx = nextActivePlayer(state.players, selfIndex);
    final nextHand = state.players[nextIdx].hand;
    remaining.sort((a, b) {
      final aRisk = _discardRisk(a, nextHand);
      final bRisk = _discardRisk(b, nextHand);
      if (aRisk != bRisk) {
        return aRisk.compareTo(bRisk); // prefer low-risk discard
      }
      return cardPointValue(b).compareTo(cardPointValue(a));
    });
    decisions.add(DiscardCard(remaining.first));
  }

  return decisions;
}

// ── Hard AI ───────────────────────────────────────────────────────────────────

List<AiDecision> _hardDecide(
  RummyPlayer self,
  PlayingCard? topDiscard,
  RummyGameState state,
  int selfIndex,
) {
  final decisions = <AiDecision>[];

  // Draw from discard only if it won't give an easy meld to us from the enemy.
  if (topDiscard != null && _improvesHand(self.hand, topDiscard)) {
    decisions.add(DrawFromDiscard(topDiscard));
  } else {
    decisions.add(DrawFromDeck());
  }

  final hand = List<PlayingCard>.from(self.hand);
  final foundMelds = _extractMelds(hand);
  decisions.addAll(foundMelds.map(LayMeld.new));

  if (self.melds.length + foundMelds.length >= kRummyMinMeldsToDeclare) {
    decisions.add(DeclareWin());
    return decisions;
  }

  final remaining = _removeUsedCards(hand, foundMelds);
  if (remaining.isNotEmpty) {
    final nextIdx = nextActivePlayer(state.players, selfIndex);
    final nextHand = state.players[nextIdx].hand;

    // Hard: strongly prefer safe discards (next player can't meld with them).
    remaining.sort((a, b) {
      final aScore = _discardRisk(a, nextHand) * 10 + cardPointValue(a);
      final bScore = _discardRisk(b, nextHand) * 10 + cardPointValue(b);
      return aScore.compareTo(bScore);
    });

    decisions.add(DiscardCard(remaining.first));
  }

  return decisions;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extracts as many valid melds as possible from [hand] (greedy).
List<RummyMeld> _extractMelds(List<PlayingCard> hand) {
  final melds = <RummyMeld>[];
  final available = List<PlayingCard>.from(hand);

  bool found = true;
  while (found) {
    found = false;
    for (var size = 4; size >= 3; size--) {
      final combo = _findMeldCombo(available, size);
      if (combo != null) {
        melds.add(combo);
        for (final c in combo.cards) {
          available.remove(c);
        }
        found = true;
        break;
      }
    }
  }
  return melds;
}

RummyMeld? _findMeldCombo(List<PlayingCard> cards, int size) {
  if (cards.length < size) {
    return null;
  }
  final indices = List.generate(size, (i) => i);
  return _nextCombo(cards, indices, size);
}

RummyMeld? _nextCombo(
    List<PlayingCard> cards, List<int> indices, int size) {
  if (indices.last >= cards.length) {
    return null;
  }
  final combo = [for (final i in indices) cards[i]];
  final type = validateMeld(combo);
  if (type != null) {
    return RummyMeld(type: type, cards: combo);
  }
  // Advance to next combination.
  for (var i = size - 1; i >= 0; i--) {
    if (indices[i] < cards.length - (size - i)) {
      indices[i]++;
      for (var j = i + 1; j < size; j++) {
        indices[j] = indices[j - 1] + 1;
      }
      return _nextCombo(cards, indices, size);
    }
  }
  return null;
}

/// Removes meld cards from [hand] and returns the remaining.
List<PlayingCard> _removeUsedCards(
    List<PlayingCard> hand, List<RummyMeld> melds) {
  final usedIds = melds.expand((m) => m.cards.map((c) => c.id)).toSet();
  return hand.where((c) => !usedIds.contains(c.id)).toList();
}

/// Returns true if drawing [card] brings the hand closer to a valid meld.
bool _improvesHand(List<PlayingCard> hand, PlayingCard card) {
  final testHand = [...hand, card];
  for (var i = 0; i < testHand.length; i++) {
    for (var j = i + 1; j < testHand.length; j++) {
      for (var k = j + 1; k < testHand.length; k++) {
        if (validateMeld([testHand[i], testHand[j], testHand[k]]) != null) {
          return true;
        }
      }
    }
  }
  return false;
}

/// Returns a risk score (0 = safe, higher = risky) for discarding [card]
/// given the [nextPlayerHand].
int _discardRisk(PlayingCard card, List<PlayingCard> nextPlayerHand) {
  if (card.isJoker) {
    return 0;
  }
  var risk = 0;
  for (final other in nextPlayerHand) {
    if (other.isJoker) {
      continue;
    }
    // Same rank — contributes to a set.
    if (other.rank == card.rank) {
      risk++;
    }
    // Adjacent rank same suit — contributes to a run.
    if (other.suit == card.suit && (other.rank - card.rank).abs() <= 2) {
      risk++;
    }
  }
  return risk;
}

