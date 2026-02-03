import 'package:flame/components.dart';
import '../infinite_runner_game.dart';

class GroundTile extends SpriteComponent
    with HasGameReference<InfiniteRunnerGame> {
  GroundTile({required Vector2 position, required this.scrollSpeed})
    : super(position: position);

  double scrollSpeed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // ✅ SAFE: asset loading only
    sprite = await Sprite.load('platformIndustrial_003.png');

    anchor = Anchor.topLeft;
  }

  @override
  void onMount() {
    super.onMount();

    // Scale the ground tile to fit the ground height exactly
    // Use the constant groundHeight for consistency
    final groundHeight = game.size.y - game.groundY;
    final scaleFactor = groundHeight / sprite!.originalSize.y;

    // Set size with consistent scaling - this ensures no gaps
    size = Vector2(sprite!.originalSize.x * scaleFactor, groundHeight);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.x -= scrollSpeed * dt;

    // Queue-based system handles tile recycling in game logic
  }

  void updateSpeed(double newSpeed) {
    scrollSpeed = newSpeed;
  }
}
