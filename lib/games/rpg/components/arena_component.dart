import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';

/// A platform definition — static rectangle the player can stand on.
class Platform {
  const Platform({required this.rect});
  final Rect rect;
}

/// Renders the arena background and stone platforms, with animated ambient effects.
class ArenaComponent extends Component with HasGameReference {
  ArenaComponent({required this.bossId});

  final BossId bossId;

  final List<Platform> platforms = [];

  double _time = 0;

  // Ambient particle data — pre-allocated, animated via math
  static const int _numWisps = 6;
  static const int _numEmbers = 8;
  static const int _numDrips = 4;

  final List<double> _wispBaseX = [];
  final List<double> _wispBaseY = [];
  final List<double> _wispPhase = [];

  final List<double> _emberBaseX = [];
  final List<double> _emberPhase = [];
  final List<double> _emberSpeed = [];

  final List<double> _dripX = [];
  final List<double> _dripPhase = [];

  // Static cached paints
  static final _bgPaintWraith = Paint()..color = const Color(0xFF0D0020);
  static final _bgPaintDefault = Paint()..color = const Color(0xFF1A1008);
  static final _midPaintWraith = Paint()..color = const Color(0xFF1A0040);
  static final _midPaintDefault = Paint()..color = const Color(0xFF2A1A0A);
  static final _platformPaint = Paint()..color = const Color(0xFF4A4040);
  static final _platformHighlightPaint = Paint()
    ..color = const Color(0xFF6A6060);
  static final _platformShadowPaint = Paint()..color = const Color(0xFF2A2020);

  // Mutable paints for animated effects (updated each frame, not allocated)
  final Paint _wispPaint = Paint()
    ..color = const Color(0xAA80C8FF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final Paint _wispCorePaint = Paint()..color = const Color(0xFFCCEEFF);
  final Paint _emberPaint = Paint()..color = const Color(0xFFFF6600);
  final Paint _heatPaint = Paint()..color = const Color(0x22FF4400);
  final Paint _mistPaint = Paint()..color = const Color(0x1A4A0080);
  final Paint _runeRingPaint = Paint()
    ..color = const Color(0x334A00CC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _pulsePaint = Paint()..color = const Color(0x0F8000FF);
  final Paint _dripPaint = Paint()..color = const Color(0xFF604010);
  final Paint _cracklePaint = Paint()
    ..color = const Color(0x55FF4400)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildPlatforms();
    _initParticles();
  }

  void _initParticles() {
    final size = game.size;
    final rng = math.Random(42); // seeded for determinism

    // Wisps (wraith arena)
    for (int i = 0; i < _numWisps; i++) {
      _wispBaseX.add(size.x * (0.08 + rng.nextDouble() * 0.84));
      _wispBaseY.add(size.y * (0.15 + rng.nextDouble() * 0.55));
      _wispPhase.add(rng.nextDouble() * math.pi * 2);
    }

    // Embers (golem arena)
    for (int i = 0; i < _numEmbers; i++) {
      _emberBaseX.add(size.x * (0.04 + rng.nextDouble() * 0.92));
      _emberPhase.add(rng.nextDouble() * 90.0);
      _emberSpeed.add(22 + rng.nextDouble() * 38);
    }

    // Stalactite drips (golem arena ceiling)
    for (int i = 0; i < _numDrips; i++) {
      _dripX.add(size.x * (0.12 + i * 0.22 + rng.nextDouble() * 0.08));
      _dripPhase.add(rng.nextDouble() * 3.0);
    }
  }

  void _buildPlatforms() {
    platforms.clear();
    final size = game.size;
    // Ground platform
    platforms.add(Platform(rect: Rect.fromLTWH(0, size.y - 60, size.x, 60)));
    if (bossId == BossId.wraith) {
      platforms.add(
        Platform(rect: Rect.fromLTWH(size.x * 0.1, size.y - 160, 120, 20)),
      );
      platforms.add(
        Platform(rect: Rect.fromLTWH(size.x * 0.45, size.y - 200, 120, 20)),
      );
      platforms.add(
        Platform(rect: Rect.fromLTWH(size.x * 0.75, size.y - 160, 120, 20)),
      );
    } else {
      platforms.add(
        Platform(rect: Rect.fromLTWH(size.x * 0.1, size.y - 160, 140, 24)),
      );
      platforms.add(
        Platform(rect: Rect.fromLTWH(size.x * 0.65, size.y - 200, 140, 24)),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    final bgPaint = bossId == BossId.wraith ? _bgPaintWraith : _bgPaintDefault;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    if (bossId == BossId.wraith) {
      _renderWraithArena(canvas, size);
    } else {
      _renderGolemArena(canvas, size);
    }

    // Platforms
    for (final p in platforms) {
      _drawPlatform(canvas, p.rect);
    }
  }

  void _renderWraithArena(Canvas canvas, Vector2 size) {
    // Mid-layer pulsing dark void
    final pulse = (math.sin(_time * 0.5) * 0.5 + 0.5);
    _pulsePaint.color = Color.fromARGB(
      (pulse * 28).round(),
      128, 0, 255,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.25, size.x, size.y * 0.45),
      _midPaintWraith,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.25, size.x, size.y * 0.45),
      _pulsePaint,
    );

    // Rotating rune rings
    for (int r = 0; r < 2; r++) {
      final cx = size.x * (0.28 + r * 0.44);
      final cy = size.y * 0.48;
      final radius = 55.0 + r * 18.0;
      final rot = _time * (r == 0 ? 0.4 : -0.3);
      _runeRingPaint.color = Color.fromARGB(
        (50 + pulse * 40).round(), 100, 0, 220,
      );
      canvas.drawCircle(Offset(cx, cy), radius, _runeRingPaint);
      // 4 rune dots around the ring
      for (int d = 0; d < 4; d++) {
        final angle = rot + d * math.pi / 2;
        final rx = cx + math.cos(angle) * radius;
        final ry = cy + math.sin(angle) * radius;
        _runeRingPaint.color = Color.fromARGB(
          (80 + pulse * 80).round(), 150, 80, 255,
        );
        canvas.drawCircle(Offset(rx, ry), 3, _runeRingPaint);
      }
    }

    // Ground mist
    _mistPaint.color = Color.fromARGB(
      (18 + math.sin(_time * 0.35) * 8).round().clamp(10, 30),
      74, 0, 128,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y - 90, size.x, 90),
      _mistPaint,
    );

    // Ethereal wisps
    for (int i = 0; i < _numWisps; i++) {
      final wx = _wispBaseX[i] + math.sin(_time * 0.65 + _wispPhase[i]) * 38;
      final wy = _wispBaseY[i] + math.cos(_time * 0.48 + _wispPhase[i] * 1.3) * 20;
      final wSize = 2.5 + math.sin(_time * 1.1 + _wispPhase[i]).abs() * 2.0;
      _wispPaint.color = Color.fromARGB(
        (100 + math.sin(_time * 0.9 + _wispPhase[i]) * 60).round().clamp(40, 160),
        120, 180, 255,
      );
      canvas.drawCircle(Offset(wx, wy), wSize + 2, _wispPaint);
      _wispCorePaint.color = Color.fromARGB(
        (180 + math.sin(_time * 1.2 + _wispPhase[i]) * 60).round().clamp(100, 240),
        220, 240, 255,
      );
      canvas.drawCircle(Offset(wx, wy), wSize * 0.5, _wispCorePaint);
    }
  }

  void _renderGolemArena(Canvas canvas, Vector2 size) {
    // Mid-layer cave rock face
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.3, size.x, size.y * 0.4),
      _midPaintDefault,
    );

    // Ceiling stalactites (static visual) — use _dripPaint (dark brown instance paint)
    _dripPaint.color = const Color(0xFF302010);
    for (int s = 0; s < 6; s++) {
      final sx = size.x * (0.05 + s * 0.17);
      final sh = 24.0 + (s % 3) * 14.0;
      canvas.drawRect(Rect.fromLTWH(sx, 0, 12, sh), _dripPaint);
    }

    // Heat cracks in floor — pulsing orange lines
    final crackAlpha = (50 + math.sin(_time * 2.1) * 35).round().clamp(15, 90);
    _cracklePaint.color = Color.fromARGB(crackAlpha, 255, 80, 0);
    final groundY = size.y - 60;
    // Pre-defined crack paths — no allocation in render
    canvas.drawLine(
      Offset(size.x * 0.15, groundY),
      Offset(size.x * 0.22, groundY - 16),
      _cracklePaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.22, groundY - 16),
      Offset(size.x * 0.28, groundY - 8),
      _cracklePaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.55, groundY),
      Offset(size.x * 0.60, groundY - 20),
      _cracklePaint,
    );
    canvas.drawLine(
      Offset(size.x * 0.60, groundY - 20),
      Offset(size.x * 0.67, groundY - 10),
      _cracklePaint,
    );

    // Ground heat glow
    _heatPaint.color = Color.fromARGB(
      (24 + math.sin(_time * 1.8) * 14).round().clamp(10, 42),
      255, 68, 0,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, groundY - 22, size.x, 22),
      _heatPaint,
    );

    // Rising ember particles
    for (int i = 0; i < _numEmbers; i++) {
      final elapsed = (_time * _emberSpeed[i] + _emberPhase[i]) % (groundY * 0.85);
      final ey = groundY - elapsed;
      final ex = _emberBaseX[i] + math.sin(_time * 2.2 + _emberPhase[i]) * 7;
      final fadeAlpha = ((1.0 - elapsed / (groundY * 0.85)) * 220).round().clamp(0, 220);
      _emberPaint.color = Color.fromARGB(fadeAlpha, 255, 100 + (elapsed * 0.5).round().clamp(0, 100), 0);
      canvas.drawCircle(Offset(ex, ey), 1.8, _emberPaint);
    }

    // Stalactite drips — falling liquid drops
    for (int i = 0; i < _numDrips; i++) {
      final dripY = ((_time * 18 + _dripPhase[i] * 12) % 40).toDouble();
      _dripPaint.color = Color.fromARGB(
        (120 - dripY * 2).round().clamp(40, 120), 96, 64, 16,
      );
      canvas.drawCircle(Offset(_dripX[i], dripY + 18), 2.5, _dripPaint);
    }
  }

  void _drawPlatform(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _platformPaint);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 4),
      _platformHighlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 4, rect.width, 4),
      _platformShadowPaint,
    );
  }
}
