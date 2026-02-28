import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_player.dart';
import 'playing_card_widget.dart';

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

  static const double _scale = 0.55;
  static const double _cardW = kCardWidth * _scale;
  static const double _cardH = kCardHeight * _scale;

  @override
  Widget build(BuildContext context) {
    final cardCount = player.hand.length.clamp(0, 8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _nameChip(),
        const SizedBox(height: 2),
        horizontal ? _horizontalCards(cardCount) : _verticalCards(cardCount),
      ],
    );
  }

  Widget _nameChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? DSColors.rummyAccent.withValues(alpha: 0.9)
            : DSColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentTurn ? DSColors.rummyAccent : DSColors.surfaceHighlight,
          width: 1,
        ),
      ),
      child: Text(
        '${player.name} (${player.hand.length}) ${player.score}pts',
        style: DSTypography.labelSmall.copyWith(
          color: isCurrentTurn ? Colors.black : DSColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _horizontalCards(int count) {
    final overlap = _cardW * 0.45;
    return SizedBox(
      height: _cardH,
      width: overlap * count + _cardW * 0.55,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * overlap,
              child: _faceDownCard(),
            ),
        ],
      ),
    );
  }

  Widget _verticalCards(int count) {
    final overlap = _cardH * 0.35;
    return SizedBox(
      width: _cardW,
      height: overlap * count + _cardH * 0.65,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              top: i * overlap,
              child: _faceDownCard(),
            ),
        ],
      ),
    );
  }

  Widget _faceDownCard() {
    const dummyCard = PlayingCard(
      id: '_back',
      suit: suitSpades,
      rank: rankAce,
      isJoker: false,
    );
    return PlayingCardWidget(
      card: dummyCard,
      faceUp: false,
      width: _cardW,
      height: _cardH,
    );
  }
}
