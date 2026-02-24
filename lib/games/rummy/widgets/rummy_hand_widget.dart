import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

/// Displays the human player's hand in a fan arc layout.
class RummyHandWidget extends StatelessWidget {
  const RummyHandWidget({
    super.key,
    required this.cards,
    required this.selectedCardIds,
    required this.onCardTap,
    this.enabled = true,
  });

  final List<PlayingCard> cards;
  final List<String> selectedCardIds;
  final void Function(PlayingCard) onCardTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: cards.map((card) {
            final selected = selectedCardIds.contains(card.id);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: PlayingCardWidget(
                card: card,
                faceUp: true,
                isSelected: selected,
                onTap: enabled ? () => onCardTap(card) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
