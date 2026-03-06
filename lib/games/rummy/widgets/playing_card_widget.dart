import 'package:flutter/material.dart';

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

  static const _baseShadow = BoxShadow(
    color: Color(0x42000000),
    blurRadius: 4,
    offset: Offset(1, 2),
  );

  static const _selectedGlow = BoxShadow(
    color: Color(0x99FFD700),
    blurRadius: 6,
    spreadRadius: 3,
  );

  @override
  Widget build(BuildContext context) {
    final path = _imagePath();
    final shadows = <BoxShadow>[
      if (faceUp) _baseShadow,
      if (isSelected) _selectedGlow,
    ];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: isSelected ? const Offset(0, -0.15) : Offset.zero,
        child: path != null
            ? Container(
                width: width,
                height: height,
                decoration: shadows.isNotEmpty
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: shadows,
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
            : Container(
                width: width,
                height: height,
                decoration: shadows.isNotEmpty
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: shadows,
                      )
                    : null,
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
