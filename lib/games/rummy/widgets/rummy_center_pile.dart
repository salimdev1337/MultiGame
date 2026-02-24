import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

/// Draw pile + Discard pile side by side in the table center.
class RummyCenterPile extends StatelessWidget {
  const RummyCenterPile({
    super.key,
    required this.drawPileCount,
    required this.topDiscard,
    required this.canDraw,
    required this.onDrawFromDeck,
    required this.onDrawFromDiscard,
  });

  final int drawPileCount;
  final PlayingCard? topDiscard;
  final bool canDraw;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onDrawFromDiscard;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Draw pile.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: canDraw ? onDrawFromDeck : null,
              child: Stack(
                children: [
                  if (drawPileCount > 1)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: _blankCard(),
                    ),
                  _blankCard(highlighted: canDraw),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$drawPileCount cards',
              style: DSTypography.labelSmall.copyWith(color: DSColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Discard pile.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: canDraw && topDiscard != null ? onDrawFromDiscard : null,
              child: topDiscard != null
                  ? PlayingCardWidget(
                      card: topDiscard!,
                      faceUp: true,
                    )
                  : _emptyDiscardSlot(),
            ),
            const SizedBox(height: 4),
            Text(
              'Discard',
              style: DSTypography.labelSmall.copyWith(color: DSColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _blankCard({bool highlighted = false}) {
    return Container(
      width: kCardWidth,
      height: kCardHeight,
      decoration: BoxDecoration(
        color: highlighted
            ? DSColors.rummyCardBack.withValues(alpha: 0.9)
            : DSColors.rummyCardBack.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? DSColors.rummyAccent : DSColors.rummyAccent.withValues(alpha: 0.4),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: DSColors.rummyAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _emptyDiscardSlot() {
    return Container(
      width: kCardWidth,
      height: kCardHeight,
      decoration: BoxDecoration(
        color: DSColors.rummyFelt.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DSColors.rummyPrimary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: const Icon(Icons.add, color: Colors.white30, size: 20),
    );
  }
}
