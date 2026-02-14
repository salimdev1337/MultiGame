/// Per-player state that is synced over the network during a race.
/// Immutable snapshot — replaced entirely on each position update.
class RacePlayerState {
  const RacePlayerState({
    required this.playerId,
    required this.displayName,
    this.distance = 0.0,
    this.isReady = false,
    this.isFinished = false,
    this.finishTimeMs = 0,
    this.isConnected = true,
  });

  /// 0 = host, 1–3 = guests
  final int playerId;
  final String displayName;

  /// Progress in scroll units (0 → 10 000)
  final double distance;

  /// True once the player tapped "Ready" in the lobby
  final bool isReady;

  /// True once the player crossed the finish line
  final bool isFinished;

  /// Wall-clock ms at which the player finished (0 = not finished yet)
  final int finishTimeMs;

  /// False when the player disconnects mid-race
  final bool isConnected;

  /// Progress as 0.0–1.0 fraction of the track
  double get progress => (distance / 10000.0).clamp(0.0, 1.0);

  RacePlayerState copyWith({
    double? distance,
    bool? isReady,
    bool? isFinished,
    int? finishTimeMs,
    bool? isConnected,
  }) => RacePlayerState(
    playerId: playerId,
    displayName: displayName,
    distance: distance ?? this.distance,
    isReady: isReady ?? this.isReady,
    isFinished: isFinished ?? this.isFinished,
    finishTimeMs: finishTimeMs ?? this.finishTimeMs,
    isConnected: isConnected ?? this.isConnected,
  );

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'displayName': displayName,
    'distance': distance,
    'isReady': isReady,
    'isFinished': isFinished,
    'finishTimeMs': finishTimeMs,
    'isConnected': isConnected,
  };

  factory RacePlayerState.fromMap(Map<String, dynamic> map) => RacePlayerState(
    playerId: (map['playerId'] as num).toInt(),
    displayName: map['displayName'] as String,
    distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
    isReady: (map['isReady'] as bool?) ?? false,
    isFinished: (map['isFinished'] as bool?) ?? false,
    finishTimeMs: (map['finishTimeMs'] as num?)?.toInt() ?? 0,
    isConnected: (map['isConnected'] as bool?) ?? true,
  );
}
