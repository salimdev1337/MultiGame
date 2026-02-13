/// Determines whether the runner plays solo or in a multiplayer race
enum GameMode {
  /// Classic endless runner — collision = game over
  solo,

  /// Race to the finish line — collision = speed penalty
  race,
}
