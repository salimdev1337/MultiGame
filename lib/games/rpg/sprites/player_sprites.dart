// ignore_for_file: lines_longer_than_80_chars
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

/// Hero — 8×12 pixel character
/// Colors: 0xFFB0C4DE body, 0xFF8B0000 cape/detail, 0xFFFFD700 sword

const int _t = 0x00000000; // transparent
const int _b = 0xFF5C8A8A; // body (teal-gray)
const int _s = 0xFFFFD700; // sword (gold)
const int _h = 0xFF3A3A3A; // hair/dark
const int _k = 0xFF8B0000; // cape (dark red)
const int _e = 0xFFFFE4B5; // skin

class PlayerSprites {
  static const PixelSprite idle0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_t, _k, _b, _s, _s, _b, _k, _t],
      [_t, _t, _b, _b, _b, _b, _t, _t],
      [_t, _t, _b, _t, _t, _b, _t, _t],
      [_t, _t, _b, _t, _t, _b, _t, _t],
      [_t, _t, _h, _t, _t, _h, _t, _t],
    ],
  );

  static const PixelSprite idle1 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_t, _k, _b, _s, _s, _b, _k, _t],
      [_t, _t, _b, _b, _b, _b, _t, _t],
      [_t, _t, _h, _b, _b, _h, _t, _t],
      [_t, _t, _h, _t, _t, _h, _t, _t],
      [_t, _t, _h, _t, _t, _h, _t, _t],
    ],
  );

  static const PixelSprite walk0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_t, _k, _b, _s, _s, _b, _k, _t],
      [_t, _b, _b, _b, _b, _b, _t, _t],
      [_b, _h, _t, _t, _b, _t, _t, _t],
      [_h, _t, _t, _t, _h, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite walk1 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_t, _k, _b, _s, _s, _b, _k, _t],
      [_t, _t, _b, _b, _b, _b, _b, _t],
      [_t, _t, _t, _b, _t, _t, _h, _b],
      [_t, _t, _t, _h, _t, _t, _t, _h],
      [_t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite attack0 = PixelSprite(
    width: 10, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t, _t, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t, _t, _t],
      [_k, _b, _b, _b, _b, _b, _b, _s, _s, _s],
      [_k, _b, _b, _b, _b, _b, _b, _s, _t, _t],
      [_t, _k, _b, _t, _t, _b, _k, _t, _t, _t],
      [_t, _t, _b, _b, _b, _b, _t, _t, _t, _t],
      [_t, _t, _h, _b, _b, _h, _t, _t, _t, _t],
      [_t, _t, _h, _t, _t, _h, _t, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite hurt0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _h, _h, _h, _h, _t, _t],
      [_t, _h, _e, _e, _e, _e, _h, _t],
      [_t, _h, _e, 0xFFFF4444, 0xFFFF4444, _e, _h, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _t],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_k, 0xFFFF4444, _b, _b, _b, _b, _k, _k],
      [_t, _k, _b, _s, _s, _b, _k, _t],
      [_t, _t, _b, _b, _b, _b, _t, _t],
      [_t, _t, _b, _t, _t, _b, _t, _t],
      [_t, _t, _h, _t, _t, _h, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelAnimation idleAnim = PixelAnimation(
    frames: [idle0, idle1],
    frameDuration: 0.5,
  );

  static const PixelAnimation walkAnim = PixelAnimation(
    frames: [walk0, walk1],
    frameDuration: 0.2,
  );

  static const PixelAnimation attackAnim = PixelAnimation(
    frames: [attack0, idle0],
    frameDuration: 0.15,
  );

  static const PixelAnimation hurtAnim = PixelAnimation(
    frames: [hurt0],
    frameDuration: 0.3,
  );

  // Dodge — player crouching low, lunging forward with sword extended
  static const PixelSprite dodge0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _t, _h, _h, _t, _t, _t],
      [_t, _t, _h, _e, _e, _h, _t, _t],
      [_t, _k, _b, _b, _b, _b, _k, _k],
      [_k, _b, _b, _b, _b, _b, _b, _k],
      [_t, _k, _b, _b, _b, _b, _s, _s],
      [_t, _t, _b, _b, _b, _t, _t, _t],
      [_t, _b, _b, _t, _b, _t, _t, _t],
      [_b, _h, _t, _t, _b, _h, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelAnimation dodgeAnim = PixelAnimation(
    frames: [dodge0],
    frameDuration: 0.35,
  );
}
