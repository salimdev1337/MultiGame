// Connection state enum - see docs/SUDOKU_ARCHITECTURE.md

enum ConnectionState {
  online,
  offline,
  reconnecting,
}

extension ConnectionStateExtension on ConnectionState {
  String toJson() => name;

  bool get isActive => this == ConnectionState.online;

  bool get isReconnecting => this == ConnectionState.reconnecting;

  bool get isDisconnected =>
      this == ConnectionState.offline || this == ConnectionState.reconnecting;

  static ConnectionState fromJson(String value) {
    return ConnectionState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConnectionState.offline,
    );
  }
}
