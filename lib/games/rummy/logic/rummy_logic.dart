import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';
import '../models/rummy_meld.dart';
import '../models/rummy_player.dart';

// ── Card point values ─────────────────────────────────────────────────────────

int cardPointValue(PlayingCard card) {
  if (card.isJoker) {
    return 10;
  }
  if (card.rank == rankAce || card.rank >= rankJack) {
    return 10;
  }
  return card.rank;
}

// ── Meld validation ───────────────────────────────────────────────────────────

/// Returns the [MeldType] if [cards] form a valid meld, or null otherwise.
/// Requires at least 3 cards.
MeldType? validateMeld(List<PlayingCard> cards) {
  if (cards.length < 3) {
    return null;
  }
  if (_validateSet(cards)) {
    return MeldType.set;
  }
  if (_validateRun(cards)) {
    return MeldType.run;
  }
  return null;
}

/// Set: 3–4 cards of same rank, different suits (jokers fill any slot).
bool _validateSet(List<PlayingCard> cards) {
  if (cards.length > 4) {
    return false;
  }
  final nonJokers = cards.where((c) => !c.isJoker).toList();
  if (nonJokers.isEmpty) {
    return true;
  }
  final rank = nonJokers.first.rank;
  // All non-jokers must share the same rank.
  if (nonJokers.any((c) => c.rank != rank)) {
    return false;
  }
  // All non-jokers must have different suits.
  final suits = nonJokers.map((c) => c.suit).toSet();
  return suits.length == nonJokers.length;
}

/// Run: 3+ consecutive cards of same suit (jokers fill gaps).
bool _validateRun(List<PlayingCard> cards) {
  final nonJokers = cards.where((c) => !c.isJoker).toList();
  if (nonJokers.isEmpty) {
    return true;
  }
  final suit = nonJokers.first.suit;
  if (nonJokers.any((c) => c.suit != suit)) {
    return false;
  }
  final sortedRanks = nonJokers.map((c) => c.rank).toList()..sort();
  if (sortedRanks.toSet().length != nonJokers.length) {
    return false;
  }
  // Try ace-low (A = 1).
  final spanLow = sortedRanks.last - sortedRanks.first + 1;
  if (spanLow <= cards.length) {
    return true;
  }
  // Try ace-high (A = 14).
  if (sortedRanks.contains(rankAce)) {
    final adjusted = sortedRanks.map((r) => r == rankAce ? 14 : r).toList()..sort();
    final spanHigh = adjusted.last - adjusted.first + 1;
    if (spanHigh <= cards.length) {
      return true;
    }
  }
  return false;
}

/// Returns true if [cards] form a run where Ace plays as the highest card (rank 14).
bool _isAceHighRun(List<PlayingCard> cards) {
  final nonJokers = cards.where((c) => !c.isJoker).toList();
  final ranks = nonJokers.map((c) => c.rank).toSet();
  if (!ranks.contains(rankAce)) {
    return false;
  }
  // If ace-low span fits, treat ace as low (prefer low over high).
  final sortedLow = ranks.toList()..sort();
  final spanLow = sortedLow.last - sortedLow.first + 1;
  if (spanLow <= cards.length) {
    return false;
  }
  // Check ace-high (A = 14).
  final adjusted = ranks.map((r) => r == rankAce ? 14 : r).toList()..sort();
  final spanHigh = adjusted.last - adjusted.first + 1;
  return spanHigh <= cards.length;
}

// ── Run sort ──────────────────────────────────────────────────────────────────

/// Sorts run cards descending (high → low), placing jokers at gap positions.
/// Remaining jokers (no gap to fill) are prepended as the highest cards.
List<PlayingCard> sortRunCards(List<PlayingCard> cards) {
  final jokers = cards.where((c) => c.isJoker).toList();
  final nonJokers = cards.where((c) => !c.isJoker).toList();

  if (nonJokers.isEmpty) {
    return jokers;
  }

  final aceHigh = _isAceHighRun(cards);

  int effRank(PlayingCard card) =>
      aceHigh && card.rank == rankAce ? 14 : card.rank;

  nonJokers.sort((a, b) => effRank(b).compareTo(effRank(a)));

  if (jokers.isEmpty) {
    return nonJokers;
  }

  final result = <PlayingCard>[];
  var jokerIdx = 0;

  for (var i = 0; i < nonJokers.length; i++) {
    result.add(nonJokers[i]);
    if (i + 1 < nonJokers.length) {
      final cur = effRank(nonJokers[i]);
      final nxt = effRank(nonJokers[i + 1]);
      for (var gap = cur - 1; gap > nxt && jokerIdx < jokers.length; gap--) {
        result.add(jokers[jokerIdx++]);
      }
    }
  }

  if (jokerIdx < jokers.length) {
    return [...jokers.sublist(jokerIdx), ...result];
  }
  return result;
}

// ── Partition into multiple melds ─────────────────────────────────────────────

/// Returns a partition of [cards] into valid melds, or null if impossible.
/// Only succeeds when all cards are accounted for and each group is a valid meld.
List<List<PlayingCard>>? tryPartitionIntoMelds(List<PlayingCard> cards) {
  if (cards.length < 6) {
    return null;
  }
  return _partitionHelper(cards);
}

List<List<PlayingCard>>? _partitionHelper(List<PlayingCard> remaining) {
  if (remaining.isEmpty) {
    return [];
  }
  if (remaining.length < 3) {
    return null;
  }
  for (int size = 3; size <= remaining.length; size++) {
    for (final subset in _combinations(remaining, size)) {
      if (validateMeld(subset) != null) {
        final rest = remaining.where((c) => !subset.contains(c)).toList();
        final partitioned = _partitionHelper(rest);
        if (partitioned != null) {
          return [subset, ...partitioned];
        }
      }
    }
  }
  return null;
}

List<List<T>> _combinations<T>(List<T> items, int size) {
  if (size == 0) {
    return [[]];
  }
  if (items.length < size) {
    return [];
  }
  final result = <List<T>>[];
  for (int i = 0; i <= items.length - size; i++) {
    for (final rest in _combinations(items.sublist(i + 1), size - 1)) {
      result.add([items[i], ...rest]);
    }
  }
  return result;
}

// ── Add to meld ───────────────────────────────────────────────────────────────

/// Tries to add [cardsToAdd] to [meld] for an already-open player.
///
/// - Joker swap: if `nonJokers(meld) + cardsToAdd` is a valid meld of the
///   *same size* as [meld], one joker is retrieved.
/// - Extend:    if `meld.cards + cardsToAdd` is a valid longer meld.
///
/// Returns `({newMeld, retrievedJokers})` on success, `null` otherwise.
({RummyMeld newMeld, List<PlayingCard> retrievedJokers})? tryAddToMeld(
  RummyMeld meld,
  List<PlayingCard> cardsToAdd,
) {
  if (cardsToAdd.isEmpty) {
    return null;
  }

  final jokers = meld.cards.where((c) => c.isJoker).toList();
  final nonJokers = meld.cards.where((c) => !c.isJoker).toList();

  // Joker-swap path: only attempted when exactly one card is added and the
  // meld contains at least one joker.
  // For sets, only allowed when the joker is the 4th card (meld already has 4 cards).
  if (jokers.isNotEmpty && cardsToAdd.length == 1) {
    final allowSwap = meld.type == MeldType.run || meld.cards.length == 4;
    if (allowSwap) {
      final swapCards = [...nonJokers, cardsToAdd.first];
      if (swapCards.length == meld.cards.length) {
        final type = validateMeld(swapCards);
        if (type != null) {
          return (
            newMeld: RummyMeld(
              type: type,
              cards: type == MeldType.run ? sortRunCards(swapCards) : swapCards,
            ),
            retrievedJokers: [jokers.first],
          );
        }
      }
    }
  }

  // Extend path: add card(s) to the full meld.
  final extended = [...meld.cards, ...cardsToAdd];
  final type = validateMeld(extended);
  if (type != null) {
    return (
      newMeld: RummyMeld(
        type: type,
        cards: type == MeldType.run ? sortRunCards(extended) : extended,
      ),
      retrievedJokers: const [],
    );
  }

  return null;
}

// ── Deadwood ─────────────────────────────────────────────────────────────────

/// Sum of point values of all unmelded cards in [hand].
int deadwoodValue(List<PlayingCard> hand) {
  return hand.fold(0, (sum, c) => sum + cardPointValue(c));
}

/// Total point value of cards in a meld.
///
/// Jokers take the value of the card they replace:
/// - In a set: joker = value of the shared rank (e.g. set of 2s → joker = 2)
/// - In a run: joker = value of the rank it fills in the sequence
///
/// Ace rules:
/// - Ace in a low run (A-2-3 etc.) = 1
/// - Ace in a high run (A-K-Q-J etc.) or in a set = 10
int meldPointTotal(List<PlayingCard> meldCards) {
  final meldType = validateMeld(meldCards);

  if (meldType == MeldType.set) {
    final nonJokers = meldCards.where((c) => !c.isJoker).toList();
    final jokerValue = nonJokers.isNotEmpty ? cardPointValue(nonJokers.first) : 10;
    return meldCards.fold(0, (sum, c) => sum + (c.isJoker ? jokerValue : cardPointValue(c)));
  }

  if (meldType == MeldType.run) {
    final aceHigh = _isAceHighRun(meldCards);
    final sorted = sortRunCards(meldCards);
    final effectiveRanks = _resolveRunEffectiveRanks(sorted, aceHigh);
    return effectiveRanks.fold(0, (sum, rank) => sum + _runRankPointValue(rank));
  }

  return meldCards.fold(0, (sum, c) => sum + cardPointValue(c));
}

/// Point value for a rank as it appears in a run sequence.
/// Ace-low (effectiveRank == rankAce == 1) = 1; face cards and ace-high (>=11) = 10.
int _runRankPointValue(int effectiveRank) {
  if (effectiveRank >= rankJack) {
    return 10;
  }
  if (effectiveRank == rankAce) {
    return 1;
  }
  return effectiveRank;
}

/// Resolves the effective rank of every card in a sorted run (high → low).
/// Uses the first non-joker as an anchor to compute the rank sequence.
/// Jokers at the front extend the run upward; jokers in gaps fill down.
List<int> _resolveRunEffectiveRanks(List<PlayingCard> sortedCards, bool aceHigh) {
  int effRank(PlayingCard c) => aceHigh && c.rank == rankAce ? 14 : c.rank;

  int? anchorRank;
  int anchorIdx = 0;
  for (int i = 0; i < sortedCards.length; i++) {
    if (!sortedCards[i].isJoker) {
      anchorRank = effRank(sortedCards[i]);
      anchorIdx = i;
      break;
    }
  }

  if (anchorRank == null) {
    return List.filled(sortedCards.length, 0);
  }

  return List.generate(
    sortedCards.length,
    (i) => anchorRank! + (anchorIdx - i),
  );
}

// ── Declare check ─────────────────────────────────────────────────────────────

/// A round ends automatically when a player's hand is completely empty.
bool canDeclare(List<PlayingCard> hand) => hand.isEmpty;

// ── Round scoring ─────────────────────────────────────────────────────────────

/// Computes penalty points for each non-declarer after [declarerIndex] declares.
///
/// - 0 melds → flat +100
/// - ≥ 1 meld → deadwood card value
///
/// Returns a map of playerIndex → penalty.
Map<int, int> computeRoundPenalties(
  RummyGameState state,
  int declarerIndex,
) {
  final penalties = <int, int>{};
  for (var i = 0; i < state.players.length; i++) {
    if (i == declarerIndex) {
      continue;
    }
    final player = state.players[i];
    if (player.isEliminated) {
      continue;
    }
    if (player.melds.isEmpty) {
      penalties[i] = 100;
    } else {
      penalties[i] = deadwoodValue(player.hand);
    }
  }
  return penalties;
}

/// Returns true if the +50 discard penalty should fire.
///
/// Fires when:
/// - There was a last discard (lastDiscardByPlayer != null).
/// - [drawerIndex] is the immediately next active player.
/// - The drawn card matches the last discarded card.
/// - [drawerPlayer] has formed at least one meld using the drawn card this turn.
bool checkDiscardPenalty(
  RummyGameState state,
  int drawerIndex,
  PlayingCard drawn,
  RummyPlayer drawerPlayer,
) {
  if (state.lastDiscardByPlayer == null) {
    return false;
  }
  if (state.lastDiscardedCard?.id != drawn.id) {
    return false;
  }
  // The drawer must have used the drawn card in a meld.
  final usedInMeld = drawerPlayer.melds.any(
    (m) => m.cards.any((c) => c.id == drawn.id),
  );
  return usedInMeld;
}

// ── Next active player ────────────────────────────────────────────────────────

/// Returns the index of the next non-eliminated player after [currentIndex].
int nextActivePlayer(List<RummyPlayer> players, int currentIndex) {
  final count = players.length;
  for (var offset = 1; offset <= count; offset++) {
    final idx = (currentIndex + offset) % count;
    if (!players[idx].isEliminated) {
      return idx;
    }
  }
  return currentIndex;
}
