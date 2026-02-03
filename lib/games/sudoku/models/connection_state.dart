/// Connection state for online multiplayer
enum ConnectionState {
  /// Player is online and syncing
  online,

  /// Player is offline (disconnected), within grace period
  offline,

  /// Player is attempting to reconnect
  reconnecting,
}

/// Extension methods for ConnectionState
extension ConnectionStateExtension on ConnectionState {
  /// Convert to JSON string
  String toJson() => name;

  /// Check if player is actively connected
  bool get isActive => this == ConnectionState.online;

  /// Check if player is attempting reconnection
  bool get isReconnecting => this == ConnectionState.reconnecting;

  /// Check if player is disconnected
  bool get isDisconnected =>
      this == ConnectionState.offline || this == ConnectionState.reconnecting;

  /// Create from JSON string
  static ConnectionState fromJson(String value) {
    return ConnectionState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConnectionState.offline,
    );
  }
}
