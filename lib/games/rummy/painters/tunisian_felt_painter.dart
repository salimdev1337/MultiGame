import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:multigame/design_system/ds_colors.dart';

/// Paints a Tunisian zellige-patterned felt background:
/// green base, 8-pointed star + cross tile pattern, vignette edges.
class TunisianFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Green felt base
    canvas.drawRect(Offset.zero & size, Paint()..color = DSColors.rummyFelt);

    // Zellige tile pattern overlay
    _paintZelligePattern(canvas, size);

    // Vignette (dark edges)
    _paintVignette(canvas, size);
  }

  void _paintZelligePattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DSColors.rummyPrimary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const tileSize = 80.0;
    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (var row = -1; row < rows; row++) {
      for (var col = -1; col < cols; col++) {
        final cx = col * tileSize + tileSize / 2;
        final cy = row * tileSize + tileSize / 2;
        _paintStarTile(canvas, cx, cy, tileSize, paint);
      }
    }
  }

  /// Paints one 8-pointed star with cross pattern at the given center.
  void _paintStarTile(
    Canvas canvas,
    double cx,
    double cy,
    double tileSize,
    Paint paint,
  ) {
    final r = tileSize * 0.38;
    final innerR = r * 0.45;

    // 8-pointed star: alternate between outer and inner radius
    final starPath = Path();
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = cx + math.cos(angle) * radius;
      final y = cy + math.sin(angle) * radius;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, paint);

    // Cross lines through center
    final crossR = tileSize * 0.42;
    canvas.drawLine(Offset(cx - crossR, cy), Offset(cx + crossR, cy), paint);
    canvas.drawLine(Offset(cx, cy - crossR), Offset(cx, cy + crossR), paint);

    // Small inner circle
    canvas.drawCircle(Offset(cx, cy), innerR * 0.5, paint);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(
      size.width * size.width / 4 + size.height * size.height / 4,
    );

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0x00000000),
        const Color(0x00000000),
        const Color(0x40000000),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: maxRadius);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(TunisianFeltPainter old) => false;
}
