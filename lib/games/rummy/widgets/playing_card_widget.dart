import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import '../painters/card_painter.dart';

const double kCardWidth = 56.0;
const double kCardHeight = 84.0;
const double kCardAspectRatio = kCardWidth / kCardHeight;

/// A tappable playing card with optional selection lift and flip animation.
class PlayingCardWidget extends StatelessWidget {
  const PlayingCardWidget({
    super.key,
    required this.card,
    this.faceUp = true,
    this.isSelected = false,
    this.onTap,
    this.width = kCardWidth,
    this.height = kCardHeight,
  });

  final PlayingCard card;
  final bool faceUp;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: isSelected ? const Offset(0, -0.15) : Offset.zero,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: CardPainter(
              card: card,
              faceUp: faceUp,
              isSelected: isSelected,
            ),
          ),
        ),
      ),
    );
  }
}
