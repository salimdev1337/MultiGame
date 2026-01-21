/// Represents the current state of the infinite runner game
enum GameState {
  /// Initial state before game starts
  idle,

  /// Active gameplay
  playing,

  /// Game paused (app backgrounded or manual pause)
  paused,

  /// Game ended (collision occurred)
  gameOver,
}
