import 'dart:ui';

import 'package:flame/components.dart';

/// A platform definition — static rectangle the player can stand on.
class Platform {
  const Platform({required this.rect});
  final Rect rect;
}

/// Renders the arena background and stone platforms.
class ArenaComponent extends Component with HasGameReference {
  ArenaComponent({required this.bossId});

  final String bossId;

  final List<Platform> platforms = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _buildPlatforms();
  }

  void _buildPlatforms() {
    platforms.clear();
    final size = game.size;
    // Ground platform
    platforms.add(Platform(
      rect: Rect.fromLTWH(0, size.y - 60, size.x, 60),
    ));
    if (bossId == 'wraith') {
      // Floating platforms for wraith arena
      platforms.add(Platform(
        rect: Rect.fromLTWH(size.x * 0.1, size.y - 160, 120, 20),
      ));
      platforms.add(Platform(
        rect: Rect.fromLTWH(size.x * 0.45, size.y - 200, 120, 20),
      ));
      platforms.add(Platform(
        rect: Rect.fromLTWH(size.x * 0.75, size.y - 160, 120, 20),
      ));
    } else {
      // Rocky cave platforms for golem arena
      platforms.add(Platform(
        rect: Rect.fromLTWH(size.x * 0.1, size.y - 160, 140, 24),
      ));
      platforms.add(Platform(
        rect: Rect.fromLTWH(size.x * 0.65, size.y - 200, 140, 24),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    // Background
    final bgColor = bossId == 'wraith'
        ? const Color(0xFF0D0020)
        : const Color(0xFF1A1008);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = bgColor,
    );

    // Distant background detail
    final midColor = bossId == 'wraith'
        ? const Color(0xFF1A0040)
        : const Color(0xFF2A1A0A);
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.3, size.x, size.y * 0.4),
      Paint()..color = midColor,
    );

    // Platforms
    for (final p in platforms) {
      _drawPlatform(canvas, p.rect);
    }
  }

  void _drawPlatform(Canvas canvas, Rect rect) {
    // Platform body
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF4A4040),
    );
    // Top highlight
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 4),
      Paint()..color = const Color(0xFF6A6060),
    );
    // Bottom shadow
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 4, rect.width, 4),
      Paint()..color = const Color(0xFF2A2020),
    );
  }
}
