import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/playing_card.dart';
import '../painters/card_painter.dart';

const double kCardWidth = 60.0;
const double kCardHeight = 90.0;
const double kCardAspectRatio = kCardWidth / kCardHeight;

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

  String? _imagePath() {
    if (!faceUp) {
      return null;
    }
    if (card.isJoker) {
      final idx = int.tryParse(card.id.replaceAll('joker_', '')) ?? 1;
      return idx.isOdd
          ? 'assets/images/deck/card_59.png'
          : 'assets/images/deck/card_60.png';
    }
    if (card.rank < rankJack) {
      return null;
    }
    final suitOffset = switch (card.suit) {
      1 => 20,
      2 => 25,
      3 => 50,
      0 => 55,
      _ => null,
    };
    if (suitOffset == null) {
      return null;
    }
    return 'assets/images/deck/card_${suitOffset + card.rank - 10}.png';
  }

  @override
  Widget build(BuildContext context) {
    final path = _imagePath();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: isSelected ? const Offset(0, -0.15) : Offset.zero,
        child: RepaintBoundary(
          child: path != null
            ? Container(
                width: width,
                height: height,
                decoration: isSelected
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: DSColors.rummyAccent.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 3,
                          ),
                        ],
                      )
                    : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    path,
                    width: width,
                    height: height,
                    fit: BoxFit.fill,
                  ),
                ),
              )
            : SizedBox(
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
      ),
    );
  }
}
