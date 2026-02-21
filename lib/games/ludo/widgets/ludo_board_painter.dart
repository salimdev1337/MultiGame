import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../logic/ludo_path.dart';
import '../models/ludo_enums.dart';

// ── Colour palette ────────────────────────────────────────────────────────

const _colorBg         = Color(0xFF0D0D1A);
const _colorCell       = Color(0xFF1A1A30);
const _colorBorder     = Color(0xFF252545);
const _colorFrameLight = Color(0xFF2E2E50);
const _colorFrameDark  = Color(0xFF07070F);
const _colorRed        = Color(0xFFE53935);
const _colorBlue       = Color(0xFF2979FF);
const _colorGreen      = Color(0xFF43A047);
const _colorYellow     = Color(0xFFFFD600);
const _colorGold       = Color(0xFFFFD700);
const _colorGoldDark   = Color(0xFF8B6914);

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

// Maps a track absolute position to the player zone it belongs to.
// Red: 0-12, Green: 13-25, Yellow: 26-38, Blue: 39-51
LudoPlayerColor _safeZone(int absPos) {
  if (absPos < 13) {
    return LudoPlayerColor.red;
  }
  if (absPos < 26) {
    return LudoPlayerColor.green;
  }
  if (absPos < 39) {
    return LudoPlayerColor.yellow;
  }
  return LudoPlayerColor.blue;
}

/// Paints the static Ludo board (15×15 grid).
/// Does NOT draw tokens — those are overlaid via [Stack] in the widget tree.
///
/// Set [debug] to true to overlay every cell with its grid coordinate and
/// track / home-column position index.
class LudoBoardPainter extends CustomPainter {
  const LudoBoardPainter({this.debug = false});

  final bool debug;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;

    _drawBackground(canvas, size, cell);
    _drawCrossArea(canvas, cell);
    _drawHomeColumns(canvas, cell);
    _drawSafeStars(canvas, cell);
    _drawCenter(canvas, size, cell);
    _drawCornerBases(canvas, cell);

    if (debug) {
      _drawDebugOverlay(canvas, cell);
    }
  }

  // ── Background ───────────────────────────────────────────────────────────

  void _drawBackground(Canvas canvas, Size size, double cell) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _colorBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cell * 0.1),
      ),
      Paint()
        ..color = _colorFrameLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08,
    );
  }

  // ── Cross area (arms + center 3×3) ────────────────────────────────────

  void _drawCrossArea(Canvas canvas, double cell) {
    final fillPaint = Paint()..color = _colorCell;
    final borderPaint = Paint()
      ..color = _colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        if (!((c >= 6 && c <= 8) || (r >= 6 && r <= 8))) {
          continue;
        }
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }

    // Overdraw safe-square cells with their player zone color.
    for (final entry in kTrackCoords.entries) {
      if (!kSafeSquares.contains(entry.key)) {
        continue;
      }
      final col = entry.value.$1;
      final row = entry.value.$2;
      final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
      final safeColor = _playerColor(_safeZone(entry.key));
      canvas.drawRect(
        rect,
        Paint()..color = safeColor.withValues(alpha: 0.60),
      );
      canvas.drawRect(rect, borderPaint);
    }

    // Overdraw the 4 outer-corner junction cells with their player colour.
    const cornerCells = <(int, int), LudoPlayerColor>{
      (6, 6): LudoPlayerColor.red,
      (8, 6): LudoPlayerColor.green,
      (6, 8): LudoPlayerColor.blue,
      (8, 8): LudoPlayerColor.yellow,
    };
    for (final entry in cornerCells.entries) {
      final rect = Rect.fromLTWH(
        entry.key.$1 * cell,
        entry.key.$2 * cell,
        cell,
        cell,
      );
      canvas.drawRect(
        rect,
        Paint()..color = _playerColor(entry.value).withValues(alpha: 0.85),
      );
      canvas.drawRect(rect, borderPaint);
    }
  }

  // ── Home columns ───────────────────────────────────────────────────────

  void _drawHomeColumns(Canvas canvas, double cell) {
    final borderPaint = Paint()
      ..color = _colorBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (final entry in kHomeColumnCoords.entries) {
      final color = _playerColor(entry.key);
      final coords = entry.value;

      // Compute arm bounding rect for gradient shader
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;
      for (final coord in coords) {
        final x = coord.$1 * cell;
        final y = coord.$2 * cell;
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x + cell > maxX) {
          maxX = x + cell;
        }
        if (y + cell > maxY) {
          maxY = y + cell;
        }
      }
      final armRect = Rect.fromLTRB(minX, minY, maxX, maxY);

      // Gradient direction: bright at entry, fade toward center.
      // Red enters from left, Green from top, Yellow from right, Blue from bottom.
      final (Alignment, Alignment) direction = switch (entry.key) {
        LudoPlayerColor.red    => (Alignment.centerLeft, Alignment.centerRight),
        LudoPlayerColor.green  => (Alignment.topCenter, Alignment.bottomCenter),
        LudoPlayerColor.yellow => (Alignment.centerRight, Alignment.centerLeft),
        LudoPlayerColor.blue   => (Alignment.bottomCenter, Alignment.topCenter),
      };

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: direction.$1,
          end: direction.$2,
          colors: [color, color.withValues(alpha: 0.45)],
        ).createShader(armRect);

      for (final coord in coords) {
        final rect = Rect.fromLTWH(coord.$1 * cell, coord.$2 * cell, cell, cell);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  // ── Safe-square star icons (#8, #21, #34, #47) ───────────────────────────

  void _drawSafeStars(Canvas canvas, double cell) {
    const starPositions = {8, 21, 34, 47};
    final starPaint = Paint()..color = const Color(0xFFFFF9C4);
    for (final pos in starPositions) {
      final coord = kTrackCoords[pos]!;
      final cx = (coord.$1 + 0.5) * cell;
      final cy = (coord.$2 + 0.5) * cell;

      // Glow halo behind star
      canvas.drawCircle(
        Offset(cx, cy),
        cell * 0.38,
        Paint()
          ..color = _playerColor(_safeZone(pos)).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawPath(_starPath(cx, cy, cell * 0.36, cell * 0.15), starPaint);
    }
  }

  // ── Center 3×3 — four coloured triangles + gold finish ────────────────

  void _drawCenter(Canvas canvas, Size size, double cell) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final centre = Offset(cx, cy);

    final r = cell * 1.5;
    final hw = cell * 1.05;

    final triangles = <(LudoPlayerColor, double)>[
      (LudoPlayerColor.red,    math.pi),
      (LudoPlayerColor.green,  -math.pi / 2),
      (LudoPlayerColor.yellow, 0),
      (LudoPlayerColor.blue,   math.pi / 2),
    ];

    for (final (colorEnum, angle) in triangles) {
      final playerColor = _playerColor(colorEnum);
      final tip = Offset(
        cx + math.cos(angle) * r,
        cy + math.sin(angle) * r,
      );
      final left = Offset(
        cx + math.cos(angle + math.pi / 2) * hw,
        cy + math.sin(angle + math.pi / 2) * hw,
      );
      final right = Offset(
        cx + math.cos(angle - math.pi / 2) * hw,
        cy + math.sin(angle - math.pi / 2) * hw,
      );
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();

      // Compute bounding rect for gradient shader
      final minX = math.min(tip.dx, math.min(left.dx, right.dx));
      final minY = math.min(tip.dy, math.min(left.dy, right.dy));
      final maxX = math.max(tip.dx, math.max(left.dx, right.dx));
      final maxY = math.max(tip.dy, math.max(left.dy, right.dy));
      final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);

      // Gradient: from board-center side (slightly transparent) toward tip (full)
      final (Alignment, Alignment) gradAlign = switch (colorEnum) {
        LudoPlayerColor.red    => (Alignment.centerRight, Alignment.centerLeft),
        LudoPlayerColor.green  => (Alignment.bottomCenter, Alignment.topCenter),
        LudoPlayerColor.yellow => (Alignment.centerLeft, Alignment.centerRight),
        LudoPlayerColor.blue   => (Alignment.topCenter, Alignment.bottomCenter),
      };

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: gradAlign.$1,
            end: gradAlign.$2,
            colors: [playerColor.withValues(alpha: 0.9), playerColor],
          ).createShader(bounds),
      );
    }

    // Gold center — glow layer
    canvas.drawCircle(
      centre,
      cell * 0.55,
      Paint()
        ..color = _colorGold.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Gold center — radial gradient fill
    final circleRect = Rect.fromCircle(center: centre, radius: cell * 0.38);
    canvas.drawCircle(
      centre,
      cell * 0.38,
      Paint()
        ..shader = const RadialGradient(
          colors: [_colorGold, _colorGoldDark],
        ).createShader(circleRect),
    );

    // Gold center — ring
    canvas.drawCircle(
      centre,
      cell * 0.38,
      Paint()
        ..color = _colorGold.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06,
    );
  }

  // ── Corner bases ───────────────────────────────────────────────────────

  void _drawCornerBases(Canvas canvas, double cell) {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);

    final bases = <LudoPlayerColor, Rect>{
      LudoPlayerColor.red:    Rect.fromLTWH(0,        0,        6 * cell, 6 * cell),
      LudoPlayerColor.green:  Rect.fromLTWH(9 * cell, 0,        6 * cell, 6 * cell),
      LudoPlayerColor.blue:   Rect.fromLTWH(0,        9 * cell, 6 * cell, 6 * cell),
      LudoPlayerColor.yellow: Rect.fromLTWH(9 * cell, 9 * cell, 6 * cell, 6 * cell),
    };

    for (final entry in bases.entries) {
      final color = _playerColor(entry.key);
      final rect = entry.value;

      // 1. Radial gradient background
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.topLeft,
            radius: 1.6,
            colors: [
              Color.lerp(color, white, 0.25)!,
              color,
              Color.lerp(color, black, 0.40)!,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(rect),
      );

      // 2. Inner circle — dark fill
      final baseCentre = rect.center;
      final circleRadius = cell * 2.25;
      canvas.drawCircle(baseCentre, circleRadius, Paint()..color = _colorBg);

      // 3. Inner circle — outer glow ring
      canvas.drawCircle(
        baseCentre,
        circleRadius,
        Paint()
          ..color = color.withValues(alpha: 0.60)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.18
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // 3b. Inner circle — sharp ring
      canvas.drawCircle(
        baseCentre,
        circleRadius,
        Paint()
          ..color = color.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.10,
      );

      // 4. Slot circles
      for (final coord in kBaseSlotCoords[entry.key]!) {
        final slotCx = (coord.$1 + 0.5) * cell;
        final slotCy = (coord.$2 + 0.5) * cell;
        final slotCenter = Offset(slotCx, slotCy);
        final slotR = cell * 0.37;

        // Dark fill
        canvas.drawCircle(
          slotCenter,
          slotR,
          Paint()..color = const Color(0xFF0D0D1A),
        );

        // Blurred glow border
        canvas.drawCircle(
          slotCenter,
          slotR,
          Paint()
            ..color = color.withValues(alpha: 0.50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.12
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        // Sharp border
        canvas.drawCircle(
          slotCenter,
          slotR,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.12,
        );
      }

      // 5. Base outer border
      canvas.drawRect(
        rect,
        Paint()
          ..color = _colorFrameDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  Path _starPath(double cx, double cy, double outerR, double innerR) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  // ── Debug overlay ─────────────────────────────────────────────────────────

  void _drawDebugOverlay(Canvas canvas, double cell) {
    // Build reverse map: (col,row) → track position.
    final trackByCoord = <(int, int), int>{};
    for (final entry in kTrackCoords.entries) {
      trackByCoord[(entry.value.$1, entry.value.$2)] = entry.key;
    }

    // Build reverse map: (col,row) → home-column step label per color.
    final homeByCoord = <(int, int), String>{};
    for (final entry in kHomeColumnCoords.entries) {
      final colorInitial = entry.key.name[0].toUpperCase();
      for (int i = 0; i < entry.value.length; i++) {
        final coord = entry.value[i];
        homeByCoord[(coord.$1, coord.$2)] = '$colorInitial${i + 1}';
      }
    }

    final bgPaint = Paint()..color = const Color(0xAA000000);

    for (int r = 0; r < 15; r++) {
      for (int c = 0; c < 15; c++) {
        final cellRect = Rect.fromLTWH(c * cell, r * cell, cell, cell);

        final coordLabel = '$c,$r';

        final trackPos = trackByCoord[(c, r)];
        final homeLabel = homeByCoord[(c, r)];
        final posLabel = trackPos != null
            ? '#$trackPos'
            : (homeLabel ?? '');

        final fontSize = (cell * 0.22).clamp(6.0, 11.0);

        canvas.drawRect(
          Rect.fromLTWH(
            cellRect.left,
            cellRect.bottom - cell * 0.48,
            cell,
            cell * 0.48,
          ),
          bgPaint,
        );

        _drawText(
          canvas,
          coordLabel,
          Offset(cellRect.left + cell * 0.5, cellRect.bottom - cell * 0.42),
          fontSize,
          const Color(0xFFFFFFFF),
        );

        if (posLabel.isNotEmpty) {
          _drawText(
            canvas,
            posLabel,
            Offset(cellRect.left + cell * 0.5, cellRect.bottom - cell * 0.18),
            fontSize * 1.1,
            const Color(0xFFFFFF00),
          );
        }
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
      ..addText(text);
    final paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: fontSize * 6));
    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - paragraph.width / 2, center.dy - paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(LudoBoardPainter oldDelegate) => oldDelegate.debug != debug;
}
