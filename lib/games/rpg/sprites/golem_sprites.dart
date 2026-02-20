// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

const int _t = 0x00000000;
const int _G = 0xFF808080; // gray body
const int _D = 0xFF505050; // dark gray
const int _L = 0xFFA0A0A0; // light gray
const int _R = 0xFFCC2200; // red glow eye
const int _S = 0xFF303030; // shadow

class GolemSprites {
  static const PixelSprite idle0 = PixelSprite(
    width: 12, height: 14,
    pixels: [
      [_t, _t, _D, _D, _D, _D, _D, _D, _D, _D, _t, _t],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_D, _G, _L, _G, _G, _G, _G, _G, _G, _L, _G, _D],
      [_D, _G, _G, _R, _G, _G, _G, _G, _R, _G, _G, _D],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_D, _G, _G, _G, _S, _S, _S, _S, _G, _G, _G, _D],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_t, _D, _G, _D, _t, _t, _t, _t, _D, _G, _D, _t],
      [_t, _D, _G, _D, _t, _t, _t, _t, _D, _G, _D, _t],
      [_t, _D, _G, _D, _t, _t, _t, _t, _D, _G, _D, _t],
      [_t, _S, _S, _S, _t, _t, _t, _t, _S, _S, _S, _t],
    ],
  );

  static const PixelSprite idle1 = PixelSprite(
    width: 12, height: 14,
    pixels: [
      [_t, _t, _D, _D, _D, _D, _D, _D, _D, _D, _t, _t],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_D, _G, _L, _G, _G, _G, _G, _G, _G, _L, _G, _D],
      [_D, _G, _G, _R, _G, _G, _G, _G, _R, _G, _G, _D],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_D, _G, _G, _G, _S, _S, _S, _S, _G, _G, _G, _D],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_t, _D, _G, _G, _G, _G, _G, _G, _G, _G, _D, _t],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_D, _G, _G, _G, _G, _G, _G, _G, _G, _G, _G, _D],
      [_t, _D, _G, _D, _t, _t, _t, _t, _D, _G, _D, _t],
      [_t, _D, _G, _D, _t, _t, _t, _t, _D, _G, _D, _t],
      [_t, _S, _S, _D, _t, _t, _t, _t, _D, _S, _S, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelAnimation idleAnim = PixelAnimation(
    frames: [idle0, idle1],
    frameDuration: 0.6,
  );

  static const PixelAnimation attackAnim = PixelAnimation(
    frames: [idle0, idle1],
    frameDuration: 0.2,
  );

  static const PixelAnimation hurtAnim = PixelAnimation(
    frames: [idle0],
    frameDuration: 0.3,
  );

  static const PixelAnimation dieAnim = PixelAnimation(
    frames: [idle1, idle0],
    frameDuration: 0.4,
  );
}
