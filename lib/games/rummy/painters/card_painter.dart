import 'package:flutter/rendering.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/playing_card.dart';
import 'card_back_painter.dart';
import 'face_card_painter.dart';
import 'pip_layout.dart';

const _kWhite = Color(0xFFFFFEFA);
const _kRed = Color(0xFFCC0000);
const _kBlack = Color(0xFF1A1A1A);

class CardPainter extends CustomPainter {
  const CardPainter({
    required this.card,
    this.faceUp = true,
    this.isSelected = false,
  });

  final PlayingCard card;
  final bool faceUp;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    if (isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(9)),
        Paint()
          ..color = DSColors.rummyAccent.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    if (!faceUp) {
      paintCardBack(canvas, size, rRect);
      return;
    }

    // White card background
    canvas.save();
    canvas.clipRRect(rRect);
    canvas.drawRect(rect, Paint()..color = _kWhite);

    if (card.isJoker) {
      _paintJoker(canvas, size);
    } else if (card.rank >= rankJack) {
      _paintFaceCard(canvas, size);
    } else {
      _paintPipCard(canvas, size);
    }

    canvas.restore();

    // Card border
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFBBBBBB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  Color get _suitColor => card.isRed ? _kRed : _kBlack;

  void _paintCornerLabels(Canvas canvas, Size size) {
    final rankSize = size.height * 0.13;
    final suitSize = size.height * 0.14;
    final margin = size.width * 0.08;

    // Top-left rank
    final rankTp = TextPainter(
      text: TextSpan(
        text: card.rankLabel,
        style: TextStyle(
          fontSize: rankSize,
          color: _suitColor,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    rankTp.paint(canvas, Offset(margin, margin));

    // Top-left suit symbol below rank
    final suitY = margin + rankTp.height + 1;
    drawSuitSymbol(canvas, card.suit, Offset(margin + rankTp.width / 2, suitY + suitSize * 0.5), suitSize * 0.5);

    // Bottom-right (rotated 180)
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.scale(-1, -1);
    rankTp.paint(canvas, Offset(margin, margin));
    drawSuitSymbol(canvas, card.suit, Offset(margin + rankTp.width / 2, suitY + suitSize * 0.5), suitSize * 0.5);
    canvas.restore();
  }

  void _paintPipCard(Canvas canvas, Size size) {
    _paintCornerLabels(canvas, size);

    final positions = kPipPositions[card.rank];
    if (positions == null) {
      return;
    }

    // Ace gets a large center symbol
    if (card.rank == rankAce) {
      drawSuitSymbol(canvas, card.suit, Offset(size.width * 0.5, size.height * 0.5), size.width * 0.3);
      return;
    }

    final pipSize = size.width * 0.19;
    for (final pos in positions) {
      drawSuitSymbol(
        canvas,
        card.suit,
        Offset(size.width * pos.x, size.height * pos.y),
        pipSize,
        flip: pos.flip,
      );
    }
  }

  void _paintFaceCard(Canvas canvas, Size size) {
    _paintCornerLabels(canvas, size);

    // Faint background tint for face cards
    final tint = _suitColor.withValues(alpha: 0.04);
    canvas.drawRect(Offset.zero & size, Paint()..color = tint);

    // Draw the geometric figure
    paintFaceCard(canvas, size, card);
  }

  void _paintJoker(Canvas canvas, Size size) {
    // Background tint
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFFF8E7),
    );

    // "JOKER" text at top
    final fontSize = size.height * 0.08;
    final tp = TextPainter(
      text: TextSpan(
        text: 'JOKER',
        style: TextStyle(
          fontSize: fontSize,
          color: _kRed,
          fontWeight: FontWeight.bold,
          height: 1,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.06));

    // Jester figure
    paintJokerFigure(canvas, size);

    // "JOKER" at bottom (rotated)
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.scale(-1, -1);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.06));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CardPainter old) =>
      old.card.id != card.id || old.faceUp != faceUp || old.isSelected != isSelected;
}
