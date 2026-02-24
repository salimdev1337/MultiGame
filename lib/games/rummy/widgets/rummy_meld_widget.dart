import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/rummy_meld.dart';
import 'playing_card_widget.dart';

/// Displays a row of placed melds for a player.
class RummyMeldWidget extends StatelessWidget {
  const RummyMeldWidget({
    super.key,
    required this.melds,
    this.label,
  });

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
            style: DSTypography.labelSmall.copyWith(color: DSColors.textTertiary),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.all(3),
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
        children: meld.cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: PlayingCardWidget(
                    card: card,
                    width: kCardWidth * 0.75,
                    height: kCardHeight * 0.75,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
