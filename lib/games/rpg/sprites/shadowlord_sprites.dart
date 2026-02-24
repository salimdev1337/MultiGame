// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

const int _t = 0x00000000;
const int _D = 0xFF220022; // deep void dark
const int _V = 0xFF440044; // void body
const int _L = 0xFF660066; // lighter void
const int _P = 0xFFAA00AA; // bright void pulse
const int _W = 0xFFFFFFFF; // void eye glow
const int _B = 0xFF110011; // near-black void core

class ShadowlordSprites {
  static const PixelSprite float0 = PixelSprite(
    width: 12, height: 14,
    pixels: [
      [_t, _t, _D, _D, _V, _V, _V, _V, _D, _D, _t, _t],
      [_t, _D, _V, _L, _V, _V, _V, _V, _L, _V, _D, _t],
      [_D, _V, _L, _V, _V, _V, _V, _V, _V, _L, _V, _D],
      [_D, _V, _V, _W, _V, _V, _V, _V, _W, _V, _V, _D],
      [_D, _V, _V, _B, _V, _V, _V, _V, _B, _V, _V, _D],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_D, _V, _V, _V, _P, _P, _P, _P, _V, _V, _V, _D],
      [_t, _D, _V, _V, _V, _V, _V, _V, _V, _V, _D, _t],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_P, _V, _D, _V, _t, _t, _t, _t, _V, _D, _V, _P],
      [_P, _t, _V, _D, _t, _t, _t, _t, _D, _V, _t, _P],
      [_t, _t, _P, _t, _t, _t, _t, _t, _t, _P, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite float1 = PixelSprite(
    width: 12, height: 14,
    pixels: [
      [_t, _t, _D, _D, _V, _V, _V, _V, _D, _D, _t, _t],
      [_t, _D, _V, _L, _V, _V, _V, _V, _L, _V, _D, _t],
      [_D, _V, _L, _V, _V, _V, _V, _V, _V, _L, _V, _D],
      [_D, _V, _V, _W, _V, _V, _V, _V, _W, _V, _V, _D],
      [_D, _V, _V, _B, _V, _V, _V, _V, _B, _V, _V, _D],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_D, _V, _V, _V, _P, _P, _P, _P, _V, _V, _V, _D],
      [_t, _D, _V, _V, _V, _V, _V, _V, _V, _V, _D, _t],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_D, _V, _V, _V, _V, _V, _V, _V, _V, _V, _V, _D],
      [_P, _V, _D, _t, _V, _t, _t, _V, _t, _D, _V, _P],
      [_t, _P, _t, _V, _D, _t, _t, _D, _V, _t, _P, _t],
      [_t, _t, _t, _P, _t, _t, _t, _t, _P, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t, _t],
    ],
  );

  static const PixelAnimation floatAnim = PixelAnimation(
    frames: [float0, float1],
    frameDuration: 0.45,
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
