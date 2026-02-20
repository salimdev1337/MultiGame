import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../logic/ludo_path.dart';
import '../models/ludo_enums.dart';

// ── Colour palette (no flutter/material.dart import) ─────────────────────

const _colorRed = Color(0xFFE53935);
const _colorBlue = Color(0xFF2196F3);
const _colorGreen = Color(0xFF43A047);
const _colorYellow = Color(0xFFFFD700);
const _colorWhite = Color(0xFFFFFFFF);
const _colorTrack = Color(0xFFF5F5F5);
const _colorBorder = Color(0xFF9E9E9E);
const _colorSafe = Color(0xFFB2DFDB);
const _colorCentre = Color(0xFF7E57C2);

Color _playerColor(LudoPlayerColor c) {
  switch (c) {
    case LudoPlayerColor.red:
      return _colorRed;
    case LudoPlayerColor.blue:
      return _colorBlue;
    case LudoPlayerColor.green:
      return _colorGreen;
    case LudoPlayerColor.yellow:
      return _colorYellow;
  }
}

/// Paints the static Ludo board (15×15 grid).
/// Does NOT draw tokens — those are overlaid via [Stack] in the widget tree.
class LudoBoardPainter extends CustomPainter {
  const LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;

    _drawBackground(canvas, size, cell);
    _drawCornerBases(canvas, cell);
    _drawTrackSquares(canvas, cell);
    _drawHomeColumns(canvas, cell);
    _drawCentreStar(canvas, size, cell);
    _drawGrid(canvas, size, cell);
  }

  void _drawBackground(Canvas canvas, Size size, double cell) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _colorWhite,
    );
  }

  void _drawCornerBases(Canvas canvas, double cell) {
    final corners = <LudoPlayerColor, Rect>{
      LudoPlayerColor.red: Rect.fromLTWH(0, 9 * cell, 6 * cell, 6 * cell),
      LudoPlayerColor.blue: Rect.fromLTWH(9 * cell, 0, 6 * cell, 6 * cell),
      LudoPlayerColor.green: Rect.fromLTWH(9 * cell, 9 * cell, 6 * cell, 6 * cell),
      LudoPlayerColor.yellow: Rect.fromLTWH(0, 0, 6 * cell, 6 * cell),
    };

    for (final entry in corners.entries) {
      final paint = Paint()..color = _playerColor(entry.key);
      canvas.drawRect(entry.value, paint);

      // Inner white slot area.
      final inner = entry.value.deflate(cell * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inner, Radius.circular(cell * 0.3)),
        Paint()..color = _colorWhite.withValues(alpha: 0.85),
      );

      // Four token circle guides.
      final slotCoords = kBaseSlotCoords[entry.key]!;
      for (final coord in slotCoords) {
        final cx = (coord.$1 + 0.5) * cell;
        final cy = (coord.$2 + 0.5) * cell;
        canvas.drawCircle(
          Offset(cx, cy),
          cell * 0.35,
          Paint()..color = _playerColor(entry.key).withValues(alpha: 0.3),
        );
      }
    }
  }

  void _drawTrackSquares(Canvas canvas, double cell) {
    final trackPaint = Paint()..color = _colorTrack;
    final safePaint = Paint()..color = _colorSafe;
    final borderPaint = Paint()
      ..color = _colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final entry in kTrackCoords.entries) {
      final absPos = entry.key;
      final col = entry.value.$1;
      final row = entry.value.$2;
      final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);

      canvas.drawRect(rect, kSafeSquares.contains(absPos) ? safePaint : trackPaint);
      canvas.drawRect(rect, borderPaint);

      // Mark safe squares with a small star.
      if (kSafeSquares.contains(absPos)) {
        _drawSmallStar(canvas, Offset(col * cell + cell / 2, row * cell + cell / 2), cell * 0.25);
      }
    }
  }

  void _drawHomeColumns(Canvas canvas, double cell) {
    final borderPaint = Paint()
      ..color = _colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final entry in kHomeColumnCoords.entries) {
      final color = entry.key;
      final colPaint = Paint()
        ..color = _playerColor(color).withValues(alpha: 0.45);

      for (final coord in entry.value) {
        final rect = Rect.fromLTWH(
          coord.$1 * cell,
          coord.$2 * cell,
          cell,
          cell,
        );
        canvas.drawRect(rect, colPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawCentreStar(Canvas canvas, Size size, double cell) {
    // 6×6 centre at cols/rows 6-8 (the 3×3 core around (7,7)).
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = cell * 1.4;

    final bg = Paint()..color = _colorCentre;
    canvas.drawCircle(centre, radius, bg);

    // Draw a 4-pointed star from the player colours.
    _drawCentreArrows(canvas, centre, cell);
  }

  void _drawCentreArrows(Canvas canvas, Offset centre, double cell) {
    // Four triangular arrows pointing inward from each home column colour.
    final arrows = <(LudoPlayerColor, double)>[
      (LudoPlayerColor.red, math.pi),        // arrow from left → right
      (LudoPlayerColor.blue, math.pi / 2),   // from top → bottom
      (LudoPlayerColor.green, 0),            // from right → left
      (LudoPlayerColor.yellow, -math.pi / 2), // from bottom → top
    ];

    for (final (color, angle) in arrows) {
      final paint = Paint()..color = _playerColor(color);
      final tip = Offset(
        centre.dx + math.cos(angle) * cell * 1.1,
        centre.dy + math.sin(angle) * cell * 1.1,
      );
      final left = Offset(
        centre.dx + math.cos(angle + math.pi / 2) * cell * 0.45,
        centre.dy + math.sin(angle + math.pi / 2) * cell * 0.45,
      );
      final right = Offset(
        centre.dx + math.cos(angle - math.pi / 2) * cell * 0.45,
        centre.dy + math.sin(angle - math.pi / 2) * cell * 0.45,
      );
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawSmallStar(Canvas canvas, Offset centre, double radius) {
    final starPaint = Paint()
      ..color = const Color(0xFF26A69A)
      ..style = PaintingStyle.fill;
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isOdd ? radius * 0.4 : radius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = centre.dx + r * math.cos(angle);
      final y = centre.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, starPaint);
  }

  void _drawGrid(Canvas canvas, Size size, double cell) {
    final paint = Paint()
      ..color = _colorBorder.withValues(alpha: 0.4)
      ..strokeWidth = 0.3;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
        Offset(i * cell, 0),
        Offset(i * cell, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cell),
        Offset(size.width, i * cell),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LudoBoardPainter oldDelegate) => false;
}
