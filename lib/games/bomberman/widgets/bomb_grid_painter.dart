import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

// ─── Color palette — sourced from DSColors ───────────────────────────────────

const _kPlayerColors = [
  DSColors.primary,          // cyan    — P1 / host
  DSColors.bombermanP2,      // gold    — P2
  DSColors.memoryPrimary,    // purple  — P3
  DSColors.bombermanP4,      // orange  — P4
];

const _kPowerupColors = {
  PowerupType.extraBomb: DSColors.success,
  PowerupType.blastRange: DSColors.secondary,
  PowerupType.speed: DSColors.memoryPrimary,
  PowerupType.shield: DSColors.primary,
};

/// Stateless CustomPainter that renders the full Bomberman grid each frame.
/// The [animValue] (0–1, driven by Ticker) is used for bomb fuse animation.
class BombGridPainter extends CustomPainter {
  final BombGameState gameState;
  final double animValue; // drives fuse shrink + explosion pulse

  const BombGridPainter({required this.gameState, required this.animValue});

  // ─── Cached static Paint objects (fixed colors, allocated once) ───────────

  static final _bgPaint       = Paint()..color = DSColors.bombermanBg;
  static final _floorAPaint   = Paint()..color = DSColors.bombermanFloorA;
  static final _floorBPaint   = Paint()..color = DSColors.bombermanFloorB;
  static final _groutPaint    = Paint()..color = DSColors.bombermanGrout;
  static final _wallPaint     = Paint()..color = DSColors.bombermanWall;
  static final _wallTopPaint  = Paint()
    ..color = DSColors.bombermanWallTop
    ..strokeWidth = 2;
  static final _wallShadePaint = Paint()
    ..color = DSColors.bombermanWallBevel
    ..strokeWidth = 2;
  static final _blockPaint = Paint()..color = DSColors.bombermanBlock;
  static final _blockGrainPaint = Paint()
    ..color = DSColors.bombermanBlockHighlight.withValues(alpha: 0.4)
    ..strokeWidth = 1;
  static final _bombBodyPaint = Paint()..color = DSColors.highContrastSurface;
  static final _fusePaint = Paint()
    ..color = DSColors.bombermanFuse
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  // ─── Player character paints ──────────────────────────────────────────────
  static final _skinPaint = Paint()..color = const Color(0xFFFFCC99);
  static final _eyeWhitePaint = Paint()..color = const Color(0xFFFFFFFF);
  static final _pupilPaint = Paint()..color = const Color(0xFF1a1a1a);
  static final _shadowPaint = Paint()..color = const Color(0x4D000000);
  static final _bodyHighlightPaint = Paint()
    ..color = const Color(0x33FFFFFF);
  static final _shieldPaint = Paint()
    ..color = const Color(0xFF00d4ff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  bool shouldRepaint(BombGridPainter old) =>
      old.animValue != animValue ||
      old.gameState.bombs != gameState.bombs ||
      old.gameState.explosions != gameState.explosions ||
      old.gameState.players != gameState.players ||
      old.gameState.grid != gameState.grid ||
      old.gameState.powerups != gameState.powerups;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / kGridW;
    final cellH = size.height / kGridH;

    _drawBackground(canvas, size);
    _drawGrid(canvas, size, cellW, cellH);
    _drawPowerups(canvas, cellW, cellH);
    _drawExplosions(canvas, cellW, cellH);
    _drawBombs(canvas, cellW, cellH);
    _drawPlayers(canvas, cellW, cellH);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Overall fill
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    final cellW = size.width / kGridW;
    final cellH = size.height / kGridH;
    const grout = 1.5; // grout line width in px

    for (int r = 0; r < kGridH; r++) {
      for (int c = 0; c < kGridW; c++) {
        // Only draw floor tiles on empty/walkable cells — walls are drawn later
        final left   = c * cellW + grout;
        final top    = r * cellH + grout;
        final width  = cellW - grout * 2;
        final height = cellH - grout * 2;

        if (width <= 0 || height <= 0) continue;

        // Checker — two very close dark shades give depth without noise
        canvas.drawRect(
          Rect.fromLTWH(left, top, width, height),
          (r + c).isEven ? _floorAPaint : _floorBPaint,
        );
      }
    }

    // Grout lines — draw a thin grid over everything
    _groutPaint.style = PaintingStyle.stroke;
    _groutPaint.strokeWidth = grout;
    for (int r = 0; r <= kGridH; r++) {
      canvas.drawLine(
        Offset(0, r * cellH),
        Offset(size.width, r * cellH),
        _groutPaint,
      );
    }
    for (int c = 0; c <= kGridW; c++) {
      canvas.drawLine(
        Offset(c * cellW, 0),
        Offset(c * cellW, size.height),
        _groutPaint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final grid = gameState.grid;
    for (int r = 0; r < kGridH; r++) {
      for (int c = 0; c < kGridW; c++) {
        final cell = grid[r][c];
        if (cell == CellType.empty) continue;

        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        if (cell == CellType.wall) {
          // ── Wall face (main body) ─────────────────────────────────────
          canvas.drawRect(rect, _wallPaint);

          const bevel = 3.0;

          // Top-left lit faces — simulates light from top-left
          _wallTopPaint.style = PaintingStyle.fill;
          // Top strip
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top, rect.width, bevel),
            _wallTopPaint,
          );
          // Left strip
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.top, bevel, rect.height),
            _wallTopPaint,
          );

          // Bottom-right shadow faces — simulates shadow/depth
          _wallShadePaint.style = PaintingStyle.fill;
          // Bottom strip
          canvas.drawRect(
            Rect.fromLTWH(rect.left, rect.bottom - bevel, rect.width, bevel),
            _wallShadePaint,
          );
          // Right strip
          canvas.drawRect(
            Rect.fromLTWH(rect.right - bevel, rect.top, bevel, rect.height),
            _wallShadePaint,
          );
        } else if (cell == CellType.block) {
          canvas.drawRect(rect, _blockPaint);
          // Wood-grain lines
          canvas.drawLine(
            Offset(c * cellW + 3, r * cellH + cellH * 0.3),
            Offset(c * cellW + cellW - 3, r * cellH + cellH * 0.3),
            _blockGrainPaint,
          );
          canvas.drawLine(
            Offset(c * cellW + 3, r * cellH + cellH * 0.65),
            Offset(c * cellW + cellW - 3, r * cellH + cellH * 0.65),
            _blockGrainPaint,
          );
        }
      }
    }
  }

  void _drawExplosions(Canvas canvas, double cellW, double cellH) {
    for (final e in gameState.explosions) {
      final alpha = e.alpha;
      final cx = e.x * cellW + cellW / 2;
      final cy = e.y * cellH + cellH / 2;
      final radius =
          min(cellW, cellH) * 0.5 * (0.8 + 0.2 * sin(animValue * pi * 4));

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            DSColors.bombermanExplosionCenter.withValues(alpha: alpha),
            DSColors.bombermanExplosionOuter.withValues(alpha: alpha * 0.5),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawCircle(Offset(cx, cy), radius, paint);

      // Glow
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 1.3,
        Paint()
          ..color = DSColors.bombermanExplosionCenter.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _drawBombs(Canvas canvas, double cellW, double cellH) {
    for (final b in gameState.bombs) {
      final cx = b.x * cellW + cellW / 2;
      final cy = b.y * cellH + cellH / 2;
      final r = min(cellW, cellH) * 0.38;

      // Body
      canvas.drawCircle(Offset(cx, cy), r, _bombBodyPaint);

      // Fuse (shrinking arc based on bomb progress)
      final fuseProgress = b.fuseProgress;
      final fuseAngle = pi * (1.0 - fuseProgress) * 1.5;
      final rect = Rect.fromCircle(
        center: Offset(cx, cy - r * 0.9),
        radius: r * 0.4,
      );
      canvas.drawArc(rect, -pi / 2, fuseAngle, false, _fusePaint);

      // Spark at fuse tip (pulsing)
      if (fuseProgress > 0.6) {
        final sparkAlpha = (sin(animValue * pi * 8) * 0.5 + 0.5);
        canvas.drawCircle(
          Offset(cx, cy - r * 1.3),
          r * 0.15,
          Paint()..color = DSColors.bombermanFuse.withValues(alpha: sparkAlpha.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _drawPlayers(Canvas canvas, double cellW, double cellH) {
    for (final p in gameState.players) {
      if (!p.isAlive && !p.isGhost) continue;

      // p.x/p.y are smooth cell-centre coords (e.g. 1.5 = centre of cell 1)
      final cx = p.x * cellW;
      final cy = p.y * cellH;
      final cs = min(cellW, cellH); // reference cell size

      final baseColor = _kPlayerColors[p.id % _kPlayerColors.length];
      final alpha = p.isGhost ? 0.35 : 1.0;
      final color = baseColor.withValues(alpha: alpha);

      // ── Ghost short-circuit ──────────────────────────────────────────────
      if (p.isGhost) {
        final tp = TextPainter(
          text: TextSpan(text: '👻', style: TextStyle(fontSize: cs * 0.55)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
        continue;
      }

      // ── 1. Soft glow (underneath everything) ────────────────────────────
      canvas.drawCircle(
        Offset(cx, cy),
        cs * 0.55,
        Paint()
          ..color = color.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // ── 2. Ground shadow (subtle oval below feet) ────────────────────────
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + cs * 0.38),
          width: cs * 0.55,
          height: cs * 0.14,
        ),
        _shadowPaint,
      );

      // ── 3. Legs (two rounded rects, slightly below body centre) ──────────
      final legW = cs * 0.17;
      final legH = cs * 0.2;
      final legY = cy + cs * 0.22;
      for (final dx in [-cs * 0.13, cs * 0.13]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx + dx, legY),
              width: legW,
              height: legH,
            ),
            Radius.circular(legW * 0.45),
          ),
          Paint()..color = color.withValues(alpha: 0.8),
        );
      }

      // ── 4. Body / overalls ───────────────────────────────────────────────
      final bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + cs * 0.04),
          width: cs * 0.58,
          height: cs * 0.46,
        ),
        Radius.circular(cs * 0.12),
      );
      canvas.drawRRect(bodyRect, Paint()..color = color);

      // Chest highlight (top strip — gives slight 3-D roundness)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - cs * 0.06),
            width: cs * 0.42,
            height: cs * 0.12,
          ),
          Radius.circular(cs * 0.06),
        ),
        _bodyHighlightPaint,
      );

      // ── 5. Head (skin-toned circle) ──────────────────────────────────────
      final headR = cs * 0.21;
      final headCy = cy - cs * 0.19;
      _skinPaint.color = const Color(0xFFFFCC99).withValues(alpha: alpha);
      canvas.drawCircle(Offset(cx, headCy), headR, _skinPaint);

      // ── 6. Helmet (top half of head, player colour) ──────────────────────
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, headCy), radius: headR * 1.06),
        pi,     // startAngle: left side
        pi,     // sweepAngle: top semicircle
        true,
        Paint()..color = color,
      );

      // Helmet brim — thin horizontal bar at head equator
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, headCy),
            width: headR * 2.3,
            height: headR * 0.28,
          ),
          Radius.circular(headR * 0.14),
        ),
        Paint()..color = color.withValues(alpha: 0.9),
      );

      // ── 7. Eyes ──────────────────────────────────────────────────────────
      final eyeY = headCy + headR * 0.18;
      final eyeR = headR * 0.22;
      for (final ex in [-headR * 0.38, headR * 0.38]) {
        _eyeWhitePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: alpha);
        canvas.drawCircle(Offset(cx + ex, eyeY), eyeR, _eyeWhitePaint);
        _pupilPaint.color =
            const Color(0xFF1a1a1a).withValues(alpha: alpha);
        canvas.drawCircle(
          Offset(cx + ex, eyeY + eyeR * 0.2),
          eyeR * 0.55,
          _pupilPaint,
        );
      }

      // ── 8. Shield ring (pulsing cyan outline) ────────────────────────────
      if (p.hasShield) {
        final shieldAlpha =
            (sin(animValue * pi * 4) * 0.3 + 0.7).clamp(0.0, 1.0);
        _shieldPaint.color =
            const Color(0xFF00d4ff).withValues(alpha: shieldAlpha);
        canvas.drawCircle(Offset(cx, cy), cs * 0.5, _shieldPaint);
      }

      // ── 9. Multiplayer ID badge ───────────────────────────────────────────
      if (p.id > 0) {
        final badgeCx = cx + cs * 0.26;
        final badgeCy = cy - cs * 0.26;
        canvas.drawCircle(
          Offset(badgeCx, badgeCy),
          cs * 0.13,
          Paint()..color = const Color(0xCC111111),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '${p.id + 1}',
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: cs * 0.16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(badgeCx - tp.width / 2, badgeCy - tp.height / 2),
        );
      }
    }
  }

  void _drawPowerups(Canvas canvas, double cellW, double cellH) {
    final cs = min(cellW, cellH);

    for (final pw in gameState.powerups) {
      final cx = pw.x * cellW + cellW / 2;
      final cy = pw.y * cellH + cellH / 2;
      final color = _kPowerupColors[pw.type] ?? const Color(0xFFffffff);

      // Pulsing glow ring — draws attention to the pickup
      final glowAlpha = (sin(animValue * pi * 2) * 0.25 + 0.45).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, cy),
        cs * 0.46,
        Paint()
          ..color = color.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Dark pill background so the emoji pops on the floor
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: cs * 0.7, height: cs * 0.7),
          Radius.circular(cs * 0.16),
        ),
        Paint()..color = const Color(0xCC0a0c12),
      );

      // Emoji icon — fills the cell naturally, no text label needed
      final emoji = switch (pw.type) {
        PowerupType.extraBomb  => '💣',
        PowerupType.blastRange => '🔥',
        PowerupType.speed      => '⚡',
        PowerupType.shield     => '🛡️',
      };
      final tp = TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(fontSize: cs * 0.44),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }
}
