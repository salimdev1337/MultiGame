import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_meld.dart';
import 'playing_card_widget.dart';

/// Displays a row of placed melds for a player.
class RummyMeldWidget extends StatelessWidget {
  const RummyMeldWidget({super.key, required this.melds, this.label});

  final List<RummyMeld> melds;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (melds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: DSTypography.labelSmall.copyWith(
              color: DSColors.textTertiary,
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: melds.map((meld) => _MeldGroup(meld: meld)).toList(),
          ),
        ),
      ],
    );
  }
}

class _MeldGroup extends StatelessWidget {
  const _MeldGroup({required this.meld});
  final RummyMeld meld;

  List<PlayingCard> _sortedCards(RummyMeld meld) {
    final sorted = [...meld.cards];
    if (meld.type == MeldType.run) {
      // Ascending rank; jokers (rank 0) go to end.
      sorted.sort((a, b) {
        if (a.isJoker && b.isJoker) {
          return 0;
        }
        if (a.isJoker) {
          return 1;
        }
        if (b.isJoker) {
          return -1;
        }
        return a.rank.compareTo(b.rank);
      });
    } else {
      // Set: same rank — sort by suit for visual consistency; jokers last.
      sorted.sort((a, b) {
        if (a.isJoker && b.isJoker) {
          return 0;
        }
        if (a.isJoker) {
          return 1;
        }
        if (b.isJoker) {
          return -1;
        }
        return a.suit.compareTo(b.suit);
      });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 20, bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DSColors.rummyFelt.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: DSColors.rummyAccent.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _sortedCards(meld)
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 3),
                child: PlayingCardWidget(
                  card: card,
                  width: kCardWidth * 1.8,
                  height: kCardHeight * 1.8,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
