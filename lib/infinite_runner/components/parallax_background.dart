import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';

class ParallaxBackground extends ParallaxComponent {
  ParallaxBackground({required Vector2 size, required double scrollSpeed})
    : _scrollSpeed = scrollSpeed,
      super(size: size);

  double _scrollSpeed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    parallax = await game.loadParallax(
      [
        ParallaxImageData('sky.png'),
        ParallaxImageData('mountain1.png'),
        ParallaxImageData('hills1.png'),
        ParallaxImageData('clouds1.png'),
      ],
      baseVelocity: Vector2(_scrollSpeed, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
      fill: LayerFill.width,
      repeat: ImageRepeat.repeatX,
      alignment: Alignment.bottomCenter,
    );
  }

  /// Update scroll speed (called when game speed changes)
  /// Zero allocations - only updates velocity reference
  void updateSpeed(double newSpeed) {
    if (_scrollSpeed != newSpeed) {
      _scrollSpeed = newSpeed;

      // Update parallax base velocity
      if (parallax != null) {
        parallax!.baseVelocity.x = newSpeed;
      }
    }
  }
}
