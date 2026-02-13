import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'abilities/ability_pickup.dart';
import 'abilities/ability_type.dart';
import 'components/player.dart';
import 'components/obstacle.dart';
import 'components/ground.dart';
import 'components/ghost_player.dart';
import 'components/parallax_background.dart';
import 'multiplayer/race_client.dart';
import 'multiplayer/race_player_state.dart';
import 'multiplayer/race_room.dart';
import 'state/game_state.dart';
import 'state/game_mode.dart';
import 'systems/collision_system.dart';
import 'systems/spawn_system.dart';
import 'systems/obstacle_pool.dart';

/// Main infinite runner game using Flame engine
/// Optimized for 60 FPS with object pooling and clean architecture
class InfiniteRunnerGame extends FlameGame
    with DragCallbacks, HasCollisionDetection, KeyboardEvents {
  InfiniteRunnerGame({
    this.gameMode = GameMode.solo,
    this.raceClient,
    this.raceRoom,
  }) : super();

  /// Whether this is a solo run or a multiplayer race
  final GameMode gameMode;

  /// Multiplayer client — non-null when racing with others over local WiFi
  final RaceClient? raceClient;

  /// Shared room state — non-null when racing with others
  final RaceRoom? raceRoom;

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

  // Race mode fields
  static const double trackLength = 10000.0;
  double _distanceTraveled = 0.0;
  double get distanceTraveled => _distanceTraveled;
  int _finishTimeSeconds = 0;
  int get finishTimeSeconds => _finishTimeSeconds;
  int _raceStartMs = 0;
  // Last effective speed propagated to components (avoids redundant calls)
  double _lastPropagatedSpeed = 0.0;
  bool get isPlayerSlowed => _player.speedMultiplier < 1.0;
  bool get isPlayerBoosted => _player.speedMultiplier > 1.0;
  bool get playerHasShield => _player.hasShield;
  AbilityType? get playerHeldAbility => _player.heldAbility;

  // Active ability pickups on the track
  final List<AbilityPickup> _abilityPickups = [];

  // Multiplayer: ghost opponents
  final Map<int, GhostPlayer> _ghosts = {};
  // Colours per player slot (0=host cyan, 1=gold, 2=purple, 3=orange)
  static const List<Color> _playerColors = [
    Color(0xFF00d4ff),
    Color(0xFFffd700),
    Color(0xFF7c4dff),
    Color(0xFFff6b35),
  ];

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
    for (int i = 1; i < 20; i++) {
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
      case GameState.countdown:
      case GameState.paused:
      case GameState.gameOver:
      case GameState.finished:
        break;
      case GameState.playing:
        _updatePlaying(dt);
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
    }

    // In race mode, effective speed = base speed × player multiplier.
    // Propagate whenever the effective speed changes (slowdown start/end or speed increase).
    if (gameMode == GameMode.race) {
      final effective = _currentScrollSpeed * _player.speedMultiplier;
      if (effective != _lastPropagatedSpeed) {
        _propagateSpeed(effective);
        _lastPropagatedSpeed = effective;
      }
      _distanceTraveled += effective * dt;
      _checkFinishLine();

      // Update ghost positions from latest room state
      if (raceRoom != null) {
        for (final opponent in raceRoom!.opponents) {
          final ghost = _ghosts[opponent.playerId];
          if (ghost != null) {
            ghost.distanceDelta = opponent.distance - _distanceTraveled;
          }
        }
      }
    } else {
      // Solo mode: propagate base speed only while still increasing
      if (_currentScrollSpeed < maxScrollSpeed) {
        _background.updateSpeed(_currentScrollSpeed);
        _obstaclePool.updateSpeed(_currentScrollSpeed);
        for (final ground in _groundTiles) {
          ground.updateSpeed(_currentScrollSpeed);
        }
        for (final obstacle in _obstacles) {
          obstacle.updateSpeed(_currentScrollSpeed);
        }
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

    // Ability pickups (race mode only)
    if (gameMode == GameMode.race) {
      final newPickup = _spawnSystem.updatePickups(dt, _currentScrollSpeed);
      if (newPickup != null) {
        _abilityPickups.add(newPickup);
        add(newPickup);
      }

      // Check collection
      final collected = _collisionSystem.checkPickups(_player, _abilityPickups);
      if (collected != null) {
        _player.heldAbility = collected.type;
      }

      // Remove collected or off-screen pickups
      _abilityPickups.removeWhere((p) {
        if (p.isCollected || p.isOffScreen) {
          remove(p);
          return true;
        }
        return false;
      });
    }
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
          if (gameMode == GameMode.race) {
            startRace();
          } else {
            startGame();
          }
          break;
        case GameState.playing:
          _player.jump();
          break;
        case GameState.countdown:
        case GameState.paused:
        case GameState.gameOver:
        case GameState.finished:
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
          if (gameMode == GameMode.race) {
            startRace();
          } else {
            startGame();
          }
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
      final hudKey = gameMode == GameMode.race ? 'raceHud' : 'hud';
      overlays.remove(hudKey);
      overlays.add('paused');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      final hudKey = gameMode == GameMode.race ? 'raceHud' : 'hud';
      overlays.remove('paused');
      overlays.add(hudKey);
    }
  }

  /// Propagate a speed value to all scrolling components
  void _propagateSpeed(double speed) {
    _background.updateSpeed(speed);
    _obstaclePool.updateSpeed(speed);
    for (final ground in _groundTiles) {
      ground.updateSpeed(speed);
    }
    for (final obstacle in _obstacles) {
      obstacle.updateSpeed(speed);
    }
  }

  /// Check if player has reached the finish line (race mode only)
  void _checkFinishLine() {
    if (_distanceTraveled >= trackLength) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      _finishTimeSeconds = ((nowMs - _raceStartMs) / 1000).floor();
      _gameState = GameState.finished;

      // Notify network (multiplayer) or show local finish immediately (solo race)
      if (raceClient != null) {
        raceClient!.stopPositionBroadcast();
        raceClient!.sendFinish(nowMs - _raceStartMs);
        // Don't show finish overlay yet — wait for results from host
      } else {
        overlays.remove('raceHud');
        overlays.add('raceFinish');
      }
    }
  }

  /// Handle collision
  void _handleCollision() {
    if (gameMode == GameMode.race) {
      // Shield absorbs the hit
      if (_player.hasShield) {
        _player.hasShield = false;
        _collisionSystem.reset();
        return;
      }
      // Race mode: slow the player down, allow further collisions
      _player.applySpeedEffect(factor: 0.6, duration: 2.0);
      _collisionSystem.reset();
    } else {
      // Solo mode: game over
      _gameState = GameState.gameOver;
      _player.die();
      if (score > _highScore) {
        _highScore = score;
        _saveHighScore();
      }
      overlays.remove('hud');
      overlays.add('gameOver');
    }
  }

  /// Activate the player's currently held ability (race mode)
  void activateAbility() {
    final ability = _player.heldAbility;
    if (ability == null || _gameState != GameState.playing) return;
    _player.heldAbility = null;

    switch (ability) {
      case AbilityType.speedBoost:
        _player.applySpeedEffect(factor: 1.5, duration: 5.0);
      case AbilityType.shield:
        _player.activateShield();
      case AbilityType.slowField:
        // Broadcast so opponents ahead apply the slow to themselves
        // (In solo / Phase 2: no client, so apply locally as before)
        if (raceClient == null) {
          _player.applySpeedEffect(factor: 0.7, duration: 4.0);
        }
      case AbilityType.obstacleRain:
        _spawnObstacleRain();
    }

    // Broadcast to other players in multiplayer
    raceClient?.sendAbilityUsed(ability.name);
  }

  /// Force-spawn 3 obstacles ahead of the current position (obstacleRain ability)
  void _spawnObstacleRain() {
    final types = ObstacleType.values;
    for (int i = 0; i < 3; i++) {
      final type = types[i % types.length];
      final spawnXPos = size.x + 120 + i * 180.0;
      final obstacle = _obstaclePool.acquire(type, Vector2(spawnXPos, groundY));
      _obstacles.add(obstacle);
      add(obstacle);
    }
  }

  /// Restart solo game
  void restart() {
    overlays.remove('gameOver');
    startGame();
  }

  /// Begin countdown then race (race mode entry point)
  void startRace() {
    _distanceTraveled = 0.0;
    _lastPropagatedSpeed = 0.0;
    _score = 0.0;
    _currentScrollSpeed = _baseScrollSpeed;
    _player.reset();
    _collisionSystem.reset();
    _spawnSystem.reset();
    for (final obstacle in _obstacles) {
      remove(obstacle);
      _obstaclePool.release(obstacle);
    }
    _obstacles.clear();
    for (final pickup in _abilityPickups) {
      remove(pickup);
    }
    _abilityPickups.clear();
    for (final ghost in _ghosts.values) {
      remove(ghost);
    }
    _ghosts.clear();
    _gameState = GameState.countdown;
    overlays.remove('idle');
    overlays.add('countdown');
  }

  /// Called by CountdownOverlay when GO! animation completes
  void beginRacing() {
    _raceStartMs = DateTime.now().millisecondsSinceEpoch;
    _gameState = GameState.playing;
    overlays.remove('countdown');
    overlays.add('raceHud');

    // Multiplayer: wire client events and create ghost components
    if (raceClient != null && raceRoom != null) {
      raceClient!.onEvent = _handleNetworkEvent;
      raceClient!.onHostLeft = _handleHostLeft;

      // Create a ghost for every opponent already in the room
      for (final opponent in raceRoom!.opponents) {
        _addGhost(opponent);
      }

      // Start broadcasting our position every 100ms
      raceClient!.startPositionBroadcast(() => _distanceTraveled);
    }
  }

  void _addGhost(RacePlayerState opponent) {
    if (_ghosts.containsKey(opponent.playerId)) return;
    final color = _playerColors[opponent.playerId.clamp(0, _playerColors.length - 1)];
    final ghost = GhostPlayer(
      playerId: opponent.playerId,
      displayName: opponent.displayName,
      playerColor: color,
      groundY: groundY,
    );
    _ghosts[opponent.playerId] = ghost;
    add(ghost);
  }

  void _handleNetworkEvent(RaceClientEvent event) {
    switch (event.type) {
      case RaceClientEventType.playerListUpdated:
        // A new opponent joined mid-lobby — add a ghost for them
        if (raceRoom != null) {
          for (final opponent in raceRoom!.opponents) {
            _addGhost(opponent);
          }
        }

      case RaceClientEventType.positionsUpdated:
        // Ghost positions are refreshed in _updatePlaying() from raceRoom
        break;

      case RaceClientEventType.opponentUsedAbility:
        // Phase 3: if someone activates slowField and we're ahead of them,
        // apply the slow penalty to ourselves
        if (event.abilityId == 'slowField' && raceRoom != null) {
          final opponent = raceRoom!.players.firstWhere(
            (p) => p.playerId == event.opponentId,
            orElse: () => RacePlayerState(
              playerId: event.opponentId ?? -1,
              displayName: '',
            ),
          );
          if (_distanceTraveled > opponent.distance) {
            _player.applySpeedEffect(factor: 0.7, duration: 4.0);
          }
        }

      case RaceClientEventType.resultsReceived:
        // Show finish overlay if not already shown
        if (_gameState != GameState.finished) {
          _gameState = GameState.finished;
          overlays.remove('raceHud');
          overlays.add('raceFinish');
        }

      case RaceClientEventType.playerDisconnected:
        // Mark ghost as disconnected (faded out handled via isConnected)
        break;

      default:
        break;
    }
  }

  void _handleHostLeft() {
    _gameState = GameState.finished;
    overlays.remove('raceHud');
    overlays.add('raceFinish');
  }

  /// Restart a race after finishing
  void restartRace() {
    overlays.remove('raceFinish');
    startRace();
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

    // Disconnect from race network
    raceClient?.stopPositionBroadcast();
    raceClient?.disconnect();

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

    // Update ghost ground Y
    for (final ghost in _ghosts.values) {
      ghost.updateGroundY(newGroundY);
    }

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
