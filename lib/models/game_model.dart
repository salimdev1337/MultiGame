class GameModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final bool isAvailable;

  GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.isAvailable,
  });

  static List<GameModel> getAvailableGames() {
    return [
      GameModel(
        id: 'snake_game',
        name: 'Snake',
        description: 'Classic snake game with neon style',
        imagePath: 'assets/images/snake.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'image_puzzle',
        name: 'Puzzle',
        description: 'Slide tiles to complete the picture',
        imagePath: 'assets/images/classic_puzzle_carousel_thumbnail.png',
        isAvailable: true,
      ),
      GameModel(
        id: '2048',
        name: '2048',
        description: 'Merge tiles to reach the goal!',
        imagePath: 'assets/images/2048_challenge_carousel_thumbnail.png',
        isAvailable: true,
      ),

      GameModel(
        id: 'memory_game',
        name: 'Memory Game',
        description: 'Match pairs to win',
        imagePath: 'assets/images/fallback_puzzle.jpg',
        isAvailable: false,
      ),
    ];
  }
}
