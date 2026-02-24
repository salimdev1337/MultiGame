import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/sprites/golem_sprites.dart';
import 'package:multigame/games/rpg/sprites/hollow_king_sprites.dart';
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';
import 'package:multigame/games/rpg/sprites/shadowlord_sprites.dart';
import 'package:multigame/games/rpg/sprites/wraith_sprites.dart';

/// Loads and caches rasterized pixel-sprite frames for a boss.
/// Call [load] once in onLoad(); then use [draw] each render frame.
class BossSpriteRenderer {
  BossSpriteRenderer(this.bossId);

  final BossId bossId;

  late PixelAnimation _idleAnim;
  late PixelAnimation _attackAnim;
  late PixelAnimation _hurtAnim;

  final Map<String, List<ui.Image>> _cache = {};

  Future<void> load() async {
    switch (bossId) {
      case BossId.warden:
        _idleAnim = GolemSprites.idleAnim;
        _attackAnim = GolemSprites.attackAnim;
        _hurtAnim = GolemSprites.hurtAnim;
      case BossId.shaman:
        _idleAnim = WraithSprites.floatAnim;
        _attackAnim = WraithSprites.attackAnim;
        _hurtAnim = WraithSprites.hurtAnim;
      case BossId.hollowKing:
        _idleAnim = HollowKingSprites.idleAnim;
        _attackAnim = HollowKingSprites.attackAnim;
        _hurtAnim = HollowKingSprites.hurtAnim;
      case BossId.shadowlord:
        _idleAnim = ShadowlordSprites.floatAnim;
        _attackAnim = ShadowlordSprites.attackAnim;
        _hurtAnim = ShadowlordSprites.hurtAnim;
    }
    await _loadAnim('idle', _idleAnim);
    await _loadAnim('attack', _attackAnim);
    await _loadAnim('hurt', _hurtAnim);
  }

  Future<void> _loadAnim(String key, PixelAnimation anim) async {
    _cache[key] = [];
    for (final sprite in anim.frames) {
      _cache[key]!.add(await sprite.toImage(4));
    }
  }

  void draw(
    ui.Canvas canvas,
    BossAnimState state,
    bool isHurt,
    double elapsedSecs,
    Vector2 targetSize,
  ) {
    final String key;
    final PixelAnimation anim;
    if (isHurt) {
      key = 'hurt';
      anim = _hurtAnim;
    } else if (state == BossAnimState.attack) {
      key = 'attack';
      anim = _attackAnim;
    } else {
      key = 'idle';
      anim = _idleAnim;
    }

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
}
