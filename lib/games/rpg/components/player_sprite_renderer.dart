import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';
import 'package:multigame/games/rpg/sprites/player_sprites.dart';

/// Loads and caches rasterized pixel-sprite frames for the player (Voss).
/// Call [load] once in onLoad(); then use [draw] each render frame.
class PlayerSpriteRenderer {
  late final Map<String, PixelAnimation> _anims;
  final Map<String, List<ui.Image>> _cache = {};

  Future<void> load() async {
    _anims = {
      'idle':     PlayerSprites.idleAnim,
      'walk':     PlayerSprites.walkAnim,
      'attack':   PlayerSprites.attackAnim,
      'hurt':     PlayerSprites.hurtAnim,
      'dodge':    PlayerSprites.dodgeAnim,
      'ultimate': PlayerSprites.ultimateAnim,
    };
    for (final entry in _anims.entries) {
      await _loadAnim(entry.key, entry.value);
    }
  }

  Future<void> _loadAnim(String key, PixelAnimation anim) async {
    _cache[key] = [];
    for (final sprite in anim.frames) {
      _cache[key]!.add(await sprite.toImage(4));
    }
  }

  void draw(
    ui.Canvas canvas,
    PlayerAnimState state,
    bool isHurt,
    double elapsedSecs,
    Vector2 targetSize,
  ) {
    final key = _keyFor(state, isHurt);
    final anim = _anims[key]!;
    final images = _cache[key];
    if (images == null || images.isEmpty) {
      return;
    }

    final frameCount = images.length;
    final idx = frameCount > 1
        ? ((elapsedSecs % (anim.frameDuration * frameCount)) /
                anim.frameDuration)
            .floor()
            .clamp(0, frameCount - 1)
        : 0;

    final img = images[idx];
    final src = ui.Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );
    final dst = ui.Rect.fromLTWH(0, 0, targetSize.x, targetSize.y);

    final paint = ui.Paint();
    if (isHurt) {
      paint.colorFilter = const ui.ColorFilter.mode(
        ui.Color(0xCCFFFFFF),
        ui.BlendMode.srcATop,
      );
    }
    canvas.drawImageRect(img, src, dst, paint);
  }

  String _keyFor(PlayerAnimState state, bool isHurt) {
    if (isHurt) {
      return 'hurt';
    }
    switch (state) {
      case PlayerAnimState.attack:
        return 'attack';
      case PlayerAnimState.hurt:
        return 'hurt';
      case PlayerAnimState.dodge:
        return 'dodge';
      case PlayerAnimState.walk:
        return 'walk';
      case PlayerAnimState.ultimate:
        return 'ultimate';
      default:
        return 'idle';
    }
  }
}
