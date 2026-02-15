import 'dart:math';
import '../models/memory_card.dart';

/// Generates a shuffled deck of [totalPairs] pairs.
/// Returns a list of [totalPairs * 2] cards in random order.
List<MemoryCard> generateCards(int totalPairs, Random rng) {
  final cards = <MemoryCard>[];
  for (int v = 0; v < totalPairs; v++) {
    cards.add(MemoryCard(id: v * 2, value: v));
    cards.add(MemoryCard(id: v * 2 + 1, value: v));
  }
  cards.shuffle(rng);
  return cards;
}

/// Swaps cards at positions [i] and [j] with two randomly chosen
/// face-down, unmatched cards (different from i and j).
///
/// Returns the updated card list. If fewer than 2 other eligible cards
/// exist the swap is skipped gracefully.
List<MemoryCard> shuffleFour(
  List<MemoryCard> cards,
  int i,
  int j,
  Random rng,
) {
  // Collect eligible swap targets: face-down, unmatched, not i or j.
  final eligible = <int>[];
  for (int k = 0; k < cards.length; k++) {
    if (k != i && k != j && !cards[k].isFlipped && !cards[k].isMatched) {
      eligible.add(k);
    }
  }

  if (eligible.length < 2) return List.of(cards); // not enough cards to swap

  // Pick two distinct random positions from eligible list.
  eligible.shuffle(rng);
  final int p = eligible[0];
  final int q = eligible[1];

  final result = List<MemoryCard>.of(cards);

  // Swap: (i ↔ p) and (j ↔ q)
  final tmp = result[i];
  result[i] = result[p];
  result[p] = tmp;

  final tmp2 = result[j];
  result[j] = result[q];
  result[q] = tmp2;

  return result;
}

/// Score awarded for a correct match.
/// streak=0 → 100, streak=1 → 200, streak=2 → 300, streak≥3 → 400.
int computeScore(int streak) => 100 * (streak + 1).clamp(1, 4);
