import 'package:flutter/material.dart';

import '../models/ludo_enums.dart';
import '../models/ludo_token.dart';

// ── Player colours ────────────────────────────────────────────────────────

Color _tokenColor(LudoPlayerColor c) {
  switch (c) {
    case LudoPlayerColor.red:
      return const Color(0xFFE53935);
    case LudoPlayerColor.blue:
      return const Color(0xFF2979FF);
    case LudoPlayerColor.green:
      return const Color(0xFF43A047);
    case LudoPlayerColor.yellow:
      return const Color(0xFFFFD600);
  }
}

/// A single Ludo token rendered as an animated positioned widget on the board.
///
/// The parent [Stack] must have the same coordinate system as the board painter
/// (cell size = boardSize / 15).
class LudoTokenWidget extends StatefulWidget {
  const LudoTokenWidget({
    super.key,
    required this.token,
    required this.cellSize,
    required this.col,
    required this.row,
    required this.isSelected,
    required this.isMovable,
    this.subCellOffsetX = 0,
    this.subCellOffsetY = 0,
    this.hopTrigger = 0,
    this.instantMove = false,
    this.onTap,
  });

  final LudoToken token;
  final double cellSize;
  final int col;
  final int row;
  final bool isSelected;
  final bool isMovable;
  final double subCellOffsetX;
  final double subCellOffsetY;
  /// Increments each time the token should bounce. `didUpdateWidget` triggers
  /// a hop animation whenever this value changes.
  final int hopTrigger;
  /// When true, position changes are instant (no AnimatedPositioned tween).
  final bool instantMove;
  final VoidCallback? onTap;

  @override
  State<LudoTokenWidget> createState() => _LudoTokenWidgetState();
}

class _LudoTokenWidgetState extends State<LudoTokenWidget>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _glowAlpha;

  late final AnimationController _hopCtrl;
  late final Animation<double> _hopScale;
  late final Animation<double> _hopLift;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _glowAlpha = Tween<double>(begin: 0.25, end: 0.75).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _hopScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.88), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(_hopCtrl);
    _hopLift = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -1.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _hopCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(LudoTokenWidget old) {
    super.didUpdateWidget(old);
    if (widget.hopTrigger != old.hopTrigger && widget.hopTrigger > 0) {
      _hopCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _hopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.cellSize * 0.72;
    final left = widget.col * widget.cellSize +
        (widget.cellSize - size) / 2 +
        widget.subCellOffsetX;
    final top = widget.row * widget.cellSize +
        (widget.cellSize - size) / 2 +
        widget.subCellOffsetY;

    final color = _tokenColor(widget.token.owner);
    final shielded = widget.token.shieldTurnsLeft > 0;
    final frozen = widget.token.isFrozen;
    final ambient = !widget.isMovable &&
        !widget.isSelected &&
        !shielded &&
        widget.token.isInBase;

    return AnimatedPositioned(
      duration: widget.instantMove
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: widget.isMovable ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _hopCtrl]),
          builder: (context, _) {
            final pulseScale = widget.isSelected ? _pulse.value : 1.0;
            final liftY = _hopLift.value * widget.cellSize * 0.5;
            final glowAlpha = widget.isMovable
                ? _glowAlpha.value
                : (shielded ? 0.55 : 0.0);
            return Transform.translate(
              offset: Offset(0, liftY),
              child: Transform.scale(
                scale: pulseScale * _hopScale.value,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _PawnPainter(
                    color: color,
                    isSelected: widget.isSelected,
                    isMovable: widget.isMovable,
                    shielded: shielded,
                    frozen: frozen,
                    glowAlpha: glowAlpha,
                    ambient: ambient,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Pawn painter ──────────────────────────────────────────────────────────

class _PawnPainter extends CustomPainter {
  const _PawnPainter({
    required this.color,
    required this.isSelected,
    required this.isMovable,
    required this.shielded,
    required this.frozen,
    required this.glowAlpha,
    required this.ambient,
  });

  final Color color;
  final bool isSelected;
  final bool isMovable;
  final bool shielded;
  final bool frozen;
  final double glowAlpha;
  final bool ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow beneath the pawn when movable (animated) or shielded (fixed).
    if (glowAlpha > 0) {
      final glowColor = shielded ? const Color(0xFF80DEEA) : color;
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      _drawAllParts(canvas, w, h, glowPaint);
    }

    // Shadow (drawn before fill so it appears beneath)
    final shadowPath = _buildCombinedPath(w, h);
    canvas.drawShadow(shadowPath, Colors.black, 3, false);

    // Ambient glow for idle in-base tokens (very faint, always on)
    if (ambient) {
      canvas.drawCircle(
        Offset(w * 0.5, h * 0.5),
        w * 0.5,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Gradient fill
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.55, -0.55),
        radius: 1.45,
        colors: [
          Color.lerp(color, Colors.white, 0.68)!,
          color,
          Color.lerp(color, Colors.black, 0.42)!,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    _drawAllParts(canvas, w, h, fillPaint);

    // Stroke outline
    final borderColor = isSelected
        ? Colors.white
        : shielded
            ? const Color(0xFF80DEEA)
            : Colors.black.withValues(alpha: 0.35);
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = shielded ? 2.5 : (isSelected ? 2.0 : 1.5);
    _drawAllParts(canvas, w, h, strokePaint);

    // Head highlight — primary specular oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.34, h * 0.18),
        width: w * 0.17,
        height: w * 0.12,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.60),
    );
    // Head highlight — specular hot spot
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.16),
      w * 0.045,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );

    // Frozen snowflake overlay
    if (frozen) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '❄',
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.18));
    }
  }

  void _drawAllParts(Canvas canvas, double w, double h, Paint paint) {
    canvas.drawOval(Rect.fromLTWH(0, h * 0.82, w, h * 0.18), paint);

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, h * 0.82)
        ..lineTo(w * 0.85, h * 0.82)
        ..lineTo(w * 0.70, h * 0.55)
        ..lineTo(w * 0.30, h * 0.55)
        ..close(),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTRB(w * 0.38, h * 0.42, w * 0.62, h * 0.58),
      paint,
    );

    canvas.drawOval(
      Rect.fromLTWH(w * 0.28, h * 0.43, w * 0.44, h * 0.07),
      paint,
    );

    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.26, paint);
  }

  Path _buildCombinedPath(double w, double h) {
    return Path()
      ..addOval(Rect.fromLTWH(0, h * 0.82, w, h * 0.18))
      ..addPath(
        Path()
          ..moveTo(w * 0.15, h * 0.82)
          ..lineTo(w * 0.85, h * 0.82)
          ..lineTo(w * 0.70, h * 0.55)
          ..lineTo(w * 0.30, h * 0.55)
          ..close(),
        Offset.zero,
      )
      ..addRect(Rect.fromLTRB(w * 0.38, h * 0.42, w * 0.62, h * 0.58))
      ..addOval(Rect.fromLTWH(w * 0.28, h * 0.43, w * 0.44, h * 0.07))
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.28), radius: w * 0.26),
      );
  }

  @override
  bool shouldRepaint(_PawnPainter old) =>
      old.color != color ||
      old.isSelected != isSelected ||
      old.isMovable != isMovable ||
      old.shielded != shielded ||
      old.frozen != frozen ||
      old.glowAlpha != glowAlpha ||
      old.ambient != ambient;
}
