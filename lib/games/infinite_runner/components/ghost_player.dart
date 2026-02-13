import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Semi-transparent opponent avatar rendered in world space.
/// Position is updated each frame based on the opponent's distance delta
/// relative to the local player.
class GhostPlayer extends PositionComponent {
  GhostPlayer({
    required this.playerId,
    required this.displayName,
    required this.playerColor,
    required double groundY,
  }) : _groundY = groundY,
       super(
         size: Vector2(36, 54),
         anchor: Anchor.bottomCenter,
       );

  final int playerId;
  final String displayName;
  final Color playerColor;
  double _groundY;

  /// Delta in scroll-units between opponent and local player.
  /// Positive = opponent is ahead (to the right).
  double distanceDelta = 0.0;

  // ── Layout constants ─────────────────────────────────────────────────────
  /// Local player always renders at this screen x
  static const double localPlayerX = 100.0;

  /// 1 scroll-unit ≈ this many pixels of horizontal offset
  static const double pixelsPerUnit = 0.8;

  /// Max screen-edge padding so the ghost stays visible
  static const double edgePad = 48.0;

  void updateGroundY(double newGroundY) {
    _groundY = newGroundY;
    position.y = newGroundY;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Map distance delta to screen x, clamped so ghost stays on-screen
    // (the parent game provides the screen width via onGameResize)
    final rawX = localPlayerX + distanceDelta * pixelsPerUnit;
    position.x = rawX;
    position.y = _groundY;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Body — higher opacity for better contrast
    final bodyPaint = Paint()..color = playerColor.withValues(alpha: 0.65);
    final outlinePaint = Paint()
      ..color = playerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    // White inner highlight for additional contrast against dark backgrounds
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw a simple humanoid silhouette (rect body + circle head)
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.65);
    final headCenter = Offset(w / 2, h * 0.18);
    const headRadius = 10.0;

    canvas.drawRect(bodyRect, bodyPaint);
    canvas.drawRect(bodyRect, outlinePaint);
    canvas.drawRect(bodyRect, highlightPaint);
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);
    canvas.drawCircle(headCenter, headRadius, highlightPaint);

    // Name label above the ghost (truncated to 8 chars)
    final label = displayName.length > 8
        ? '${displayName.substring(0, 7)}…'
        : (displayName.isNotEmpty ? displayName : '?');
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: playerColor,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4),
            Shadow(color: Colors.black, blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.3 - tp.height - 4));
  }
}
