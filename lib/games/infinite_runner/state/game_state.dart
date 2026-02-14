/// Represents the current state of the infinite runner game
enum GameState {
  /// Initial state before game starts
  idle,

  /// 3-2-1-GO! countdown before race begins (race mode only)
  countdown,

  /// Active gameplay
  playing,

  /// Game paused (app backgrounded or manual pause)
  paused,

  /// Game ended (collision occurred) — solo mode only
  gameOver,

  /// Player crossed the finish line — race mode only
  finished,
}
