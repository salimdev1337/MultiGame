import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_player.dart';
import 'playing_card_widget.dart';

/// Displays a face-down opponent hand + name + score chip.
class RummyOpponentWidget extends StatelessWidget {
  const RummyOpponentWidget({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.horizontal = true,
  });

  final RummyPlayer player;
  final bool isCurrentTurn;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final cardCount = player.hand.length.clamp(0, 8);

    Widget cards = horizontal
        ? _horizontalCards(cardCount)
        : _verticalCards(cardCount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _nameChip(),
        const SizedBox(height: 4),
        cards,
        const SizedBox(height: 4),
        _meldBadge(),
      ],
    );
  }

  Widget _nameChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? DSColors.rummyAccent.withValues(alpha: 0.9)
            : DSColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? DSColors.rummyAccent : DSColors.surfaceHighlight,
          width: 1,
        ),
      ),
      child: Text(
        '${player.name}  ${player.score}pts',
        style: DSTypography.labelSmall.copyWith(
          color: isCurrentTurn ? Colors.black : DSColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _horizontalCards(int count) {
    return SizedBox(
      height: kCardHeight * 0.55,
      width: (kCardWidth * 0.5) * count + kCardWidth * 0.5,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * kCardWidth * 0.5,
              child: _faceDownCard(),
            ),
        ],
      ),
    );
  }

  Widget _verticalCards(int count) {
    return SizedBox(
      width: kCardWidth * 0.55,
      height: (kCardHeight * 0.4) * count + kCardHeight * 0.4,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              top: i * kCardHeight * 0.4,
              child: _faceDownCard(),
            ),
        ],
      ),
    );
  }

  Widget _faceDownCard() {
    // Use a placeholder card id for face-down rendering.
    const dummyCard = PlayingCard(
      id: '_back',
      suit: suitSpades,
      rank: rankAce,
      isJoker: false,
    );
    return PlayingCardWidget(
      card: dummyCard,
      faceUp: false,
      width: kCardWidth * 0.7,
      height: kCardHeight * 0.7,
    );
  }

  Widget _meldBadge() {
    if (player.melds.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DSColors.rummyPrimary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${player.melds.length} meld${player.melds.length > 1 ? 's' : ''}',
        style: DSTypography.labelSmall.copyWith(
          color: Colors.white,
          fontSize: 9,
        ),
      ),
    );
  }
}
