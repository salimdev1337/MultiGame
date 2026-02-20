// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

const int _t = 0x00000000;
const int _P = 0xFF4A0080; // purple body
const int _L = 0xFF8000CC; // light purple
const int _W = 0xFFFFFFFF; // white eyes
const int _S = 0xFF200040; // shadow dark
const int _C = 0xFF00AAFF; // cyan aura

class WraithSprites {
  static const PixelSprite float0 = PixelSprite(
    width: 10, height: 14,
    pixels: [
      [_t, _t, _t, _S, _S, _S, _S, _t, _t, _t],
      [_t, _t, _S, _P, _P, _P, _P, _S, _t, _t],
      [_t, _S, _P, _L, _P, _P, _L, _P, _S, _t],
      [_t, _S, _P, _W, _P, _P, _W, _P, _S, _t],
      [_t, _S, _P, _P, _P, _P, _P, _P, _S, _t],
      [_t, _S, _P, _P, _S, _S, _P, _P, _S, _t],
      [_t, _t, _S, _P, _P, _P, _P, _S, _t, _t],
      [_t, _t, _S, _P, _P, _P, _P, _S, _t, _t],
      [_t, _S, _P, _P, _P, _P, _P, _P, _S, _t],
      [_t, _S, _P, _P, _P, _P, _P, _P, _S, _t],
      [_C, _S, _P, _S, _t, _t, _S, _P, _S, _C],
      [_C, _t, _S, _t, _t, _t, _t, _S, _t, _C],
      [_t, _t, _C, _t, _t, _t, _t, _C, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite float1 = PixelSprite(
    width: 10, height: 14,
    pixels: [
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _S, _S, _S, _S, _S, _S, _t, _t],
      [_t, _S, _P, _L, _P, _P, _L, _P, _S, _t],
      [_t, _S, _P, _W, _P, _P, _W, _P, _S, _t],
      [_t, _S, _P, _P, _P, _P, _P, _P, _S, _t],
      [_t, _S, _P, _P, _S, _S, _P, _P, _S, _t],
      [_t, _t, _S, _P, _P, _P, _P, _S, _t, _t],
      [_t, _t, _S, _P, _P, _P, _P, _S, _t, _t],
      [_t, _S, _P, _P, _P, _P, _P, _P, _S, _t],
      [_C, _S, _P, _P, _P, _P, _P, _P, _S, _C],
      [_C, _t, _S, _P, _t, _t, _P, _S, _t, _C],
      [_t, _t, _t, _S, _t, _t, _S, _t, _t, _t],
      [_t, _t, _t, _C, _t, _t, _C, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelAnimation floatAnim = PixelAnimation(
    frames: [float0, float1],
    frameDuration: 0.4,
  );

  static const PixelAnimation attackAnim = PixelAnimation(
    frames: [float0, float1],
    frameDuration: 0.15,
  );

  static const PixelAnimation hurtAnim = PixelAnimation(
    frames: [float0],
    frameDuration: 0.3,
  );

  static const PixelAnimation dieAnim = PixelAnimation(
    frames: [float1, float0],
    frameDuration: 0.5,
  );
}
