import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

class ParallaxBackground extends ParallaxComponent {
  ParallaxBackground({required Vector2 size, required double scrollSpeed})
    : _scrollSpeed = scrollSpeed,
      super(size: size);

  double _scrollSpeed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Manually load images from assets/background/ and register with Flame
    await _loadAndRegisterImage('sky.png', 'background/PNG/Flat/sky.png');
    await _loadAndRegisterImage(
      'mountain1.png',
      'background/PNG/Flat/mountain1.png',
    );
    await _loadAndRegisterImage('hills1.png', 'background/PNG/Flat/hills1.png');
    await _loadAndRegisterImage(
      'clouds1.png',
      'background/PNG/Flat/clouds1.png',
    );

    // Load parallax with registered images
    parallax = await game.loadParallax(
      [
        // Layer 1: Sky - Static background (no scrolling)
        ParallaxImageData('sky.png'),

        // Layer 2: Mountains - Slow scroll (0.3x speed)
        ParallaxImageData('mountain1.png'),

        // Layer 3: Hills - Medium scroll (0.6x speed)
        ParallaxImageData('hills1.png'),

        // Layer 4: Clouds - Fast scroll (1.0x speed)
        ParallaxImageData('clouds1.png'),
      ],
      baseVelocity: Vector2(_scrollSpeed, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
      fill: LayerFill.width,
      repeat: ImageRepeat.repeatX,
      alignment: Alignment.bottomCenter,
    );
  }

  Future<void> _loadAndRegisterImage(String key, String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);
    game.images.add(key, image);
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
