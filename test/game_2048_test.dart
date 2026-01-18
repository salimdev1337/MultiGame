import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/services/achievement_service.dart';

// Mock class to test 2048 game logic
class Game2048Logic {
  List<List<int>> grid;
  int score = 0;
  bool gameOver = false;

  Game2048Logic() : grid = List.generate(4, (_) => List.filled(4, 0));

  // Initialize grid with specific values for testing
  void setGrid(List<List<int>> newGrid) {
    grid = List.generate(4, (i) => List.generate(4, (j) => newGrid[i][j]));
  }

  // Check if any moves are possible
  bool canMove() {
    // Check for empty cells
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return true;
      }
    }

    // Check for possible merges horizontally
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[i][j] == grid[i][j + 1]) return true;
      }
    }

    // Check for possible merges vertically
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == grid[i + 1][j]) return true;
      }
    }

    return false;
  }

  // Get highest tile value
  int getHighestTile() {
    int highest = 0;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] > highest) {
          highest = grid[i][j];
        }
      }
    }
    return highest;
  }

  // Move left logic
  bool moveLeft() {
    bool moved = false;
    for (int i = 0; i < 4; i++) {
      List<int> row = grid[i].where((cell) => cell != 0).toList();
      List<int> newRow = [];

      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          int merged = row[j] * 2;
          newRow.add(merged);
          score += merged;
          j += 2;
        } else {
          newRow.add(row[j]);
          j++;
        }
      }

      while (newRow.length < 4) {
        newRow.add(0);
      }

      if (grid[i].toString() != newRow.toString()) {
        moved = true;
      }
      grid[i] = newRow;
    }
    return moved;
  }

  // Move right logic
  bool moveRight() {
    bool moved = false;
    for (int i = 0; i < 4; i++) {
      List<int> row = grid[i]
          .where((cell) => cell != 0)
          .toList()
          .reversed
          .toList();
      List<int> newRow = [];

      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          int merged = row[j] * 2;
          newRow.add(merged);
          score += merged;
          j += 2;
        } else {
          newRow.add(row[j]);
          j++;
        }
      }

      while (newRow.length < 4) {
        newRow.add(0);
      }

      newRow = newRow.reversed.toList();
      if (grid[i].toString() != newRow.toString()) {
        moved = true;
      }
      grid[i] = newRow;
    }
    return moved;
  }

  // Move up logic
  bool moveUp() {
    bool moved = false;
    for (int j = 0; j < 4; j++) {
      List<int> column = [];
      for (int i = 0; i < 4; i++) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }

      List<int> newColumn = [];
      int i = 0;
      while (i < column.length) {
        if (i + 1 < column.length && column[i] == column[i + 1]) {
          int merged = column[i] * 2;
          newColumn.add(merged);
          score += merged;
          i += 2;
        } else {
          newColumn.add(column[i]);
          i++;
        }
      }

      while (newColumn.length < 4) {
        newColumn.add(0);
      }

      for (int i = 0; i < 4; i++) {
        if (grid[i][j] != newColumn[i]) {
          moved = true;
        }
        grid[i][j] = newColumn[i];
      }
    }
    return moved;
  }

  // Move down logic
  bool moveDown() {
    bool moved = false;
    for (int j = 0; j < 4; j++) {
      List<int> column = [];
      for (int i = 3; i >= 0; i--) {
        if (grid[i][j] != 0) {
          column.add(grid[i][j]);
        }
      }

      List<int> newColumn = [];
      int i = 0;
      while (i < column.length) {
        if (i + 1 < column.length && column[i] == column[i + 1]) {
          int merged = column[i] * 2;
          newColumn.add(merged);
          score += merged;
          i += 2;
        } else {
          newColumn.add(column[i]);
          i++;
        }
      }

      while (newColumn.length < 4) {
        newColumn.add(0);
      }

      for (int i = 0; i < 4; i++) {
        if (grid[3 - i][j] != newColumn[i]) {
          moved = true;
        }
        grid[3 - i][j] = newColumn[i];
      }
    }
    return moved;
  }

  // Check if grid is full
  bool isGridFull() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return false;
      }
    }
    return true;
  }
}

void main() {
  group('2048 Game Logic Tests', () {
    late Game2048Logic game;

    setUp(() {
      game = Game2048Logic();
    });

    test('Initial grid should be empty', () {
      expect(game.grid.expand((row) => row).every((cell) => cell == 0), true);
      expect(game.score, 0);
      expect(game.gameOver, false);
    });

    test('Move left should merge tiles correctly', () {
      game.setGrid([
        [2, 2, 0, 0],
        [4, 4, 4, 0],
        [2, 0, 2, 0],
        [0, 0, 0, 0],
      ]);

      game.moveLeft();

      expect(game.grid[0], [4, 0, 0, 0]); // 2+2 = 4
      expect(game.grid[1], [8, 4, 0, 0]); // 4+4 = 8, then 4 remains
      expect(game.grid[2], [4, 0, 0, 0]); // 2+2 = 4
      expect(game.score, 16); // 4 + 8 + 4 = 16
    });

    test('Move right should merge tiles correctly', () {
      game.setGrid([
        [0, 0, 2, 2],
        [0, 4, 4, 4],
        [0, 2, 0, 2],
        [0, 0, 0, 0],
      ]);

      game.moveRight();

      expect(game.grid[0], [0, 0, 0, 4]); // 2+2 = 4
      expect(game.grid[1], [0, 0, 4, 8]); // 4+4 = 8, then 4 remains
      expect(game.grid[2], [0, 0, 0, 4]); // 2+2 = 4
      expect(game.score, 16); // 4 + 8 + 4 = 16
    });

    test('Move up should merge tiles correctly', () {
      game.setGrid([
        [2, 4, 2, 0],
        [2, 4, 0, 0],
        [0, 4, 2, 0],
        [0, 0, 0, 0],
      ]);

      game.moveUp();

      expect(game.grid[0][0], 4); // 2+2 = 4
      expect(game.grid[0][1], 8); // 4+4 = 8
      expect(game.grid[1][1], 4); // remaining 4
      expect(game.grid[0][2], 4); // 2+2 = 4
      expect(game.score, 16); // 4 + 8 + 4 = 16
    });

    test('Move down should merge tiles correctly', () {
      game.setGrid([
        [0, 0, 0, 0],
        [2, 4, 2, 0],
        [2, 4, 0, 0],
        [0, 4, 2, 0],
      ]);

      game.moveDown();

      expect(game.grid[3][0], 4); // 2+2 = 4
      expect(game.grid[3][1], 8); // 4+4 = 8
      expect(game.grid[2][1], 4); // remaining 4
      expect(game.grid[3][2], 4); // 2+2 = 4
      expect(game.score, 16); // 4 + 8 + 4 = 16
    });

    test('Should detect when no moves are possible (lose condition)', () {
      game.setGrid([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);

      expect(game.canMove(), false);
      expect(game.isGridFull(), true);
    });

    test('Should detect when moves are still possible', () {
      game.setGrid([
        [2, 2, 4, 8],
        [4, 8, 16, 32],
        [2, 4, 8, 16],
        [0, 0, 0, 0],
      ]);

      expect(game.canMove(), true); // Has empty cells
    });

    test('Should detect when adjacent tiles can merge', () {
      game.setGrid([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 4], // Last two 4s can merge
      ]);

      expect(game.canMove(), true); // Can merge 4+4 in last row
    });

    test('Should get highest tile correctly', () {
      game.setGrid([
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2048, 4],
        [2, 4, 8, 16],
      ]);

      expect(game.getHighestTile(), 2048);
    });

    test('Should detect win condition when reaching 2048', () {
      game.setGrid([
        [2048, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2, 4],
        [2, 4, 8, 16],
      ]);

      expect(game.getHighestTile(), 2048);
      expect(game.getHighestTile() >= 2048, true); // Win condition
    });

    test('Should not allow moves when grid is full and no merges possible', () {
      game.setGrid([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);

      expect(game.isGridFull(), true);
      expect(game.canMove(), false);
    });

    test('Multiple moves should accumulate score correctly', () {
      game.setGrid([
        [2, 2, 4, 4],
        [2, 2, 4, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      game.moveLeft();
      // Row 0: [4, 8, 0, 0] scores: 4 + 8 = 12
      // Row 1: [4, 8, 0, 0] scores: 4 + 8 = 12
      // Total: 24

      expect(game.score, 24);

      game.moveLeft(); // Should not change anything
      expect(game.score, 24); // Score remains the same
    });
  });

  group('Achievement Service Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Should save 2048 achievement correctly', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 5000,
        highestTile: 512,
        levelPassed: 'Medium',
      );

      final stats = await service.get2048Stats();
      expect(stats['bestScore'], 5000);
      expect(stats['highestTile'], 512);
      expect(stats['lastLevelPassed'], 'Medium');
      expect(stats['gamesPlayed'], 1);
    });

    test('Should update best score when new score is higher', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 3000,
        highestTile: 256,
        levelPassed: 'Easy',
      );

      await service.save2048Achievement(
        score: 5000,
        highestTile: 512,
        levelPassed: 'Medium',
      );

      final stats = await service.get2048Stats();
      expect(stats['bestScore'], 5000); // Should be updated
      expect(stats['highestTile'], 512); // Should be updated
      expect(stats['gamesPlayed'], 2); // Should increment
    });

    test('Should not decrease best score', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 5000,
        highestTile: 512,
        levelPassed: 'Medium',
      );

      await service.save2048Achievement(
        score: 3000,
        highestTile: 256,
        levelPassed: 'Easy',
      );

      final stats = await service.get2048Stats();
      expect(stats['bestScore'], 5000); // Should remain at higher value
      expect(stats['highestTile'], 512); // Should remain at higher value
    });

    test('Should unlock 2048_beginner achievement at 512 tile', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 3000,
        highestTile: 512,
        levelPassed: 'Medium',
      );

      final achievements = await service.getAchievements();
      expect(achievements['2048_beginner'], true);
      expect(achievements['2048_intermediate'], false);
    });

    test('Should unlock 2048_intermediate achievement at 1024 tile', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 10000,
        highestTile: 1024,
        levelPassed: 'Hard',
      );

      final achievements = await service.getAchievements();
      expect(achievements['2048_beginner'], true);
      expect(achievements['2048_intermediate'], true);
      expect(achievements['2048_advanced'], false);
    });

    test('Should unlock 2048_advanced achievement at 2048 tile', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 20000,
        highestTile: 2048,
        levelPassed: 'Expert',
      );

      final achievements = await service.getAchievements();
      expect(achievements['2048_beginner'], true);
      expect(achievements['2048_intermediate'], true);
      expect(achievements['2048_advanced'], true);
      expect(achievements['2048_master'], false);
    });

    test('Should unlock 2048_master achievement at 4096 tile', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 50000,
        highestTile: 4096,
        levelPassed: 'Expert',
      );

      final achievements = await service.getAchievements();
      expect(achievements['2048_beginner'], true);
      expect(achievements['2048_intermediate'], true);
      expect(achievements['2048_advanced'], true);
      expect(achievements['2048_master'], true);
    });

    test('Should track games played correctly', () async {
      final service = AchievementService();

      for (int i = 0; i < 5; i++) {
        await service.save2048Achievement(
          score: 1000 * i,
          highestTile: 128,
          levelPassed: 'Easy',
        );
      }

      final stats = await service.get2048Stats();
      expect(stats['gamesPlayed'], 5);
    });

    test('Should reset all stats correctly', () async {
      final service = AchievementService();

      await service.save2048Achievement(
        score: 5000,
        highestTile: 2048,
        levelPassed: 'Expert',
      );

      await service.resetAll();

      final stats = await service.get2048Stats();
      expect(stats['bestScore'], 0);
      expect(stats['highestTile'], 0);
      expect(stats['gamesPlayed'], 0);
      expect(stats['lastLevelPassed'], 'None');

      final achievements = await service.getAchievements();
      expect(achievements['2048_beginner'], false);
      expect(achievements['2048_intermediate'], false);
      expect(achievements['2048_advanced'], false);
      expect(achievements['2048_master'], false);
    });
  });

  group('Win and Lose Scenarios', () {
    late Game2048Logic game;

    setUp(() {
      game = Game2048Logic();
    });

    test('Win scenario: reaching 256 (minimum objective)', () {
      game.setGrid([
        [256, 4, 8, 16],
        [32, 64, 2, 4],
        [2, 4, 8, 16],
        [0, 0, 0, 0],
      ]);

      expect(game.getHighestTile(), 256);
      expect(game.getHighestTile() >= 256, true); // Minimum objective reached
      expect(game.canMove(), true); // Can still play
    });

    test('Lose scenario: grid full, no moves, did not reach minimum', () {
      game.setGrid([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);

      expect(game.getHighestTile(), 4);
      expect(game.getHighestTile() < 256, true); // Did not reach minimum
      expect(game.isGridFull(), true);
      expect(game.canMove(), false); // Game over
    });

    test('Lose scenario: grid full, no moves, even with higher tiles', () {
      game.setGrid([
        [2, 4, 8, 16],
        [16, 8, 4, 2],
        [2, 4, 8, 16],
        [16, 8, 4, 2],
      ]);

      expect(game.getHighestTile(), 16);
      expect(game.getHighestTile() < 256, true); // Did not reach minimum
      expect(game.isGridFull(), true);
      expect(game.canMove(), false); // Game over
    });

    test('Continue playing: reached 512 but grid not full', () {
      game.setGrid([
        [512, 4, 8, 16],
        [32, 64, 128, 0],
        [2, 4, 8, 0],
        [0, 0, 0, 0],
      ]);

      expect(game.getHighestTile(), 512);
      expect(game.getHighestTile() >= 512, true); // Medium objective reached
      expect(game.canMove(), true); // Can continue playing
      expect(game.isGridFull(), false); // Grid not full yet
    });

    test('Ultimate win: reached 2048 and grid is full', () {
      game.setGrid([
        [2048, 1024, 512, 256],
        [64, 128, 32, 16],
        [8, 4, 2, 64],
        [2, 8, 16, 4],
      ]);

      expect(game.getHighestTile(), 2048);
      expect(game.getHighestTile() >= 2048, true); // Expert objective reached
      expect(game.isGridFull(), true);
      expect(game.canMove(), false); // Grid full, show win dialog
    });
  });
}
