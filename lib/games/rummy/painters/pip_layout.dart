import 'package:flutter/rendering.dart';

import '../models/playing_card.dart';

typedef PipPos = ({double x, double y, bool flip});

const Map<int, List<PipPos>> kPipPositions = {
  1: [(x: 0.5, y: 0.5, flip: false)],
  2: [(x: 0.5, y: 0.22, flip: false), (x: 0.5, y: 0.78, flip: true)],
  3: [
    (x: 0.5, y: 0.22, flip: false),
    (x: 0.5, y: 0.5, flip: false),
    (x: 0.5, y: 0.78, flip: true),
  ],
  4: [
    (x: 0.3, y: 0.22, flip: false),
    (x: 0.7, y: 0.22, flip: false),
    (x: 0.3, y: 0.78, flip: true),
    (x: 0.7, y: 0.78, flip: true),
  ],
  5: [
    (x: 0.3, y: 0.22, flip: false),
    (x: 0.7, y: 0.22, flip: false),
    (x: 0.5, y: 0.5, flip: false),
    (x: 0.3, y: 0.78, flip: true),
    (x: 0.7, y: 0.78, flip: true),
  ],
  6: [
    (x: 0.3, y: 0.22, flip: false),
    (x: 0.7, y: 0.22, flip: false),
    (x: 0.3, y: 0.5, flip: false),
    (x: 0.7, y: 0.5, flip: false),
    (x: 0.3, y: 0.78, flip: true),
    (x: 0.7, y: 0.78, flip: true),
  ],
  7: [
    (x: 0.3, y: 0.22, flip: false),
    (x: 0.7, y: 0.22, flip: false),
    (x: 0.5, y: 0.36, flip: false),
    (x: 0.3, y: 0.5, flip: false),
    (x: 0.7, y: 0.5, flip: false),
    (x: 0.3, y: 0.78, flip: true),
    (x: 0.7, y: 0.78, flip: true),
  ],
  8: [
    (x: 0.3, y: 0.22, flip: false),
    (x: 0.7, y: 0.22, flip: false),
    (x: 0.5, y: 0.36, flip: false),
    (x: 0.3, y: 0.5, flip: false),
    (x: 0.7, y: 0.5, flip: false),
    (x: 0.5, y: 0.64, flip: true),
    (x: 0.3, y: 0.78, flip: true),
    (x: 0.7, y: 0.78, flip: true),
  ],
  9: [
    (x: 0.3, y: 0.2, flip: false),
    (x: 0.7, y: 0.2, flip: false),
    (x: 0.3, y: 0.38, flip: false),
    (x: 0.7, y: 0.38, flip: false),
    (x: 0.5, y: 0.5, flip: false),
    (x: 0.3, y: 0.62, flip: true),
    (x: 0.7, y: 0.62, flip: true),
    (x: 0.3, y: 0.8, flip: true),
    (x: 0.7, y: 0.8, flip: true),
  ],
  10: [
    (x: 0.3, y: 0.2, flip: false),
    (x: 0.7, y: 0.2, flip: false),
    (x: 0.5, y: 0.32, flip: false),
    (x: 0.3, y: 0.38, flip: false),
    (x: 0.7, y: 0.38, flip: false),
    (x: 0.3, y: 0.62, flip: true),
    (x: 0.7, y: 0.62, flip: true),
    (x: 0.5, y: 0.68, flip: true),
    (x: 0.3, y: 0.8, flip: true),
    (x: 0.7, y: 0.8, flip: true),
  ],
};

void drawSuitSymbol(
  Canvas canvas,
  int suit,
  Offset center,
  double size, {
  bool flip = false,
}) {
  final paint = Paint()
    ..color = (suit == suitHearts || suit == suitDiamonds)
        ? const Color(0xFFCC0000)
        : const Color(0xFF1A1A1A)
    ..style = PaintingStyle.fill;

  canvas.save();
  canvas.translate(center.dx, center.dy);
  if (flip) {
    canvas.scale(1, -1);
  }

  final half = size / 2;

  switch (suit) {
    case suitHearts:
      _drawHeart(canvas, half, paint);
    case suitDiamonds:
      _drawDiamond(canvas, half, paint);
    case suitSpades:
      _drawSpade(canvas, half, paint);
    case suitClubs:
      _drawClub(canvas, half, paint);
  }

  canvas.restore();
}

void _drawHeart(Canvas canvas, double h, Paint paint) {
  final path = Path()
    ..moveTo(0, h * 0.8)
    ..cubicTo(-h * 0.1, h * 0.5, -h * 1.2, h * 0.2, -h * 0.7, -h * 0.3)
    ..cubicTo(-h * 0.35, -h * 0.7, 0, -h * 0.5, 0, -h * 0.2)
    ..cubicTo(0, -h * 0.5, h * 0.35, -h * 0.7, h * 0.7, -h * 0.3)
    ..cubicTo(h * 1.2, h * 0.2, h * 0.1, h * 0.5, 0, h * 0.8)
    ..close();
  canvas.drawPath(path, paint);
}

void _drawDiamond(Canvas canvas, double h, Paint paint) {
  final path = Path()
    ..moveTo(0, -h)
    ..lineTo(h * 0.7, 0)
    ..lineTo(0, h)
    ..lineTo(-h * 0.7, 0)
    ..close();
  canvas.drawPath(path, paint);
}

void _drawSpade(Canvas canvas, double h, Paint paint) {
  final path = Path()
    ..moveTo(0, -h)
    ..cubicTo(-h * 1.4, -h * 0.1, -h * 0.2, h * 0.5, 0, h * 0.2)
    ..cubicTo(h * 0.1, h * 0.5, h * 1.4, -h * 0.1, 0, -h)
    ..close();
  canvas.drawPath(path, paint);

  final stemPath = Path()
    ..moveTo(-h * 0.15, h * 0.3)
    ..quadraticBezierTo(-h * 0.25, h * 0.9, -h * 0.35, h)
    ..lineTo(h * 0.35, h)
    ..quadraticBezierTo(h * 0.25, h * 0.9, h * 0.15, h * 0.3)
    ..close();
  canvas.drawPath(stemPath, paint);
}

void _drawClub(Canvas canvas, double h, Paint paint) {
  final r = h * 0.38;
  canvas.drawCircle(Offset(0, -h * 0.45), r, paint);
  canvas.drawCircle(Offset(-h * 0.4, h * 0.05), r, paint);
  canvas.drawCircle(Offset(h * 0.4, h * 0.05), r, paint);

  final stemPath = Path()
    ..moveTo(-h * 0.12, h * 0.1)
    ..quadraticBezierTo(-h * 0.25, h * 0.8, -h * 0.35, h)
    ..lineTo(h * 0.35, h)
    ..quadraticBezierTo(h * 0.25, h * 0.8, h * 0.12, h * 0.1)
    ..close();
  canvas.drawPath(stemPath, paint);
}
