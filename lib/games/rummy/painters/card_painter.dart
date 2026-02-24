import 'package:flutter/rendering.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/playing_card.dart';

/// Paints a casino-style playing card face-up or face-down.
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
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Selection glow.
    if (isSelected) {
      final glowPaint = Paint()
        ..color = DSColors.rummyAccent.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(3),
          const Radius.circular(11),
        ),
        glowPaint,
      );
    }

    if (!faceUp) {
      _paintBack(canvas, size, rRect);
    } else if (card.isJoker) {
      _paintJoker(canvas, size, rRect);
    } else {
      _paintFace(canvas, size, rRect);
    }
  }

  // ── Face-down ─────────────────────────────────────────────────────────────

  void _paintBack(Canvas canvas, Size size, RRect rRect) {
    // Dark navy background.
    canvas.drawRRect(
      rRect,
      Paint()..color = DSColors.rummyCardBack,
    );

    // Gold border.
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = DSColors.rummyAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner ornate diamond pattern.
    final cx = size.width / 2;
    final cy = size.height / 2;
    final patternPaint = Paint()
      ..color = DSColors.rummyAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(cx, cy - size.height * 0.3)
      ..lineTo(cx + size.width * 0.25, cy)
      ..lineTo(cx, cy + size.height * 0.3)
      ..lineTo(cx - size.width * 0.25, cy)
      ..close();
    canvas.drawPath(path, patternPaint);

    // Small inner diamond.
    final inner = Path()
      ..moveTo(cx, cy - size.height * 0.15)
      ..lineTo(cx + size.width * 0.12, cy)
      ..lineTo(cx, cy + size.height * 0.15)
      ..lineTo(cx - size.width * 0.12, cy)
      ..close();
    canvas.drawPath(inner, patternPaint);
  }

  // ── Face-up ───────────────────────────────────────────────────────────────

  void _paintFace(Canvas canvas, Size size, RRect rRect) {
    // Cream background.
    canvas.drawRRect(
      rRect,
      Paint()..color = DSColors.rummyCardFace,
    );

    // Border.
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final suitColor = card.isRed ? DSColors.rummySuitRed : const Color(0xFF1A1A1A);

    // Rank + suit top-left.
    _paintRankSuit(canvas, size, suitColor, topLeft: true);
    // Rank + suit bottom-right (rotated).
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(3.14159);
    _paintRankSuit(canvas, size, suitColor, topLeft: true);
    canvas.restore();

    // Center suit symbol.
    _paintCenterSymbol(canvas, size, suitColor);
  }

  void _paintRankSuit(
    Canvas canvas,
    Size size,
    Color color, {
    required bool topLeft,
  }) {
    final fontSize = size.height * 0.13;
    _drawText(
      canvas,
      card.rankLabel,
      Offset(size.width * 0.07, size.height * 0.04),
      fontSize,
      color,
      bold: true,
    );
    _drawText(
      canvas,
      card.suitSymbol,
      Offset(size.width * 0.07, size.height * 0.04 + fontSize + 1),
      fontSize * 0.85,
      color,
    );
  }

  void _paintCenterSymbol(Canvas canvas, Size size, Color color) {
    final isFaceCard = card.rank >= rankJack && card.rank <= rankKing;
    if (isFaceCard) {
      // Large initial letter for face cards.
      final label = card.rankLabel;
      _drawText(
        canvas,
        label,
        Offset(size.width * 0.5 - size.height * 0.13, size.height * 0.35),
        size.height * 0.28,
        color,
        bold: true,
        centered: true,
        width: size.width,
      );
    } else {
      // Large suit symbol.
      _drawText(
        canvas,
        card.suitSymbol,
        Offset(size.width * 0.5 - size.height * 0.18, size.height * 0.3),
        size.height * 0.38,
        color,
        centered: true,
        width: size.width,
      );
    }
  }

  // ── Joker ─────────────────────────────────────────────────────────────────

  void _paintJoker(Canvas canvas, Size size, RRect rRect) {
    // Purple-to-dark gradient.
    canvas.drawRRect(
      rRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A1B9A),
            const Color(0xFF1A237E),
          ],
        ).createShader(Offset.zero & size),
    );

    // Gold border.
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = DSColors.rummyAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Star symbol.
    _drawText(
      canvas,
      '★',
      Offset(0, size.height * 0.2),
      size.height * 0.38,
      DSColors.rummyAccent,
      centered: true,
      width: size.width,
    );

    // "JOKER" text.
    _drawText(
      canvas,
      'JKR',
      Offset(0, size.height * 0.62),
      size.height * 0.13,
      DSColors.rummyAccent,
      bold: true,
      centered: true,
      width: size.width,
    );
  }

  // ── Text helper ───────────────────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color, {
    bool bold = false,
    bool centered = false,
    double? width,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    Offset drawOffset = offset;
    if (centered && width != null) {
      drawOffset = Offset((width - painter.width) / 2, offset.dy);
    }
    painter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(CardPainter old) =>
      old.card.id != card.id ||
      old.faceUp != faceUp ||
      old.isSelected != isSelected;
}
