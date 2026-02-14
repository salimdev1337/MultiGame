import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/core/game_registry.dart';
import 'package:multigame/core/game_interface.dart';

// Mock game definitions for testing
class MockGameDefinition extends BaseGameDefinition {
  @override
  final String id;

  @override
  final String displayName;

  @override
  final String description;

  @override
  final IconData icon;

  @override
  final String route;

  @override
  final bool isAvailable;

  @override
  final Color? color;

  @override
  final String category;

  @override
  final int? minScore;

  @override
  final int? maxScore;

  MockGameDefinition({
    required this.id,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.route,
    this.isAvailable = true,
    this.color,
    this.category = 'general',
    this.minScore,
    this.maxScore,
  });

  @override
  Widget createScreen() => const Placeholder();
}

void main() {
  late GameRegistry registry;

  setUp(() {
    // Create a fresh registry and clear it before each test
    registry = GameRegistry();
    registry.clear();
  });

  tearDown(() {
    // Clean up after each test
    registry.clear();
  });

  group('GameRegistry - Singleton pattern', () {
    test('returns same instance', () {
      final instance1 = GameRegistry();
      final instance2 = GameRegistry();

      expect(identical(instance1, instance2), true);
    });

    test('global gameRegistry instance is same as constructor', () {
      final instance = GameRegistry();
      expect(identical(instance, gameRegistry), true);
    });
  });

  group('GameRegistry - register', () {
    test('registers a game successfully', () {
      final game = MockGameDefinition(
        id: 'test_game',
        displayName: 'Test Game',
        description: 'A test game',
        icon: Icons.gamepad,
        route: '/test',
      );

      registry.register(game);

      expect(registry.hasGame('test_game'), true);
      expect(registry.gameCount, 1);
    });

    test('throws error when registering duplicate game ID', () {
      final game1 = MockGameDefinition(
        id: 'duplicate',
        displayName: 'Game 1',
        description: 'First game',
        icon: Icons.games,
        route: '/game1',
      );

      final game2 = MockGameDefinition(
        id: 'duplicate',
        displayName: 'Game 2',
        description: 'Second game',
        icon: Icons.gamepad,
        route: '/game2',
      );

      registry.register(game1);

      expect(() => registry.register(game2), throwsA(isA<ArgumentError>()));
    });

    test('registers multiple different games', () {
      final games = [
        MockGameDefinition(
          id: 'game1',
          displayName: 'Game 1',
          description: 'Desc 1',
          icon: Icons.games,
          route: '/1',
        ),
        MockGameDefinition(
          id: 'game2',
          displayName: 'Game 2',
          description: 'Desc 2',
          icon: Icons.gamepad,
          route: '/2',
        ),
        MockGameDefinition(
          id: 'game3',
          displayName: 'Game 3',
          description: 'Desc 3',
          icon: Icons.sports_esports,
          route: '/3',
        ),
      ];

      for (final game in games) {
        registry.register(game);
      }

      expect(registry.gameCount, 3);
      expect(registry.hasGame('game1'), true);
      expect(registry.hasGame('game2'), true);
      expect(registry.hasGame('game3'), true);
    });

    test('maintains registration order', () {
      final game1 = MockGameDefinition(
        id: 'first',
        displayName: 'First',
        description: 'D1',
        icon: Icons.looks_one,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'second',
        displayName: 'Second',
        description: 'D2',
        icon: Icons.looks_two,
        route: '/2',
      );
      final game3 = MockGameDefinition(
        id: 'third',
        displayName: 'Third',
        description: 'D3',
        icon: Icons.looks_3,
        route: '/3',
      );

      registry.register(game1);
      registry.register(game2);
      registry.register(game3);

      final allGames = registry.getAllGames();
      expect(allGames[0].id, 'first');
      expect(allGames[1].id, 'second');
      expect(allGames[2].id, 'third');
    });
  });

  group('GameRegistry - unregister', () {
    test('unregisters a game successfully', () {
      final game = MockGameDefinition(
        id: 'temp_game',
        displayName: 'Temp',
        description: 'Desc',
        icon: Icons.gamepad,
        route: '/temp',
      );

      registry.register(game);
      expect(registry.hasGame('temp_game'), true);

      registry.unregister('temp_game');
      expect(registry.hasGame('temp_game'), false);
      expect(registry.gameCount, 0);
    });

    test('unregister removes from registration order', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );
      final game3 = MockGameDefinition(
        id: 'game3',
        displayName: 'Game 3',
        description: 'D3',
        icon: Icons.sports,
        route: '/3',
      );

      registry.register(game1);
      registry.register(game2);
      registry.register(game3);

      registry.unregister('game2');

      final allGames = registry.getAllGames();
      expect(allGames.length, 2);
      expect(allGames[0].id, 'game1');
      expect(allGames[1].id, 'game3');
    });

    test('unregister non-existent game does not throw error', () {
      expect(() => registry.unregister('nonexistent'), returnsNormally);
    });
  });

  group('GameRegistry - getGame', () {
    test('retrieves registered game by ID', () {
      final game = MockGameDefinition(
        id: 'puzzle',
        displayName: 'Puzzle Game',
        description: 'Slide tiles',
        icon: Icons.extension,
        route: '/puzzle',
      );

      registry.register(game);

      final retrieved = registry.getGame('puzzle');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'puzzle');
      expect(retrieved.displayName, 'Puzzle Game');
    });

    test('returns null for non-existent game', () {
      final retrieved = registry.getGame('nonexistent');
      expect(retrieved, isNull);
    });

    test('retrieves correct game when multiple are registered', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );

      registry.register(game1);
      registry.register(game2);

      final retrieved = registry.getGame('game2');
      expect(retrieved!.displayName, 'Game 2');
    });
  });

  group('GameRegistry - getAllGames', () {
    test('returns empty list when no games registered', () {
      final allGames = registry.getAllGames();
      expect(allGames, isEmpty);
    });

    test('returns all registered games', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );

      registry.register(game1);
      registry.register(game2);

      final allGames = registry.getAllGames();
      expect(allGames.length, 2);
    });

    test('maintains registration order', () {
      final game1 = MockGameDefinition(
        id: 'first',
        displayName: 'First',
        description: 'D1',
        icon: Icons.looks_one,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'second',
        displayName: 'Second',
        description: 'D2',
        icon: Icons.looks_two,
        route: '/2',
      );
      final game3 = MockGameDefinition(
        id: 'third',
        displayName: 'Third',
        description: 'D3',
        icon: Icons.looks_3,
        route: '/3',
      );

      registry.register(game1);
      registry.register(game2);
      registry.register(game3);

      final allGames = registry.getAllGames();
      expect(allGames[0].id, 'first');
      expect(allGames[1].id, 'second');
      expect(allGames[2].id, 'third');
    });
  });

  group('GameRegistry - getAvailableGames', () {
    test('returns only available games', () {
      final available = MockGameDefinition(
        id: 'available',
        displayName: 'Available Game',
        description: 'Desc',
        icon: Icons.check,
        route: '/available',
        isAvailable: true,
      );

      final unavailable = MockGameDefinition(
        id: 'unavailable',
        displayName: 'Unavailable Game',
        description: 'Desc',
        icon: Icons.close,
        route: '/unavailable',
        isAvailable: false,
      );

      registry.register(available);
      registry.register(unavailable);

      final availableGames = registry.getAvailableGames();
      expect(availableGames.length, 1);
      expect(availableGames[0].id, 'available');
    });

    test('returns empty list when no games are available', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
        isAvailable: false,
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
        isAvailable: false,
      );

      registry.register(game1);
      registry.register(game2);

      final availableGames = registry.getAvailableGames();
      expect(availableGames, isEmpty);
    });

    test('returns all games when all are available', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
        isAvailable: true,
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
        isAvailable: true,
      );

      registry.register(game1);
      registry.register(game2);

      final availableGames = registry.getAvailableGames();
      expect(availableGames.length, 2);
    });
  });

  group('GameRegistry - getGamesByCategory', () {
    test('returns games in specified category', () {
      final puzzle1 = MockGameDefinition(
        id: 'puzzle1',
        displayName: 'Puzzle 1',
        description: 'D1',
        icon: Icons.extension,
        route: '/p1',
        category: 'puzzle',
      );
      final puzzle2 = MockGameDefinition(
        id: 'puzzle2',
        displayName: 'Puzzle 2',
        description: 'D2',
        icon: Icons.grid_4x4,
        route: '/p2',
        category: 'puzzle',
      );
      final arcade = MockGameDefinition(
        id: 'arcade1',
        displayName: 'Arcade 1',
        description: 'D3',
        icon: Icons.gamepad,
        route: '/a1',
        category: 'arcade',
      );

      registry.register(puzzle1);
      registry.register(puzzle2);
      registry.register(arcade);

      final puzzleGames = registry.getGamesByCategory('puzzle');
      expect(puzzleGames.length, 2);
      expect(puzzleGames[0].category, 'puzzle');
      expect(puzzleGames[1].category, 'puzzle');
    });

    test('returns empty list for non-existent category', () {
      final game = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
        category: 'puzzle',
      );
      registry.register(game);

      final strategyGames = registry.getGamesByCategory('strategy');
      expect(strategyGames, isEmpty);
    });

    test('returns empty list when no games registered', () {
      final games = registry.getGamesByCategory('puzzle');
      expect(games, isEmpty);
    });
  });

  group('GameRegistry - hasGame', () {
    test('returns true for registered game', () {
      final game = MockGameDefinition(
        id: 'test',
        displayName: 'Test',
        description: 'D',
        icon: Icons.gamepad,
        route: '/test',
      );
      registry.register(game);

      expect(registry.hasGame('test'), true);
    });

    test('returns false for non-existent game', () {
      expect(registry.hasGame('nonexistent'), false);
    });

    test('returns false after game is unregistered', () {
      final game = MockGameDefinition(
        id: 'temp',
        displayName: 'Temp',
        description: 'D',
        icon: Icons.gamepad,
        route: '/temp',
      );
      registry.register(game);

      registry.unregister('temp');
      expect(registry.hasGame('temp'), false);
    });
  });

  group('GameRegistry - gameCount', () {
    test('returns 0 for empty registry', () {
      expect(registry.gameCount, 0);
    });

    test('returns correct count after registrations', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );
      final game3 = MockGameDefinition(
        id: 'game3',
        displayName: 'Game 3',
        description: 'D3',
        icon: Icons.sports,
        route: '/3',
      );

      registry.register(game1);
      expect(registry.gameCount, 1);

      registry.register(game2);
      expect(registry.gameCount, 2);

      registry.register(game3);
      expect(registry.gameCount, 3);
    });

    test('decrements after unregistration', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );

      registry.register(game1);
      registry.register(game2);
      expect(registry.gameCount, 2);

      registry.unregister('game1');
      expect(registry.gameCount, 1);
    });
  });

  group('GameRegistry - clear', () {
    test('clears all registered games', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );

      registry.register(game1);
      registry.register(game2);
      expect(registry.gameCount, 2);

      registry.clear();
      expect(registry.gameCount, 0);
      expect(registry.hasGame('game1'), false);
      expect(registry.hasGame('game2'), false);
    });

    test('allows re-registration after clear', () {
      final game = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );

      registry.register(game);
      registry.clear();

      // Should be able to register again
      expect(() => registry.register(game), returnsNormally);
      expect(registry.hasGame('game1'), true);
    });

    test('clears registration order', () {
      final game1 = MockGameDefinition(
        id: 'game1',
        displayName: 'Game 1',
        description: 'D1',
        icon: Icons.games,
        route: '/1',
      );
      final game2 = MockGameDefinition(
        id: 'game2',
        displayName: 'Game 2',
        description: 'D2',
        icon: Icons.gamepad,
        route: '/2',
      );

      registry.register(game1);
      registry.register(game2);

      registry.clear();

      expect(registry.getAllGames(), isEmpty);
    });
  });

  group('GameRegistry - Complex game properties', () {
    test('stores and retrieves game with all properties', () {
      final game = MockGameDefinition(
        id: 'complex_game',
        displayName: 'Complex Game',
        description: 'A game with all properties',
        icon: Icons.star,
        route: '/complex',
        isAvailable: true,
        color: Colors.blue,
        category: 'puzzle',
        minScore: 0,
        maxScore: 10000,
      );

      registry.register(game);

      final retrieved = registry.getGame('complex_game');
      expect(retrieved!.displayName, 'Complex Game');
      expect(retrieved.description, 'A game with all properties');
      expect(retrieved.icon, Icons.star);
      expect(retrieved.route, '/complex');
      expect(retrieved.isAvailable, true);
      expect(retrieved.color, Colors.blue);
      expect(retrieved.category, 'puzzle');
      expect(retrieved.minScore, 0);
      expect(retrieved.maxScore, 10000);
    });

    test('handles game with null optional properties', () {
      final game = MockGameDefinition(
        id: 'minimal_game',
        displayName: 'Minimal Game',
        description: 'Minimal props',
        icon: Icons.games,
        route: '/minimal',
      );

      registry.register(game);

      final retrieved = registry.getGame('minimal_game');
      expect(retrieved!.color, isNull);
      expect(retrieved.minScore, isNull);
      expect(retrieved.maxScore, isNull);
    });
  });
}
