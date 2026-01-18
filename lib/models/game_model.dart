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
        id: 'image_puzzle',
        name: 'Image Puzzle',
        description: 'Slide tiles to complete the picture',
        imagePath: 'assets/images/fallback_puzzle.jpg',
        isAvailable: true,
      ),
      GameModel(
        id: '2048',
        name: '2048 Game',
        description: 'Merge tiles to reach the goal!',
        imagePath: 'assets/images/fallback_puzzle.jpg',
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
