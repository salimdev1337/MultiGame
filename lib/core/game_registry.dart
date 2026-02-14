import 'game_interface.dart';

/// Singleton registry for all games
/// Games register themselves on app startup
class GameRegistry {
  static final GameRegistry _instance = GameRegistry._internal();
  factory GameRegistry() => _instance;
  GameRegistry._internal();

  final Map<String, GameDefinition> _games = {};
  final List<String> _registrationOrder = [];

  /// Register a game with the registry
  void register(GameDefinition game) {
    if (_games.containsKey(game.id)) {
      throw ArgumentError('Game with id "${game.id}" is already registered');
    }
    _games[game.id] = game;
    _registrationOrder.add(game.id);
  }

  /// Unregister a game (mainly for testing)
  void unregister(String gameId) {
    _games.remove(gameId);
    _registrationOrder.remove(gameId);
  }

  /// Get a game by ID
  GameDefinition? getGame(String id) => _games[id];

  /// Get all registered games in registration order
  List<GameDefinition> getAllGames() {
    return _registrationOrder.map((id) => _games[id]!).toList();
  }

  /// Get all available games
  List<GameDefinition> getAvailableGames() {
    return getAllGames().where((game) => game.isAvailable).toList();
  }

  /// Get games by category
  List<GameDefinition> getGamesByCategory(String category) {
    return getAllGames().where((game) => game.category == category).toList();
  }

  /// Check if a game is registered
  bool hasGame(String id) => _games.containsKey(id);

  /// Get total number of registered games
  int get gameCount => _games.length;

  /// Clear all registrations (mainly for testing)
  void clear() {
    _games.clear();
    _registrationOrder.clear();
  }
}

/// Global instance for easy access
final gameRegistry = GameRegistry();
