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

/// Shuffles the two mismatched cards ([i] and [j]) with [extraCount] randomly
/// chosen face-down unmatched cards. [extraCount] must be even and ≥ 2.
///
/// Returns the updated card list and a list of swap pairs as
/// (cardId_a, cardId_b) for the UI arc animation to consume.
///
/// Gracefully skips if fewer than 2 eligible cards are available.
(List<MemoryCard>, List<(int, int)>) shuffleOnMismatch(
  List<MemoryCard> cards,
  int i,
  int j,
  Random rng, {
  int extraCount = 2,
}) {
  // Collect eligible targets: face-down, unmatched, not i or j.
  final eligible = <int>[];
  for (int k = 0; k < cards.length; k++) {
    if (k != i && k != j && !cards[k].isFlipped && !cards[k].isMatched) {
      eligible.add(k);
    }
  }

  if (eligible.length < 2) return (List.of(cards), const []);

  eligible.shuffle(rng);

  // Clamp to available count, keeping it even and ≥ 2.
  final extra = (extraCount.clamp(2, eligible.length) ~/ 2) * 2;
  final targets = eligible.take(extra).toList();

  final result = List<MemoryCard>.of(cards);
  final swapPairs = <(int, int)>[];

  // wrong1 ↔ target1
  {
    final p = targets[0];
    swapPairs.add((cards[i].id, cards[p].id));
    final tmp = result[i];
    result[i] = result[p];
    result[p] = tmp;
  }

  // wrong2 ↔ target2
  {
    final q = targets[1];
    swapPairs.add((cards[j].id, cards[q].id));
    final tmp = result[j];
    result[j] = result[q];
    result[q] = tmp;
  }

  // Additional pair swaps for medium/hard difficulties.
  for (int t = 2; t < targets.length - 1; t += 2) {
    final a = targets[t];
    final b = targets[t + 1];
    swapPairs.add((cards[a].id, cards[b].id));
    final tmp = result[a];
    result[a] = result[b];
    result[b] = tmp;
  }

  return (result, swapPairs);
}

/// Score awarded for a correct match.
/// streak=0 → 100, streak=1 → 200, streak=2 → 300, streak≥3 → 400.
int computeScore(int streak) => 100 * (streak + 1).clamp(1, 4);
