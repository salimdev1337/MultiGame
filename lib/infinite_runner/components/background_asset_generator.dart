import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Utility to generate placeholder background images
/// Replace these with actual PNG assets for production
class BackgroundAssetGenerator {
  /// Generate sky gradient (dark blue to lighter blue)
  static Future<ui.Image> generateSky(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0a0c10), Color(0xFF16181d)],
      ).createShader(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    // Add stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset((i * 37.0) % width, (i * 23.0) % (height * 0.6)),
        2,
        starPaint,
      );
    }

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  /// Generate mountain silhouette
  static Future<ui.Image> generateMountains(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.transparent,
    );

    // Dark mountain shapes at bottom
    final paint = Paint()
      ..color = const Color(0xFF1a1e26).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, height * 0.7)
      ..lineTo(width * 0.2, height * 0.5)
      ..lineTo(width * 0.4, height * 0.6)
      ..lineTo(width * 0.6, height * 0.45)
      ..lineTo(width * 0.8, height * 0.65)
      ..lineTo(width.toDouble(), height * 0.55)
      ..lineTo(width.toDouble(), height.toDouble())
      ..lineTo(0, height.toDouble())
      ..close();

    canvas.drawPath(path, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  /// Generate cloud layer
  static Future<ui.Image> generateClouds(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.transparent,
    );

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Draw a few clouds
    for (int i = 0; i < 4; i++) {
      final x = i * (width / 4.0);
      final y = 60.0 + i * 30.0;

      canvas.drawCircle(Offset(x, y), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 24, y), 26, cloudPaint);
      canvas.drawCircle(Offset(x + 52, y), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 26, y - 14), 22, cloudPaint);
    }

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }
}
