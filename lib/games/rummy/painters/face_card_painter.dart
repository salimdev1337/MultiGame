import 'package:flutter/rendering.dart';

import '../models/playing_card.dart';

const _kRed = Color(0xFFCC0000);
const _kBlack = Color(0xFF1A1A1A);
const _kGold = Color(0xFFDAA520);
const _kBlue = Color(0xFF2255AA);
const _kRobeRed = Color(0xFFCC3333);
const _kSkinTone = Color(0xFFF5D6B8);

void paintFaceCard(Canvas canvas, Size size, PlayingCard card) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final isRed = card.isRed;
  final accent = isRed ? _kRed : _kBlack;
  final robe = isRed ? _kRobeRed : _kBlue;

  canvas.save();
  canvas.translate(cx, cy);

  switch (card.rank) {
    case rankJack:
      _drawJack(canvas, size, robe, accent);
    case rankQueen:
      _drawQueen(canvas, size, robe, accent);
    case rankKing:
      _drawKing(canvas, size, robe, accent);
  }

  canvas.restore();
}

void _drawJack(Canvas canvas, Size s, Color robe, Color accent) {
  final w = s.width * 0.5;
  final h = s.height * 0.35;

  // Body/robe
  final bodyPath = Path()
    ..moveTo(-w * 0.35, h * 0.1)
    ..lineTo(-w * 0.45, h * 0.9)
    ..lineTo(w * 0.45, h * 0.9)
    ..lineTo(w * 0.35, h * 0.1)
    ..close();
  canvas.drawPath(bodyPath, Paint()..color = robe);
  canvas.drawPath(
    bodyPath,
    Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 0.8,
  );

  // Collar detail
  final collarPath = Path()
    ..moveTo(-w * 0.25, h * 0.1)
    ..lineTo(0, h * 0.3)
    ..lineTo(w * 0.25, h * 0.1);
  canvas.drawPath(
    collarPath,
    Paint()..color = _kGold..style = PaintingStyle.stroke..strokeWidth = 1.5,
  );

  // Head
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, -h * 0.15), width: w * 0.4, height: h * 0.45),
    Paint()..color = _kSkinTone,
  );

  // Hat (feathered cap)
  final hatPath = Path()
    ..moveTo(-w * 0.3, -h * 0.3)
    ..quadraticBezierTo(-w * 0.1, -h * 0.7, w * 0.3, -h * 0.45)
    ..lineTo(w * 0.25, -h * 0.3)
    ..quadraticBezierTo(0, -h * 0.35, -w * 0.3, -h * 0.3)
    ..close();
  canvas.drawPath(hatPath, Paint()..color = robe);
  canvas.drawPath(
    hatPath,
    Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 0.6,
  );

  // Feather
  final featherPath = Path()
    ..moveTo(w * 0.15, -h * 0.45)
    ..quadraticBezierTo(w * 0.5, -h * 0.8, w * 0.2, -h * 0.9);
  canvas.drawPath(
    featherPath,
    Paint()..color = _kGold..style = PaintingStyle.stroke..strokeWidth = 1.2,
  );

  // Sword (jack holds a sword)
  canvas.drawLine(
    Offset(w * 0.3, -h * 0.1),
    Offset(w * 0.3, h * 0.8),
    Paint()..color = const Color(0xFF888888)..strokeWidth = 1.5,
  );
  // Sword guard
  canvas.drawLine(
    Offset(w * 0.15, h * 0.05),
    Offset(w * 0.45, h * 0.05),
    Paint()..color = _kGold..strokeWidth = 2,
  );
}

void _drawQueen(Canvas canvas, Size s, Color robe, Color accent) {
  final w = s.width * 0.5;
  final h = s.height * 0.35;

  // Dress/robe - wider at bottom
  final dressPath = Path()
    ..moveTo(-w * 0.3, h * 0.05)
    ..quadraticBezierTo(-w * 0.5, h * 0.5, -w * 0.55, h * 0.9)
    ..lineTo(w * 0.55, h * 0.9)
    ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.3, h * 0.05)
    ..close();
  canvas.drawPath(dressPath, Paint()..color = robe);
  canvas.drawPath(
    dressPath,
    Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 0.8,
  );

  // Necklace / collar
  canvas.drawArc(
    Rect.fromCenter(center: Offset(0, h * 0.1), width: w * 0.4, height: h * 0.15),
    0, 3.14,
    false,
    Paint()..color = _kGold..style = PaintingStyle.stroke..strokeWidth = 1.5,
  );

  // Head
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, -h * 0.2), width: w * 0.38, height: h * 0.45),
    Paint()..color = _kSkinTone,
  );

  // Crown
  final crownPath = Path()
    ..moveTo(-w * 0.25, -h * 0.38)
    ..lineTo(-w * 0.28, -h * 0.6)
    ..lineTo(-w * 0.12, -h * 0.5)
    ..lineTo(0, -h * 0.7)
    ..lineTo(w * 0.12, -h * 0.5)
    ..lineTo(w * 0.28, -h * 0.6)
    ..lineTo(w * 0.25, -h * 0.38)
    ..close();
  canvas.drawPath(crownPath, Paint()..color = _kGold);
  canvas.drawPath(
    crownPath,
    Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 0.8,
  );

  // Crown jewels
  canvas.drawCircle(Offset(0, -h * 0.55), w * 0.04, Paint()..color = _kRed);
  canvas.drawCircle(Offset(-w * 0.15, -h * 0.48), w * 0.03, Paint()..color = _kBlue);
  canvas.drawCircle(Offset(w * 0.15, -h * 0.48), w * 0.03, Paint()..color = _kBlue);

  // Flower (queen holds a flower)
  final flowerCenter = Offset(-w * 0.3, h * 0.3);
  for (var i = 0; i < 5; i++) {
    final angle = i * 1.257;
    final petalX = flowerCenter.dx + w * 0.08 * _cos(angle);
    final petalY = flowerCenter.dy + w * 0.08 * _sin(angle);
    canvas.drawCircle(Offset(petalX, petalY), w * 0.05, Paint()..color = accent);
  }
  canvas.drawCircle(flowerCenter, w * 0.04, Paint()..color = _kGold);
}

void _drawKing(Canvas canvas, Size s, Color robe, Color accent) {
  final w = s.width * 0.5;
  final h = s.height * 0.35;

  // Body/robe
  final bodyPath = Path()
    ..moveTo(-w * 0.4, h * 0.05)
    ..lineTo(-w * 0.5, h * 0.9)
    ..lineTo(w * 0.5, h * 0.9)
    ..lineTo(w * 0.4, h * 0.05)
    ..close();
  canvas.drawPath(bodyPath, Paint()..color = robe);

  // Robe border / ermine trim
  canvas.drawLine(
    Offset(-w * 0.4, h * 0.05),
    Offset(-w * 0.5, h * 0.9),
    Paint()..color = _kGold..strokeWidth = 2,
  );
  canvas.drawLine(
    Offset(w * 0.4, h * 0.05),
    Offset(w * 0.5, h * 0.9),
    Paint()..color = _kGold..strokeWidth = 2,
  );

  // Head
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, -h * 0.2), width: w * 0.42, height: h * 0.48),
    Paint()..color = _kSkinTone,
  );

  // Beard
  final beardPath = Path()
    ..moveTo(-w * 0.15, -h * 0.05)
    ..quadraticBezierTo(0, h * 0.15, w * 0.15, -h * 0.05);
  canvas.drawPath(beardPath, Paint()..color = const Color(0xFF8B7355));

  // Crown (bigger than queen's)
  final crownPath = Path()
    ..moveTo(-w * 0.3, -h * 0.38)
    ..lineTo(-w * 0.32, -h * 0.65)
    ..lineTo(-w * 0.16, -h * 0.52)
    ..lineTo(0, -h * 0.75)
    ..lineTo(w * 0.16, -h * 0.52)
    ..lineTo(w * 0.32, -h * 0.65)
    ..lineTo(w * 0.3, -h * 0.38)
    ..close();
  canvas.drawPath(crownPath, Paint()..color = _kGold);
  canvas.drawPath(
    crownPath,
    Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 1,
  );

  // Crown jewels
  canvas.drawCircle(Offset(0, -h * 0.58), w * 0.05, Paint()..color = _kRed);
  canvas.drawCircle(Offset(-w * 0.2, -h * 0.5), w * 0.035, Paint()..color = _kBlue);
  canvas.drawCircle(Offset(w * 0.2, -h * 0.5), w * 0.035, Paint()..color = _kBlue);

  // Cross on crown top
  canvas.drawLine(
    Offset(0, -h * 0.75),
    Offset(0, -h * 0.88),
    Paint()..color = _kGold..strokeWidth = 1.5,
  );
  canvas.drawLine(
    Offset(-w * 0.06, -h * 0.82),
    Offset(w * 0.06, -h * 0.82),
    Paint()..color = _kGold..strokeWidth = 1.5,
  );

  // Scepter
  canvas.drawLine(
    Offset(w * 0.35, -h * 0.3),
    Offset(w * 0.35, h * 0.7),
    Paint()..color = _kGold..strokeWidth = 2,
  );
  canvas.drawCircle(Offset(w * 0.35, -h * 0.35), w * 0.06, Paint()..color = _kGold);
}

void paintJokerFigure(Canvas canvas, Size size) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  final w = size.width * 0.5;
  final h = size.height * 0.3;

  canvas.save();
  canvas.translate(cx, cy);

  // Body
  final bodyPath = Path()
    ..moveTo(-w * 0.3, h * 0.1)
    ..lineTo(-w * 0.4, h * 0.9)
    ..lineTo(w * 0.4, h * 0.9)
    ..lineTo(w * 0.3, h * 0.1)
    ..close();
  canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF4444AA));

  // Diamond pattern on body
  for (var i = 0; i < 3; i++) {
    final dy = h * (0.3 + i * 0.2);
    final diamond = Path()
      ..moveTo(0, dy - h * 0.06)
      ..lineTo(w * 0.06, dy)
      ..lineTo(0, dy + h * 0.06)
      ..lineTo(-w * 0.06, dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = _kGold);
  }

  // Head
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, -h * 0.15), width: w * 0.38, height: h * 0.42),
    Paint()..color = _kSkinTone,
  );

  // Jester hat (3 points)
  final hatColors = [_kRed, _kGold, const Color(0xFF2255AA)];
  final hatPoints = [
    (tipX: -w * 0.45, tipY: -h * 0.85, baseX: -w * 0.2),
    (tipX: 0.0, tipY: -h * 0.95, baseX: 0.0),
    (tipX: w * 0.45, tipY: -h * 0.85, baseX: w * 0.2),
  ];
  final baseY = -h * 0.35;

  for (var i = 0; i < 3; i++) {
    final p = hatPoints[i];
    final leftBase = i == 0 ? -w * 0.25 : hatPoints[i - 1].baseX;
    final rightBase = i == 2 ? w * 0.25 : hatPoints[i + 1].baseX;
    final pointPath = Path()
      ..moveTo(leftBase, baseY)
      ..quadraticBezierTo(p.tipX * 0.8, p.tipY, p.tipX, p.tipY)
      ..quadraticBezierTo(p.tipX * 0.8, p.tipY, rightBase, baseY)
      ..close();
    canvas.drawPath(pointPath, Paint()..color = hatColors[i]);

    // Bell at tip
    canvas.drawCircle(
      Offset(p.tipX, p.tipY),
      w * 0.05,
      Paint()..color = _kGold,
    );
  }

  // Smile
  canvas.drawArc(
    Rect.fromCenter(center: Offset(0, -h * 0.05), width: w * 0.2, height: h * 0.12),
    0, 3.14,
    false,
    Paint()..color = _kRed..style = PaintingStyle.stroke..strokeWidth = 1.2,
  );

  canvas.restore();
}

double _cos(double radians) {
  // Simple cos approximation for small petal layout
  const table = [1.0, 0.309, -0.809, -0.809, 0.309];
  final idx = (radians / 1.257).round() % 5;
  return table[idx];
}

double _sin(double radians) {
  const table = [0.0, 0.951, 0.588, -0.588, -0.951];
  final idx = (radians / 1.257).round() % 5;
  return table[idx];
}
