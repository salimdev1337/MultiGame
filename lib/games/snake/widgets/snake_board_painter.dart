import 'package:flutter/rendering.dart';

/// Draws the full snake game board (grid lines, snake segments, food) on a
/// single [Canvas] pass.  The painter accepts both the [previousSnake] and
/// [currentSnake] positions together with an interpolation factor [t]
/// (0.0 = start of tick, 1.0 = end of tick).  The [Ticker] in
/// [SnakeBoardWidget] drives [t] at 60 FPS between logical game ticks so the
/// snake appears to glide smoothly rather than snapping one cell per tick.
class SnakeBoardPainter extends CustomPainter {
  final List<Offset> previousSnake;
  final List<Offset> currentSnake;
  final Offset food;
  final double t;
  final int gridSize;

  const SnakeBoardPainter({
    required this.previousSnake,
    required this.currentSnake,
    required this.food,
    required this.t,
    required this.gridSize,
  });

  @override
  bool shouldRepaint(SnakeBoardPainter old) =>
      old.t != t ||
      old.currentSnake != currentSnake ||
      old.food != food;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    _drawGrid(canvas, size, cellW, cellH);
    _drawSnake(canvas, cellW, cellH);
    _drawFood(canvas, cellW, cellH);
  }

  void _drawGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final paint = Paint()
      ..color = const Color(0xFF55ff00).withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        paint,
      );
    }
  }

  void _drawSnake(Canvas canvas, double cellW, double cellH) {
    final len = currentSnake.length;
    if (len == 0) return;

    for (int i = 0; i < len; i++) {
      final to = currentSnake[i];
      final rawFrom = (i < previousSnake.length) ? previousSnake[i] : to;
      // Skip interpolation for wrap-around teleports (segment jumped > half grid)
      final from = _isTeleport(rawFrom, to) ? to : rawFrom;
      final lerped = Offset.lerp(from, to, t)!;

      final isHead = i == 0;
      // Body segments fade slightly toward the tail for a gradient effect
      final brightness =
          isHead ? 1.0 : (1.0 - (i / len) * 0.35).clamp(0.65, 1.0);

      final r = (0x55 * brightness).round().clamp(0, 255);
      final g = (0xff * brightness).round().clamp(0, 255);
      final segPaint = Paint()
        ..color = Color.fromARGB(255, r, g, 0)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(
        lerped.dx * cellW + 1,
        lerped.dy * cellH + 1,
        cellW - 2,
        cellH - 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(isHead ? 5.0 : 3.0)),
        segPaint,
      );

      // Soft glow on the head
      if (isHead) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(lerped.dx * cellW, lerped.dy * cellH, cellW, cellH),
            const Radius.circular(6),
          ),
          Paint()
            ..color = const Color(0xFF55ff00).withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  void _drawFood(Canvas canvas, double cellW, double cellH) {
    final fx = food.dx * cellW + cellW / 2;
    final fy = food.dy * cellH + cellH / 2;

    // Glow ring
    canvas.drawCircle(
      Offset(fx, fy),
      cellW * 0.55,
      Paint()
        ..color = const Color(0xFF00C2FF).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Core dot
    canvas.drawCircle(
      Offset(fx, fy),
      cellW * 0.4,
      Paint()..color = const Color(0xFF00C2FF),
    );
  }

  /// Returns true when the movement between [from] and [to] spans more than
  /// half the grid — indicating a wrap-around teleport that should not be
  /// interpolated (it would draw the segment sliding across the whole board).
  bool _isTeleport(Offset from, Offset to) =>
      (to.dx - from.dx).abs() > gridSize / 2 ||
      (to.dy - from.dy).abs() > gridSize / 2;
}
