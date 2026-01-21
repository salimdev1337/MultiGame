/// Player state enum for animation and behavior management
enum PlayerState {
  /// Running state (default)
  running,

  /// Jumping state (in air)
  jumping,

  /// Sliding state (on ground)
  sliding,

  /// Dead state (after collision)
  dead,
}
