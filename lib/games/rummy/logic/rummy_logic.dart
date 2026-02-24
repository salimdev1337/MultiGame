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
  // All non-jokers must share the same suit.
  final suit = nonJokers.first.suit;
  if (nonJokers.any((c) => c.suit != suit)) {
    return false;
  }
  // Sort non-jokers by rank.
  final sortedRanks = nonJokers.map((c) => c.rank).toList()..sort();
  // The span of the run must fit within the total card count.
  final span = sortedRanks.last - sortedRanks.first + 1;
  if (span > cards.length) {
    return false;
  }
  // No duplicate ranks allowed (jokers fill missing positions, not duplicates).
  final uniqueRanks = sortedRanks.toSet();
  return uniqueRanks.length == nonJokers.length;
}

// ── Deadwood ─────────────────────────────────────────────────────────────────

/// Sum of point values of all unmelded cards in [hand].
int deadwoodValue(List<PlayingCard> hand) {
  return hand.fold(0, (sum, c) => sum + cardPointValue(c));
}

// ── Declare check ─────────────────────────────────────────────────────────────

/// A player can declare when they have laid down at least 2 valid melds.
bool canDeclare(List<RummyMeld> melds) => melds.length >= kRummyMinMeldsToDeclare;

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
