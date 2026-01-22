import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/player.dart';
import 'components/obstacle.dart';
import 'components/ground.dart';
import 'components/parallax_background.dart';
import 'state/game_state.dart';
import 'systems/collision_system.dart';
import 'systems/spawn_system.dart';
import 'systems/obstacle_pool.dart';

/// Main infinite runner game using Flame engine
/// Optimized for 60 FPS with object pooling and clean architecture
class InfiniteRunnerGame extends FlameGame
    with DragCallbacks, HasCollisionDetection, KeyboardEvents {
  InfiniteRunnerGame() : super();

  // Game state
  GameState _gameState = GameState.idle;
  GameState get gameState => _gameState;

  // Components
  late Player _player;
  late ParallaxBackground _background;
  final List<GroundTile> _groundTiles = [];
  final List<Obstacle> _obstacles = [];

  // Systems
  late CollisionSystem _collisionSystem;
  late SpawnSystem _spawnSystem;
  late ObstaclePool _obstaclePool;

  // Scoring
  double _score = 0.0;
  int _highScore = 0;
  int get score => _score.floor();
  int get highScore => _highScore;

  // FPS tracking for debug
  int _fps = 0;
  double _fpsTimer = 0.0;
  int _frameCount = 0;
  int get fps => _fps;

  // Game speed
  final double _baseScrollSpeed = 250.0;
  double _currentScrollSpeed = 250.0;
  static const double maxScrollSpeed = 800.0;
  static const double speedIncreaseRate = 10.0; // Pixels per second increase

  // Ground configuration
  double get groundY => size.y * 0.82;

  // Player spawn position
  static const double playerSpawnX = 100.0;

  // Swipe detection
  Vector2? _dragStart;
  Vector2? _dragCurrent;
  static const double swipeThreshold = 50.0; // Minimum distance for swipe

  @override
  Color backgroundColor() => const Color(0xFF16181d);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize obstacle pool
    _obstaclePool = ObstaclePool(scrollSpeed: _currentScrollSpeed);

    // Initialize systems
    _collisionSystem = CollisionSystem(onCollision: _handleCollision);

    _spawnSystem = SpawnSystem(
      gameWidth: size.x,
      groundY: groundY,
      obstaclePool: _obstaclePool,
    );

    // Load high score
    await _loadHighScore();

    // Add background
    _background = ParallaxBackground(
      size: size,
      scrollSpeed: _currentScrollSpeed,
    );
    add(_background);

    // Add ground tiles
    await _initializeGround();

    // Add player
    _player = Player(
      position: Vector2(playerSpawnX, groundY),
      size: Vector2(40, 60),
      groundY: groundY,
    );
    add(_player);
    // Set initial state
    _gameState = GameState.idle;

    // Remove loading overlay and show idle overlay
    overlays.remove('loading');
    overlays.add('idle');
  }

  /// Initialize ground tiles for infinite scrolling with queue system
  Future<void> _initializeGround() async {
    // Create first tile to get the tile width
    final firstTile = GroundTile(
      position: Vector2(0, groundY),
      scrollSpeed: _currentScrollSpeed,
    );
    add(firstTile);
    await firstTile.loaded;
    _groundTiles.add(firstTile);

    // Create 9 more tiles, each positioned right after the previous one
    final tileWidth = firstTile.size.x;
    for (int i = 1; i < 10; i++) {
      final tile = GroundTile(
        position: Vector2(tileWidth * i, groundY),
        scrollSpeed: _currentScrollSpeed,
      );
      add(tile);
      _groundTiles.add(tile);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update FPS counter
    _frameCount++;
    _fpsTimer += dt;
    if (_fpsTimer >= 1.0) {
      _fps = _frameCount;
      _frameCount = 0;
      _fpsTimer = 0.0;
    }

    switch (_gameState) {
      case GameState.idle:
        // Waiting for player to start
        break;

      case GameState.playing:
        _updatePlaying(dt);
        break;

      case GameState.paused:
        // Game frozen
        break;

      case GameState.gameOver:
        // Game ended
        break;
    }
  }

  void _updatePlaying(double dt) {
    // Update score (distance based)
    _score += _currentScrollSpeed * dt * 0.01;

    // Gradually increase speed (difficulty progression)
    if (_currentScrollSpeed < maxScrollSpeed) {
      _currentScrollSpeed += speedIncreaseRate * dt;
      if (_currentScrollSpeed > maxScrollSpeed) {
        _currentScrollSpeed = maxScrollSpeed;
      }

      // Update all scrolling components (avoid frequent updates)
      _background.updateSpeed(_currentScrollSpeed);
      _obstaclePool.updateSpeed(_currentScrollSpeed);

      for (final ground in _groundTiles) {
        ground.updateSpeed(_currentScrollSpeed);
      }
      for (final obstacle in _obstacles) {
        obstacle.updateSpeed(_currentScrollSpeed);
      }
    }

    // Spawn obstacles using pool
    final newObstacle = _spawnSystem.update(
      dt,
      _currentScrollSpeed,
      _obstacles,
    );
    if (newObstacle != null) {
      _obstacles.add(newObstacle);
      add(newObstacle);
    }

    // Remove off-screen obstacles and return to pool
    _obstacles.removeWhere((obstacle) {
      if (obstacle.isOffScreen) {
        remove(obstacle);
        _obstaclePool.release(obstacle); // Return to pool
        return true;
      }
      return false;
    });

    // Queue-based ground tile management: pop from front, push to back
    if (_groundTiles.isNotEmpty &&
        _groundTiles.first.position.x + _groundTiles.first.size.x < 0) {
      // First tile is completely off-screen, remove it
      final oldTile = _groundTiles.removeAt(0);
      remove(oldTile);

      // Create new tile at the end of the queue
      final lastTile = _groundTiles.last;
      final newTile = GroundTile(
        position: Vector2(lastTile.position.x + lastTile.size.x, groundY),
        scrollSpeed: _currentScrollSpeed,
      );
      add(newTile);
      _groundTiles.add(newTile);
    }

    // Check collisions
    _collisionSystem.checkCollisions(_player, _obstacles);
  }

  /// Handle swipe start
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragStart = event.localPosition;
    _dragCurrent = event.localPosition;
  }

  /// Track drag movement
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragCurrent = event.localEndPosition;
  }

  /// Handle swipe end - detect direction
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_dragStart == null || _dragCurrent == null) return;

    final deltaY = _dragCurrent!.y - _dragStart!.y;

    // Check if swipe distance is sufficient
    if (deltaY.abs() < swipeThreshold) {
      _dragStart = null;
      return;
    }

    // Swipe up (negative deltaY)
    if (deltaY < 0) {
      switch (_gameState) {
        case GameState.idle:
          startGame();
          break;
        case GameState.playing:
          _player.jump();
          break;
        case GameState.paused:
        case GameState.gameOver:
          // Handled by overlay buttons
          break;
      }
    }
    // Swipe down (positive deltaY)
    else {
      if (_gameState == GameState.playing && !_player.isOnGround) {
        _player.fastDrop();
      }
    }

    _dragStart = null;
  }

  /// Handle keyboard input
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      // Up arrow - jump
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_gameState == GameState.idle) {
          startGame();
        } else if (_gameState == GameState.playing) {
          _player.jump();
        }
        return KeyEventResult.handled;
      }
      // Down arrow - fast drop when in air
      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_gameState == GameState.playing && !_player.isOnGround) {
          _player.fastDrop();
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Start the game
  void startGame() {
    _gameState = GameState.playing;
    _score = 0.0;
    _currentScrollSpeed = _baseScrollSpeed;
    _player.reset();
    _collisionSystem.reset();
    _spawnSystem.reset();

    // Clear existing obstacles and return to pool
    for (final obstacle in _obstacles) {
      remove(obstacle);
      _obstaclePool.release(obstacle);
    }
    _obstacles.clear();

    overlays.remove('idle');
    overlays.add('hud');
  }

  /// Pause the game
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      overlays.remove('hud');
      overlays.add('paused');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      overlays.remove('paused');
      overlays.add('hud');
    }
  }

  /// Handle collision
  void _handleCollision() {
    _gameState = GameState.gameOver;
    _player.die(); // Set player to dead state

    // Update high score
    if (score > _highScore) {
      _highScore = score;
      _saveHighScore();
    }

    overlays.remove('hud');
    overlays.add('gameOver');
  }

  /// Restart the game
  void restart() {
    overlays.remove('gameOver');
    startGame();
  }

  /// Load high score from storage
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('infinite_runner_high_score') ?? 0;
  }

  /// Save high score to storage
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('infinite_runner_high_score', _highScore);
  }

  /// Handle app lifecycle changes
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Auto-pause when app goes to background
        if (_gameState == GameState.playing) {
          pauseGame();
        }
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.hidden:
        // Don't auto-resume - let player tap to resume
        break;
    }
  }

  @override
  void onRemove() {
    // Clean up all components
    for (final obstacle in _obstacles) {
      obstacle.removeFromParent();
    }
    _obstacles.clear();

    for (final ground in _groundTiles) {
      ground.removeFromParent();
    }
    _groundTiles.clear();

    _player.removeFromParent();
    _background.removeFromParent();

    // Clear object pool
    _obstaclePool.clear();

    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Only recalculate if game is fully loaded
    if (isLoaded) {
      _updatePositionsForNewSize();
    }
  }

  /// Update all game element positions based on new screen size
  void _updatePositionsForNewSize() {
    // Check if components are initialized before updating
    if (!isLoaded) return;

    // Update background size
    _background.size = size;
    _background.updateForResize(size);

    // Update ground positions
    _updateGroundForResize();

    // Update player position to always be on the ground
    final newGroundY = groundY;
    _player.updateGroundY(newGroundY);

    // Update spawn system with new dimensions
    _spawnSystem.updateDimensions(size.x, groundY);

    // Clear and reposition any existing obstacles
    for (final obstacle in _obstacles) {
      remove(obstacle);
      _obstaclePool.release(obstacle);
    }
    _obstacles.clear();
  }

  void _updateGroundForResize() {
    for (final ground in _groundTiles) {
      remove(ground);
    }
    _groundTiles.clear();

    _initializeGround();
  }
}
