import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../models/ludo_enums.dart';

// ── Magic face metadata ────────────────────────────────────────────────────

String _magicFaceLabel(MagicDiceFace face) {
  switch (face) {
    case MagicDiceFace.turbo:
      return 'TURBO';
    case MagicDiceFace.skip:
      return 'SKIP';
    case MagicDiceFace.ghost:
      return 'GHOST';
    case MagicDiceFace.bomb:
      return 'BOMB';
    case MagicDiceFace.wildcard:
      return 'WILDCARD';
  }
}

IconData _magicFaceIcon(MagicDiceFace face) {
  switch (face) {
    case MagicDiceFace.turbo:
      return Icons.bolt_rounded;
    case MagicDiceFace.skip:
      return Icons.block_rounded;
    case MagicDiceFace.ghost:
      return Icons.visibility_off_rounded;
    case MagicDiceFace.bomb:
      return Icons.crisis_alert_rounded;
    case MagicDiceFace.wildcard:
      return Icons.star_rounded;
  }
}

Color _magicFaceColor(MagicDiceFace face) {
  switch (face) {
    case MagicDiceFace.turbo:
      return const Color(0xFFFFD600);
    case MagicDiceFace.skip:
      return const Color(0xFFEF5350);
    case MagicDiceFace.ghost:
      return const Color(0xFF80DEEA);
    case MagicDiceFace.bomb:
      return const Color(0xFFFF5722);
    case MagicDiceFace.wildcard:
      return const Color(0xFFCE93D8);
  }
}

/// Animated magic die widget displayed alongside the normal die in magic mode.
///
/// Shows a spinning face icon that settles to [face] after rolling.
class LudoMagicDiceWidget extends StatefulWidget {
  const LudoMagicDiceWidget({
    super.key,
    required this.face,
    required this.rolling,
    this.size = 80.0,
  });

  final MagicDiceFace face;
  final bool rolling;
  final double size;

  @override
  State<LudoMagicDiceWidget> createState() => _LudoMagicDiceWidgetState();
}

class _LudoMagicDiceWidgetState extends State<LudoMagicDiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  MagicDiceFace _displayFace = MagicDiceFace.turbo;
  Timer? _cycleTimer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.15), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.rolling) {
      _startRolling();
    } else {
      _displayFace = widget.face;
    }
  }

  void _startRolling() {
    _cycleTimer?.cancel();
    _ctrl.forward(from: 0);
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_ctrl.value >= 0.6) {
        t.cancel();
        setState(() => _displayFace = widget.face);
        return;
      }
      setState(() {
        _displayFace =
            MagicDiceFace.values[_rng.nextInt(MagicDiceFace.values.length)];
      });
    });
  }

  @override
  void didUpdateWidget(LudoMagicDiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling) {
      _startRolling();
    } else if (!widget.rolling && old.rolling) {
      _cycleTimer?.cancel();
      setState(() => _displayFace = widget.face);
    } else if (widget.face != old.face && !widget.rolling) {
      setState(() => _displayFace = widget.face);
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceColor = _magicFaceColor(_displayFace);
    final icon = _magicFaceIcon(_displayFace);
    final label = _magicFaceLabel(_displayFace);
    final s = widget.size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(s * 0.18),
          color: const Color(0xFF1A1A30),
          border: Border.all(color: faceColor, width: s * 0.045),
          boxShadow: [
            BoxShadow(
              color: faceColor.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: faceColor, size: s * 0.40),
            SizedBox(height: s * 0.04),
            Text(
              label,
              style: TextStyle(
                color: faceColor,
                fontSize: s * 0.115,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pip dot positions per face value (normalized 0..1 within the pip area)
const _kPipLayouts = <int, List<(double, double)>>{
  1: [(0.5, 0.5)],
  2: [(0.25, 0.25), (0.75, 0.75)],
  3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
  4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
  5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
  6: [
    (0.25, 0.2),
    (0.75, 0.2),
    (0.25, 0.5),
    (0.75, 0.5),
    (0.25, 0.8),
    (0.75, 0.8),
  ],
};

Color _diceAccent(LudoPlayerColor? color) {
  switch (color) {
    case LudoPlayerColor.red:
      return const Color(0xFFE53935);
    case LudoPlayerColor.blue:
      return const Color(0xFF2979FF);
    case LudoPlayerColor.green:
      return const Color(0xFF43A047);
    case LudoPlayerColor.yellow:
      return const Color(0xFFFFD600);
    case null:
      return DSColors.ludoPrimary;
  }
}

/// Animated on-board dice shown after the player rolls.
///
/// Phase 1 (0–540 ms): rapidly cycles random faces while wobbling.
/// Phase 2 (540–900 ms): settles to [value] with a scale bounce.
class LudoDiceWidget extends StatefulWidget {
  const LudoDiceWidget({
    super.key,
    required this.value,
    required this.rolling,
    this.playerColor,
    this.size = 80.0,
  });

  final int value;
  final bool rolling;
  final LudoPlayerColor? playerColor;
  final double size;

  @override
  State<LudoDiceWidget> createState() => _LudoDiceWidgetState();
}

class _LudoDiceWidgetState extends State<LudoDiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;

  int _displayValue = 1;
  Timer? _cycleTimer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _buildAnimations();
    if (widget.rolling) {
      _startRolling();
    } else {
      _displayValue = widget.value.clamp(1, 6);
    }
  }

  void _buildAnimations() {
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.15), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  void _startRolling() {
    _cycleTimer?.cancel();
    _ctrl.forward(from: 0);

    _cycleTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_ctrl.value >= 0.6) {
        t.cancel();
        setState(() => _displayValue = widget.value.clamp(1, 6));
        return;
      }
      setState(() => _displayValue = _rng.nextInt(6) + 1);
    });
  }

  @override
  void didUpdateWidget(LudoDiceWidget old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !old.rolling) {
      _startRolling();
    } else if (!widget.rolling && old.rolling) {
      _cycleTimer?.cancel();
      setState(() => _displayValue = widget.value.clamp(1, 6));
    } else if (widget.value != old.value && !widget.rolling) {
      setState(() => _displayValue = widget.value.clamp(1, 6));
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _diceAccent(widget.playerColor);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: child,
          ),
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _DiePainter(value: _displayValue, accentColor: accent),
      ),
    );
  }
}

class _DiePainter extends CustomPainter {
  const _DiePainter({required this.value, required this.accentColor});

  final int value;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Isometric cube geometry
    final e = w * 0.60;
    final ddx = w * 0.22;
    final ddy = w * 0.14;
    final ox = (w - (e + ddx)) / 2;
    final oy = (h - (ddy + e)) / 2;

    final fTL = Offset(ox, oy + ddy);
    final fTR = Offset(ox + e, oy + ddy);
    final fBR = Offset(ox + e, oy + ddy + e);
    final bTL = Offset(ox + ddx, oy);
    final bTR = Offset(ox + e + ddx, oy);
    final bBR = Offset(ox + e + ddx, oy + e);

    // Glow halo behind the cube
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.60),
        width: w * 0.85,
        height: h * 0.35,
      ),
      Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Drop shadow
    final shadowCenter = Offset(ox + e / 2 + ddx * 0.5, oy + ddy + e + 4);
    canvas.drawOval(
      Rect.fromCenter(center: shadowCenter, width: e * 0.9, height: e * 0.18),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Right face
    final rightPath = Path()
      ..moveTo(fTR.dx, fTR.dy)
      ..lineTo(bTR.dx, bTR.dy)
      ..lineTo(bBR.dx, bBR.dy)
      ..lineTo(fBR.dx, fBR.dy)
      ..close();
    canvas.drawPath(
      rightPath,
      Paint()..color = Color.lerp(accentColor, Colors.black, 0.55)!,
    );

    // Top face
    final topPath = Path()
      ..moveTo(fTL.dx, fTL.dy)
      ..lineTo(fTR.dx, fTR.dy)
      ..lineTo(bTR.dx, bTR.dy)
      ..lineTo(bTL.dx, bTL.dy)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()..color = Color.lerp(accentColor, Colors.white, 0.48)!,
    );

    // Front face — slightly blue-tinted white fill
    final frontRect = Rect.fromPoints(fTL, fBR);
    canvas.drawRect(frontRect, Paint()..color = const Color(0xFFF0F0FF));

    // Front face — subtle sheen
    canvas.drawRect(
      frontRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F0FF), Color(0xFFE8E8F8)],
        ).createShader(frontRect),
    );

    // Front face border
    canvas.drawRect(
      frontRect,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = e * 0.045,
    );

    // Edge outlines
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawLine(fTL, fTR, edgePaint);
    canvas.drawLine(fTR, fBR, edgePaint);
    canvas.drawLine(bTL, bTR, edgePaint);
    canvas.drawLine(bTR, fTR, edgePaint);
    canvas.drawLine(bTR, bBR, edgePaint);
    canvas.drawLine(bBR, fBR, edgePaint);

    // Pips on front face — dark for real dice aesthetic
    final pipPaint = Paint()..color = const Color(0xFF1A1A1A);
    final pipR = e * 0.085;
    final pipArea = Rect.fromLTWH(
      fTL.dx + e * 0.12,
      fTL.dy + e * 0.12,
      e * 0.76,
      e * 0.76,
    );
    final pips = _kPipLayouts[value.clamp(1, 6)] ?? _kPipLayouts[1]!;
    for (final (px, py) in pips) {
      canvas.drawCircle(
        Offset(
          pipArea.left + pipArea.width * px,
          pipArea.top + pipArea.height * py,
        ),
        pipR,
        pipPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiePainter old) =>
      old.value != value || old.accentColor != accentColor;
}
