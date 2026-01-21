import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// Optimized parallax background for Infinite Runner
/// - Static layers are pre-rendered
/// - No heavy drawing per frame
/// - Safe for 60 FPS
class Background extends PositionComponent {
  Background({required Vector2 size, required this.scrollSpeed})
    : super(size: size);

  double scrollSpeed;
  double _offset = 0.0;

  // Cached paints
  late final Paint _skyPaint;
  late final Paint _starPaint;
  late final Paint _mountainPaint;
  late final Paint _cloudPaint;

  // Cached data
  late final Picture _staticSkyAndStars;
  late final List<Offset> _stars;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _initPaints();
    _generateStars();
    _staticSkyAndStars = _recordStaticLayer();
  }

  // ------------------------
  // Initialization
  // ------------------------

  void _initPaints() {
    _skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0a0c10), Color(0xFF16181d)],
      ).createShader(size.toRect());

    _starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    _mountainPaint = Paint()
      ..color = const Color(0xFF1a1e26).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    _cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
  }

  void _generateStars() {
    final rand = math.Random(42);
    _stars = List.generate(50, (_) {
      return Offset(
        rand.nextDouble() * size.x,
        rand.nextDouble() * size.y * 0.6,
      );
    });
  }

  /// Record static sky + stars ONCE
  Picture _recordStaticLayer() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Sky
    canvas.drawRect(size.toRect(), _skyPaint);

    // Stars
    for (final star in _stars) {
      canvas.drawCircle(star, 2, _starPaint);
    }

    return recorder.endRecording();
  }

  // ------------------------
  // Update
  // ------------------------

  @override
  void update(double dt) {
    // Very cheap math only
    _offset += scrollSpeed * dt;
    if (_offset > size.x) {
      _offset -= size.x;
    }
  }

  // ------------------------
  // Render
  // ------------------------

  @override
  void render(Canvas canvas) {
    // Static background (sky + stars)
    canvas.drawPicture(_staticSkyAndStars);

    // Mountains (slow parallax)
    canvas.save();
    canvas.translate(-_offset * 0.3, 0);
    _drawMountains(canvas);
    canvas.restore();

    // Clouds (faster parallax)
    canvas.save();
    canvas.translate(-_offset * 0.6, 0);
    _drawClouds(canvas);
    canvas.restore();
  }

  // ------------------------
  // Layers
  // ------------------------

  void _drawMountains(Canvas canvas) {
    final baseY = size.y * 0.7;

    // Draw wide rect instead of complex path (cheap)
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, size.x * 2, size.y - baseY),
      _mountainPaint,
    );
  }

  void _drawClouds(Canvas canvas) {
    for (int i = 0; i < 5; i++) {
      final x = i * 220.0;
      final y = 60.0 + i * 25.0;

      canvas.drawCircle(Offset(x, y), 20, _cloudPaint);
      canvas.drawCircle(Offset(x + 24, y), 26, _cloudPaint);
      canvas.drawCircle(Offset(x + 52, y), 20, _cloudPaint);
      canvas.drawCircle(Offset(x + 26, y - 14), 22, _cloudPaint);
    }
  }

  // ------------------------
  // External API
  // ------------------------

  void updateSpeed(double newSpeed) {
    scrollSpeed = newSpeed;
  }
}
