import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/models/game_model.dart';

void main() {
  group('GameModel', () {
    test('creates game with all properties', () {
      final game = GameModel(
        id: 'test_game',
        name: 'Test Game',
        description: 'Test description',
        imagePath: 'test/path.jpg',
        isAvailable: true,
      );

      expect(game.id, 'test_game');
      expect(game.name, 'Test Game');
      expect(game.description, 'Test description');
      expect(game.imagePath, 'test/path.jpg');
      expect(game.isAvailable, true);
    });

    test('getAvailableGames returns list of games', () {
      final games = GameModel.getAvailableGames();

      expect(games.length, 3);
      expect(games[0].id, 'image_puzzle');
      expect(games[1].id, 'number_puzzle');
      expect(games[2].id, 'memory_game');
    });

    test('image_puzzle is available', () {
      final games = GameModel.getAvailableGames();
      final imagePuzzle = games.firstWhere((g) => g.id == 'image_puzzle');

      expect(imagePuzzle.name, 'Image Puzzle');
      expect(imagePuzzle.isAvailable, true);
      expect(imagePuzzle.description, 'Slide tiles to complete the picture');
    });

    test('other games are not available yet', () {
      final games = GameModel.getAvailableGames();
      final numberPuzzle = games.firstWhere((g) => g.id == 'number_puzzle');
      final memoryGame = games.firstWhere((g) => g.id == 'memory_game');

      expect(numberPuzzle.isAvailable, false);
      expect(memoryGame.isAvailable, false);
    });
  });
}
