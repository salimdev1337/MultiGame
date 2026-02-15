import 'dart:math';
import 'package:flutter/rendering.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/cell_type.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

// ─── Color palette ────────────────────────────────────────────────────────────

const _kBg = Color(0xFF111520);
const _kWall = Color(0xFF2d3142);
const _kBlock = Color(0xFF6B3A2A);
const _kBlockHighlight = Color(0xFF8B5035);
const _kBomb = Color(0xFF1a1a1a);
const _kFuse = Color(0xFFff8c00);
const _kExplosionCenter = Color(0xFFff4500);
const _kExplosionOuter = Color(0xFFffd700);

const _kPlayerColors = [
  Color(0xFF00d4ff), // cyan    — P1 / host
  Color(0xFFffd700), // gold    — P2
  Color(0xFF7c4dff), // purple  — P3
  Color(0xFFff6b35), // orange  — P4
];

const _kPowerupColors = {
  PowerupType.extraBomb: Color(0xFF19e6a2),
  PowerupType.blastRange: Color(0xFFff5c00),
  PowerupType.speed: Color(0xFF7c4dff),
  PowerupType.shield: Color(0xFF00d4ff),
};

/// Stateless CustomPainter that renders the full Bomberman grid each frame.
/// The [animValue] (0–1, driven by Ticker) is used for bomb fuse animation.
class BombGridPainter extends CustomPainter {
  final BombGameState gameState;
  final double animValue; // drives fuse shrink + explosion pulse

  const BombGridPainter({required this.gameState, required this.animValue});

  // ─── Cached static Paint objects (fixed colors, allocated once) ───────────

  static final _bgPaint = Paint()..color = _kBg;
  static final _wallPaint = Paint()..color = _kWall;
  static final _wallBevelPaint = Paint()
    ..color = const Color(0xFF3d4460).withValues(alpha: 0.6)
    ..strokeWidth = 1;
  static final _blockPaint = Paint()..color = _kBlock;
  static final _blockGrainPaint = Paint()
    ..color = _kBlockHighlight.withValues(alpha: 0.4)
    ..strokeWidth = 1;
  static final _bombBodyPaint = Paint()..color = _kBomb;
  static final _fusePaint = Paint()
    ..color = _kFuse
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final _directionDotPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _bgPaint,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double cellW, double cellH) {
    final grid = gameState.grid;
    for (int r = 0; r < kGridH; r++) {
      for (int c = 0; c < kGridW; c++) {
        final cell = grid[r][c];
        if (cell == CellType.empty) continue;

        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        if (cell == CellType.wall) {
          canvas.drawRect(rect, _wallPaint);
          // Subtle top/left highlight bevel
          canvas.drawLine(
            rect.topLeft + const Offset(1, 1),
            rect.topRight + const Offset(-1, 1),
            _wallBevelPaint,
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
            _kExplosionCenter.withValues(alpha: alpha),
            _kExplosionOuter.withValues(alpha: alpha * 0.5),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawCircle(Offset(cx, cy), radius, paint);

      // Glow
      canvas.drawCircle(
        Offset(cx, cy),
        radius * 1.3,
        Paint()
          ..color = _kExplosionCenter.withValues(alpha: alpha * 0.2)
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
          Paint()..color = _kFuse.withValues(alpha: sparkAlpha.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _drawPlayers(Canvas canvas, double cellW, double cellH) {
    for (final p in gameState.players) {
      if (!p.isAlive) continue;

      // p.x/p.y are cell-centre coords (e.g. 1.5 = centre of cell 1)
      final cx = p.x * cellW;
      final cy = p.y * cellH;
      final r = min(cellW, cellH) * 0.42;
      final baseColor = _kPlayerColors[p.id % _kPlayerColors.length];

      // Ghost: render at 35% opacity with a washed-out hue
      final alpha = p.isGhost ? 0.35 : 1.0;
      final color = baseColor.withValues(alpha: alpha);

      // Glow (dimmer for ghosts)
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.4,
        Paint()
          ..color = color.withValues(alpha: p.isGhost ? 0.08 : 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Body circle
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

      // Shield ring — pulsing cyan outline
      if (p.hasShield) {
        final shieldAlpha = (sin(animValue * pi * 4) * 0.3 + 0.7).clamp(
          0.0,
          1.0,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          r * 1.2,
          Paint()
            ..color = const Color(0xFF00d4ff).withValues(alpha: shieldAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Direction indicator (small dot on top for "face") — hidden when ghost
      if (!p.isGhost) {
        canvas.drawCircle(
          Offset(cx, cy - r * 0.5),
          r * 0.2,
          _directionDotPaint,
        );
      }

      // Ghost indicator (👻 label)
      if (p.isGhost) {
        final tp = TextPainter(
          text: TextSpan(
            text: '👻',
            style: TextStyle(fontSize: r * 0.7),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      } else if (p.id > 0) {
        // ID badge for non-local players
        final tp = TextPainter(
          text: TextSpan(
            text: '${p.id + 1}',
            style: TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: r * 0.7,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      }
    }
  }

  void _drawPowerups(Canvas canvas, double cellW, double cellH) {
    for (final pw in gameState.powerups) {
      final cx = pw.x * cellW + cellW / 2;
      final cy = pw.y * cellH + cellH / 2;
      final r = min(cellW, cellH) * 0.3;
      final color = _kPowerupColors[pw.type] ?? const Color(0xFFffffff);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          const Radius.circular(4),
        ),
        Paint()..color = color.withValues(alpha: 0.9),
      );

      // Small icon text
      final icon = switch (pw.type) {
        PowerupType.extraBomb => '+B',
        PowerupType.blastRange => '+R',
        PowerupType.speed => '+S',
        PowerupType.shield => '+SH',
      };
      final tp = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: r * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }
}
