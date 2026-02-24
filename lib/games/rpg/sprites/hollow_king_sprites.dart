// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

const int _t = 0x00000000;
const int _D = 0xFF202040; // dark shadow (deep navy)
const int _U = 0xFF3A3A80; // undead body (blue-gray)
const int _L = 0xFF5A5ABA; // lighter highlight
const int _C = 0xFFCCCC22; // crown gold
const int _G = 0xFF8888FF; // glowing blue eyes
const int _E = 0xFF9999DD; // ethereal pale (teeth)

class HollowKingSprites {
  static const PixelSprite idle0 = PixelSprite(
    width: 10, height: 14,
    pixels: [
      [_t, _C, _t, _C, _t, _C, _t, _C, _t, _t],
      [_C, _C, _C, _C, _C, _C, _C, _C, _C, _t],
      [_D, _U, _L, _U, _U, _U, _U, _L, _U, _D],
      [_D, _U, _U, _G, _U, _U, _G, _U, _U, _D],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_D, _U, _E, _E, _D, _D, _E, _E, _U, _D],
      [_t, _D, _U, _U, _U, _U, _U, _U, _D, _t],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_D, _L, _U, _U, _U, _U, _U, _U, _L, _D],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_U, _D, _t, _U, _t, _t, _U, _t, _D, _U],
      [_U, _t, _t, _D, _t, _t, _D, _t, _t, _U],
      [_t, _t, _t, _t, _U, _U, _t, _t, _t, _t],
      [_t, _t, _t, _t, _D, _D, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite idle1 = PixelSprite(
    width: 10, height: 14,
    pixels: [
      [_t, _C, _t, _C, _t, _C, _t, _C, _t, _t],
      [_C, _C, _C, _C, _C, _C, _C, _C, _C, _t],
      [_D, _U, _L, _U, _U, _U, _U, _L, _U, _D],
      [_D, _U, _U, _G, _U, _U, _G, _U, _U, _D],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_D, _U, _E, _E, _D, _D, _E, _E, _U, _D],
      [_t, _D, _U, _U, _U, _U, _U, _U, _D, _t],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_D, _L, _U, _U, _U, _U, _U, _U, _L, _D],
      [_D, _U, _U, _U, _U, _U, _U, _U, _U, _D],
      [_U, _D, _t, _t, _U, _U, _t, _t, _D, _U],
      [_D, _t, _t, _t, _D, _D, _t, _t, _t, _D],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _t, _U, _U, _U, _U, _t, _t, _t],
    ],
  );

  static const PixelAnimation idleAnim = PixelAnimation(
    frames: [idle0, idle1],
    frameDuration: 0.55,
  );

  static const PixelAnimation attackAnim = PixelAnimation(
    frames: [idle0, idle1],
    frameDuration: 0.18,
  );

  static const PixelAnimation hurtAnim = PixelAnimation(
    frames: [idle0],
    frameDuration: 0.3,
  );

  static const PixelAnimation dieAnim = PixelAnimation(
    frames: [idle1, idle0],
    frameDuration: 0.45,
  );
}
