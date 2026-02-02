/// Represents a player in an online 1v1 match
class MatchPlayer {
  /// Firebase user ID
  final String userId;

  /// Display name
  final String displayName;

  /// Current board state (9x9 grid of integers, 0 = empty, 1-9 = values)
  /// Notes are NOT synced - only actual cell values
  final List<List<int>> boardState;

  /// Number of filled cells (for progress tracking)
  final int filledCells;

  /// Whether player has completed the puzzle
  final bool isCompleted;

  /// Timestamp when player completed (null if not completed)
  final DateTime? completionTime;

  /// Timestamp when player joined the match
  final DateTime joinedAt;

  MatchPlayer({
    required this.userId,
    required this.displayName,
    required this.boardState,
    required this.filledCells,
    required this.isCompleted,
    this.completionTime,
    required this.joinedAt,
  });

  /// Create initial player state with empty board
  factory MatchPlayer.initial({
    required String userId,
    required String displayName,
  }) {
    return MatchPlayer(
      userId: userId,
      displayName: displayName,
      boardState: List.generate(9, (_) => List.filled(9, 0)),
      filledCells: 0,
      isCompleted: false,
      completionTime: null,
      joinedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'boardState': boardState,
      'filledCells': filledCells,
      'isCompleted': isCompleted,
      'completionTime': completionTime?.toIso8601String(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  /// Create from Firestore JSON
  factory MatchPlayer.fromJson(Map<String, dynamic> json) {
    return MatchPlayer(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      boardState: (json['boardState'] as List<dynamic>)
          .map((row) => (row as List<dynamic>).cast<int>())
          .toList(),
      filledCells: json['filledCells'] as int,
      isCompleted: json['isCompleted'] as bool,
      completionTime: json['completionTime'] != null
          ? DateTime.parse(json['completionTime'] as String)
          : null,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  MatchPlayer copyWith({
    String? userId,
    String? displayName,
    List<List<int>>? boardState,
    int? filledCells,
    bool? isCompleted,
    DateTime? completionTime,
    DateTime? joinedAt,
  }) {
    return MatchPlayer(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      boardState: boardState ?? this.boardState,
      filledCells: filledCells ?? this.filledCells,
      isCompleted: isCompleted ?? this.isCompleted,
      completionTime: completionTime ?? this.completionTime,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
