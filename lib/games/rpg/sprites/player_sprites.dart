// ignore_for_file: lines_longer_than_80_chars
import 'package:multigame/games/rpg/sprites/pixel_sprite.dart';

/// Voss — heavy armored crimson ranger, 8×12 (attack: 10×12)
/// Palette: crimson plate, near-black steel, gold visor, wood bow, flame orange

const int _t = 0x00000000; // transparent
const int _r = 0xFFCC1100; // crimson — main plate armor
const int _d = 0xFF880E00; // dark crimson — armor shadow/shading
const int _k = 0xFF1A1A1A; // near black — steel joints & edges
const int _v = 0xFFFFCC00; // gold — visor slit & trim
const int _w = 0xFF6B3A1F; // wood brown — bow
const int _f = 0xFFFF6600; // flame orange — attack glow / flaming arrow tip

class PlayerSprites {
  static const PixelSprite idle0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _k, _r, _r, _k, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t],
      [_t, _k, _r, _d, _d, _r, _k, _t],
      [_r, _r, _r, _r, _r, _r, _r, _r],
      [_d, _r, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _k],
      [_w, _k, _r, _k, _k, _r, _k, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _k, _t, _r, _r, _t, _k, _t],
    ],
  );

  static const PixelSprite idle1 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _t, _k, _r, _k, _t, _t],
      [_t, _t, _k, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t],
      [_t, _k, _r, _d, _d, _r, _k, _t],
      [_t, _r, _r, _r, _r, _r, _r, _r],
      [_t, _d, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _k],
      [_w, _k, _r, _k, _k, _r, _k, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _k, _t, _r, _r, _t, _k, _t],
      [_t, _k, _t, _k, _k, _t, _k, _t],
    ],
  );

  static const PixelSprite walk0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _k, _r, _r, _k, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t],
      [_t, _k, _r, _d, _d, _r, _k, _t],
      [_r, _r, _r, _r, _r, _r, _r, _r],
      [_d, _r, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _k],
      [_w, _r, _k, _k, _k, _k, _r, _t],
      [_r, _k, _t, _r, _r, _k, _t, _t],
      [_k, _t, _t, _r, _k, _t, _t, _t],
      [_t, _t, _t, _k, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite walk1 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _k, _r, _r, _k, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t],
      [_t, _k, _r, _d, _d, _r, _k, _t],
      [_r, _r, _r, _r, _r, _r, _r, _r],
      [_d, _r, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _k],
      [_w, _r, _k, _k, _k, _k, _r, _t],
      [_t, _k, _t, _r, _r, _t, _k, _r],
      [_t, _t, _t, _k, _r, _t, _t, _k],
      [_t, _t, _t, _t, _k, _t, _t, _t],
    ],
  );

  static const PixelSprite attack0 = PixelSprite(
    width: 10, height: 12,
    pixels: [
      [_t, _t, _k, _r, _r, _k, _t, _t, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t, _t, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t, _t, _t],
      [_t, _k, _r, _d, _d, _r, _k, _t, _t, _t],
      [_r, _r, _r, _r, _r, _r, _r, _r, _w, _t],
      [_d, _r, _r, _r, _r, _r, _r, _w, _k, _f],
      [_k, _k, _r, _d, _d, _r, _k, _w, _t, _t],
      [_k, _k, _k, _r, _r, _k, _k, _w, _t, _t],
      [_t, _k, _r, _k, _k, _r, _k, _t, _t, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t, _t, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t, _t, _t],
      [_t, _k, _t, _r, _r, _t, _k, _t, _t, _t],
    ],
  );

  static const PixelSprite hurt0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _k, _r, _r, _k, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, 0xFFFF4444, _k, _k, _t],
      [_t, _k, 0xFFFF4444, _d, _d, _r, _k, _t],
      [_t, _r, _r, _r, _r, _r, _r, _r],
      [_t, _d, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _t],
      [_t, _k, _r, _k, _k, _r, _k, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _t, _t, _k, _t, _t, _t, _t],
    ],
  );

  static const PixelSprite dodge0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _t, _t, _t, _t, _t, _t],
      [_t, _t, _k, _r, _r, _k, _t, _t],
      [_t, _k, _r, _r, _r, _r, _k, _t],
      [_t, _k, _k, _v, _v, _k, _k, _t],
      [_r, _r, _r, _r, _r, _r, _r, _r],
      [_d, _r, _r, _r, _r, _r, _r, _d],
      [_k, _k, _k, _r, _r, _k, _k, _k],
      [_r, _r, _k, _k, _k, _k, _r, _r],
      [_k, _r, _k, _r, _r, _k, _r, _k],
      [_r, _k, _t, _r, _r, _t, _k, _r],
      [_k, _t, _t, _k, _k, _t, _t, _k],
    ],
  );

  static const PixelSprite ultimate0 = PixelSprite(
    width: 8, height: 12,
    pixels: [
      [_t, _t, _k, _f, _f, _k, _t, _t],
      [_t, _k, _f, _r, _r, _f, _k, _t],
      [_t, _k, _k, _v, _f, _k, _k, _t],
      [_t, _k, _f, _d, _d, _f, _k, _t],
      [_f, _r, _r, _r, _r, _r, _r, _f],
      [_d, _r, _r, _r, _r, _r, _r, _d],
      [_w, _k, _r, _d, _d, _r, _k, _k],
      [_w, _k, _k, _r, _r, _k, _k, _k],
      [_w, _f, _k, _k, _k, _k, _f, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _r, _k, _r, _r, _k, _r, _t],
      [_t, _k, _t, _f, _f, _t, _k, _t],
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

  static const PixelAnimation dodgeAnim = PixelAnimation(
    frames: [dodge0],
    frameDuration: 0.35,
  );

  static const PixelAnimation ultimateAnim = PixelAnimation(
    frames: [ultimate0, idle0],
    frameDuration: 0.2,
  );
}
