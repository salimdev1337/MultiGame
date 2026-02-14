// Online match room model - see docs/SUDOKU_ARCHITECTURE.md

import 'match_status.dart';
import 'match_player.dart';

class MatchRoom {
  final String matchId;
  final MatchStatus status;
  final List<List<int>> puzzleData;
  final String difficulty;
  final MatchPlayer? player1;
  final MatchPlayer? player2;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int timeoutSeconds;
  final String roomCode;
  final DateTime? lastActivityAt;
  final int reconnectionGracePeriodSeconds;

  MatchRoom({
    required this.matchId,
    required this.status,
    required this.puzzleData,
    required this.difficulty,
    this.player1,
    this.player2,
    this.winnerId,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.timeoutSeconds = 600,
    required this.roomCode,
    this.lastActivityAt,
    this.reconnectionGracePeriodSeconds = 60,
  });

  factory MatchRoom.create({
    required String matchId,
    required List<List<int>> puzzleData,
    required String difficulty,
    required MatchPlayer player1,
    required String roomCode,
  }) {
    final now = DateTime.now();
    return MatchRoom(
      matchId: matchId,
      status: MatchStatus.waiting,
      puzzleData: puzzleData,
      difficulty: difficulty,
      player1: player1,
      player2: null,
      winnerId: null,
      createdAt: now,
      startedAt: null,
      endedAt: null,
      roomCode: roomCode,
      lastActivityAt: now,
    );
  }

  bool get isFull => player1 != null && player2 != null;

  bool get isInProgress => status == MatchStatus.playing;

  bool get isCompleted => status == MatchStatus.completed;

  bool get isWaiting => status == MatchStatus.waiting;

  bool get hasTimedOut {
    if (startedAt == null) return false;
    final elapsed = DateTime.now().difference(startedAt!);
    return elapsed.inSeconds > timeoutSeconds;
  }

  MatchPlayer? getOpponent(String userId) {
    if (player1?.userId == userId) return player2;
    if (player2?.userId == userId) return player1;
    return null;
  }

  MatchPlayer? getPlayer(String userId) {
    if (player1?.userId == userId) return player1;
    if (player2?.userId == userId) return player2;
    return null;
  }

  bool hasPlayer(String userId) {
    return player1?.userId == userId || player2?.userId == userId;
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'status': status.toJson(),
      'puzzleData': puzzleData,
      'difficulty': difficulty,
      'player1': player1?.toJson(),
      'player2': player2?.toJson(),
      'winnerId': winnerId,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'timeoutSeconds': timeoutSeconds,
      'roomCode': roomCode,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'reconnectionGracePeriodSeconds': reconnectionGracePeriodSeconds,
    };
  }

  factory MatchRoom.fromJson(Map<String, dynamic> json) {
    return MatchRoom(
      matchId: json['matchId'] as String,
      status: MatchStatusExtension.fromJson(json['status'] as String),
      puzzleData: (json['puzzleData'] as List<dynamic>)
          .map((row) => (row as List<dynamic>).cast<int>())
          .toList(),
      difficulty: json['difficulty'] as String,
      player1: json['player1'] != null
          ? MatchPlayer.fromJson(json['player1'] as Map<String, dynamic>)
          : null,
      player2: json['player2'] != null
          ? MatchPlayer.fromJson(json['player2'] as Map<String, dynamic>)
          : null,
      winnerId: json['winnerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 600,
      roomCode: json['roomCode'] as String? ?? '',
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      reconnectionGracePeriodSeconds:
          json['reconnectionGracePeriodSeconds'] as int? ?? 60,
    );
  }

  MatchRoom copyWith({
    String? matchId,
    MatchStatus? status,
    List<List<int>>? puzzleData,
    String? difficulty,
    MatchPlayer? player1,
    MatchPlayer? player2,
    String? winnerId,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? timeoutSeconds,
    String? roomCode,
    DateTime? lastActivityAt,
    int? reconnectionGracePeriodSeconds,
  }) {
    return MatchRoom(
      matchId: matchId ?? this.matchId,
      status: status ?? this.status,
      puzzleData: puzzleData ?? this.puzzleData,
      difficulty: difficulty ?? this.difficulty,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      winnerId: winnerId ?? this.winnerId,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      roomCode: roomCode ?? this.roomCode,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      reconnectionGracePeriodSeconds:
          reconnectionGracePeriodSeconds ?? this.reconnectionGracePeriodSeconds,
    );
  }
}
