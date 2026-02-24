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
        id: 'ludo',
        name: 'Ludo',
        description: 'Race tokens home — roll, capture, and use powerups!',
        imagePath: 'assets/images/ludo.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'sudoku',
        name: 'Sudoku',
        description: 'classic, rush and 1v1 sudoku games',
        imagePath: 'assets/images/sudoku.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'infinite_runner',
        name: 'Infinite Runner',
        description: 'Run, jump and avoid obstacles!',
        imagePath: 'assets/images/runner_thumbnail.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'bomberman',
        name: 'Bomberman',
        description: 'Drop bombs, destroy blocks, blast your opponents!',
        imagePath: 'assets/images/bomberman.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'wordle',
        name: 'Wordle Duel',
        description: 'Solo or 2-player head-to-head word guessing duel',
        imagePath: 'assets/images/wordle.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'rpg',
        name: 'Shadowfall Chronicles',
        description: 'Fight pixel-art bosses, grow stronger, conquer New Game+',
        imagePath: 'assets/images/rpg.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'snake_game',
        name: 'Snake',
        description: 'Classic snake game with neon style',
        imagePath: 'assets/images/snake.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'memory_game',
        name: 'Memory Game',
        description: 'Match pairs — wrong guess shuffles the board!',
        imagePath: 'assets/images/memory_game.png',
        isAvailable: true,
      ),
      GameModel(
        id: '2048',
        name: '2048',
        description: 'Merge tiles to reach the goal!',
        imagePath: 'assets/images/2048_thumbnail.png',
        isAvailable: true,
      ),

      GameModel(
        id: 'connect_four',
        name: 'Connect Four',
        description:
            'Drop pieces and connect 4 in a row — solo vs AI or pass-and-play',
        imagePath: 'assets/images/connect_four.png',
        isAvailable: true,
      ),
      GameModel(
        id: 'image_puzzle',
        name: 'Puzzle',
        description: 'Slide tiles to complete the picture',
        imagePath: 'assets/images/puzzle.png',
        isAvailable: true,
      ),
    ];
  }
}
