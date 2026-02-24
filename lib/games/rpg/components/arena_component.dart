import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// Top-down arena floor. Fixed camera — arena is centered on screen.
/// Draws a tiled floor, decorative elements, and a boundary wall.
/// Environmental storytelling: decorations are unique per boss.
class ArenaComponent extends PositionComponent with HasGameReference {
  ArenaComponent({required this.bossId}) : super(position: Vector2.zero());

  final BossId bossId;

  late Vector2 arenaMin;
  late Vector2 arenaMax;

  static const double _margin = 40;

  // Pre-allocated for render loop
  static final _floorPaint = Paint()..color = const Color(0xFF1A1A1A);
  static final _borderPaint = Paint()
    ..color = const Color(0xFF444444)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  static final _tilePaint = Paint()
    ..color = const Color(0xFF222222)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  final _decorPaint = Paint();
  final math.Random _rng = math.Random(42); // seeded for deterministic layout
  late List<Offset> _decorPositions;
  late List<double> _decorSizes;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final s = game.size;
    arenaMin = Vector2(_margin, _margin);
    arenaMax = Vector2(s.x - _margin, s.y - _margin);
    size = s;
    _generateDecorations();
  }

  void _generateDecorations() {
    _decorPositions = List.generate(
      12,
      (i) => Offset(
        arenaMin.x + _rng.nextDouble() * (arenaMax.x - arenaMin.x),
        arenaMin.y + _rng.nextDouble() * (arenaMax.y - arenaMin.y),
      ),
    );
    _decorSizes = List.generate(
      12,
      (i) => 4 + _rng.nextDouble() * 10,
    );
  }

  Rect get arenaRect => Rect.fromLTWH(
    arenaMin.x,
    arenaMin.y,
    arenaMax.x - arenaMin.x,
    arenaMax.y - arenaMin.y,
  );

  @override
  void render(Canvas canvas) {
    final rect = arenaRect;

    // Floor fill
    _floorPaint.color = _floorColor();
    canvas.drawRect(rect, _floorPaint);

    // Tile grid
    const tileSize = 48.0;
    for (double x = arenaMin.x; x < arenaMax.x; x += tileSize) {
      canvas.drawLine(
        Offset(x, arenaMin.y),
        Offset(x, arenaMax.y),
        _tilePaint,
      );
    }
    for (double y = arenaMin.y; y < arenaMax.y; y += tileSize) {
      canvas.drawLine(
        Offset(arenaMin.x, y),
        Offset(arenaMax.x, y),
        _tilePaint,
      );
    }

    // Environmental decorations
    _drawDecorations(canvas);

    // Border wall
    canvas.drawRect(rect, _borderPaint);

    // Corner brackets
    _drawCornerBrackets(canvas, rect);
  }

  void _drawDecorations(Canvas canvas) {
    _decorPaint.color = _decorColor();
    _decorPaint.style = PaintingStyle.fill;

    for (int i = 0; i < _decorPositions.length; i++) {
      final pos = _decorPositions[i];
      final sz = _decorSizes[i];
      canvas.drawRect(
        Rect.fromCenter(center: pos, width: sz, height: sz),
        _decorPaint,
      );
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    const len = 20.0;
    final paint = Paint()
      ..color = _accentColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    final dirs = [
      [const Offset(len, 0), const Offset(0, len)],
      [const Offset(-len, 0), const Offset(0, len)],
      [const Offset(len, 0), const Offset(0, -len)],
      [const Offset(-len, 0), const Offset(0, -len)],
    ];

    for (int i = 0; i < 4; i++) {
      final c = corners[i];
      canvas.drawLine(c, c + dirs[i][0], paint);
      canvas.drawLine(c, c + dirs[i][1], paint);
    }
  }

  Color _floorColor() {
    switch (bossId) {
      case BossId.warden:
        return const Color(0xFF1C1410); // dark stone
      case BossId.shaman:
        return const Color(0xFF0E1A0E); // dark swamp
      case BossId.hollowKing:
        return const Color(0xFF10101C); // dark throne room
      case BossId.shadowlord:
        return const Color(0xFF0A000A); // void
    }
  }

  Color _decorColor() {
    switch (bossId) {
      case BossId.warden:
        return const Color(0xFF3A2800); // rust / broken weapons
      case BossId.shaman:
        return const Color(0xFF0A3000); // dead vegetation
      case BossId.hollowKing:
        return const Color(0xFF20204A); // stone rubble
      case BossId.shadowlord:
        return const Color(0xFF220022); // void fragments
    }
  }

  Color _accentColor() {
    switch (bossId) {
      case BossId.warden:
        return const Color(0xFF8B6914);
      case BossId.shaman:
        return const Color(0xFF22AA22);
      case BossId.hollowKing:
        return const Color(0xFF6666CC);
      case BossId.shadowlord:
        return const Color(0xFFAA00AA);
    }
  }
}
