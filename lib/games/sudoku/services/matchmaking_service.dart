// Sudoku online matchmaking service - see docs/SUDOKU_SERVICES.md

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multigame/games/sudoku/models/match_room.dart';
import 'package:multigame/games/sudoku/models/match_player.dart';
import 'package:multigame/games/sudoku/models/match_status.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/utils/secure_logger.dart';

class MatchmakingService {
  final FirebaseFirestore _firestore;
  static const String _matchesCollection = 'sudoku_matches';
  static const String _matchNotFound = 'Match not found';
  static const String _userNotInMatch = 'User not in match';

  MatchmakingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> createMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    try {
      final generator = SudokuGenerator();
      final difficultyEnum = _parseDifficulty(difficulty);
      final puzzle = generator.generate(difficultyEnum);
      final puzzleData = puzzle.toValues();

      final roomCode = _generateRoomCode();

      final player1 = MatchPlayer.initial(
        userId: userId,
        displayName: displayName,
      );

      final docRef = _firestore.collection(_matchesCollection).doc();
      final matchRoom = MatchRoom.create(
        matchId: docRef.id,
        puzzleData: puzzleData,
        difficulty: difficulty,
        player1: player1,
        roomCode: roomCode,
      );

      await docRef.set(matchRoom.toJson());

      SecureLogger.firebase(
        'Match created: ${docRef.id} ($difficulty) - Code: $roomCode',
      );

      return docRef.id;
    } catch (e) {
      SecureLogger.error('Failed to create match', error: e);
      rethrow;
    }
  }

  Future<String?> joinAvailableMatch({
    required String userId,
    required String displayName,
    String? preferredDifficulty,
  }) async {
    try {
      Query query = _firestore
          .collection(_matchesCollection)
          .where('status', isEqualTo: MatchStatus.waiting.toJson())
          .orderBy('createdAt', descending: false)
          .limit(1);

      if (preferredDifficulty != null) {
        query = query.where('difficulty', isEqualTo: preferredDifficulty);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        SecureLogger.log('No available matches found', tag: 'Matchmaking');
        return null;
      }

      final matchDoc = snapshot.docs.first;
      final matchRoom = MatchRoom.fromJson(
        matchDoc.data() as Map<String, dynamic>,
      );

      if (matchRoom.player1?.userId == userId) {
        SecureLogger.log('Cannot join own match', tag: 'Matchmaking');
        return null;
      }

      final player2 = MatchPlayer.initial(
        userId: userId,
        displayName: displayName,
      );

      await matchDoc.reference.update({
        'player2': player2.toJson(),
        'status': MatchStatus.playing.toJson(),
        'startedAt': DateTime.now().toIso8601String(),
      });

      SecureLogger.firebase('Joined match: ${matchDoc.id}');

      return matchDoc.id;
    } catch (e) {
      SecureLogger.error('Failed to join match', error: e);
      rethrow;
    }
  }

  Future<String> quickMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    final matchId = await joinAvailableMatch(
      userId: userId,
      displayName: displayName,
      preferredDifficulty: difficulty,
    );

    if (matchId != null) {
      return matchId;
    }

    return await createMatch(
      userId: userId,
      displayName: displayName,
      difficulty: difficulty,
    );
  }

  Stream<MatchRoom> watchMatch(String matchId) {
    return _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception(_matchNotFound);
          }
          return MatchRoom.fromJson(snapshot.data() as Map<String, dynamic>);
        });
  }

  Future<void> updatePlayerBoard({
    required String matchId,
    required String userId,
    required SudokuBoard board,
    required bool isCompleted,
  }) async {
    try {
      final matchDoc = _firestore.collection(_matchesCollection).doc(matchId);
      final snapshot = await matchDoc.get();

      if (!snapshot.exists) {
        throw Exception(_matchNotFound);
      }

      final matchRoom = MatchRoom.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );
      final isPlayer1 = matchRoom.player1?.userId == userId;

      if (!isPlayer1 && matchRoom.player2?.userId != userId) {
        throw Exception(_userNotInMatch);
      }

      final currentPlayer = isPlayer1 ? matchRoom.player1! : matchRoom.player2!;

      final filledCells = _countFilledCells(board);

      final updatedPlayer = currentPlayer.copyWith(
        boardState: board.toValues(),
        filledCells: filledCells,
        isCompleted: isCompleted,
        completionTime: isCompleted && currentPlayer.completionTime == null
            ? DateTime.now()
            : currentPlayer.completionTime,
      );

      final updateData = <String, dynamic>{
        isPlayer1 ? 'player1' : 'player2': updatedPlayer.toJson(),
        'lastActivityAt': DateTime.now().toIso8601String(),
      };

      if (isCompleted && matchRoom.winnerId == null) {
        updateData['winnerId'] = userId;
        updateData['status'] = MatchStatus.completed.toJson();
        updateData['endedAt'] = DateTime.now().toIso8601String();

        SecureLogger.firebase('Player won match: $matchId');
      }

      await matchDoc.update(updateData);
    } catch (e) {
      SecureLogger.error('Failed to update player board', error: e);
      rethrow;
    }
  }

  Future<void> cancelMatch(String matchId) async {
    try {
      await _firestore.collection(_matchesCollection).doc(matchId).update({
        'status': MatchStatus.cancelled.toJson(),
        'endedAt': DateTime.now().toIso8601String(),
      });

      SecureLogger.firebase('Match cancelled: $matchId');
    } catch (e) {
      SecureLogger.error('Failed to cancel match', error: e);
      rethrow;
    }
  }

  Future<MatchRoom?> getMatch(String matchId) async {
    try {
      final snapshot = await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return MatchRoom.fromJson(snapshot.data() as Map<String, dynamic>);
    } catch (e) {
      SecureLogger.error('Failed to get match', error: e);
      return null;
    }
  }

  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      final matchRoom = await getMatch(matchId);
      if (matchRoom == null) return;

      if (matchRoom.status == MatchStatus.waiting ||
          matchRoom.status == MatchStatus.playing) {
        await cancelMatch(matchId);
      }
    } catch (e) {
      SecureLogger.error('Failed to leave match', error: e);
      rethrow;
    }
  }

  Future<void> cleanupOldMatches() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection(_matchesCollection)
          .where('endedAt', isLessThan: cutoffTime.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      SecureLogger.firebase('Cleaned up ${snapshot.docs.length} old matches');
    } catch (e) {
      SecureLogger.error('Failed to cleanup old matches', error: e);
    }
  }

  Future<void> handleTimeout(String matchId) async {
    try {
      final matchRoom = await getMatch(matchId);
      if (matchRoom == null) return;

      if (matchRoom.hasTimedOut && matchRoom.winnerId == null) {
        String? winnerId;
        if (matchRoom.player1 != null && matchRoom.player2 != null) {
          final p1Filled = matchRoom.player1!.filledCells;
          final p2Filled = matchRoom.player2!.filledCells;

          if (p1Filled > p2Filled) {
            winnerId = matchRoom.player1!.userId;
          } else if (p2Filled > p1Filled) {
            winnerId = matchRoom.player2!.userId;
          }
        }

        await _firestore.collection(_matchesCollection).doc(matchId).update({
          'status': MatchStatus.completed.toJson(),
          'winnerId': winnerId,
          'endedAt': DateTime.now().toIso8601String(),
        });

        SecureLogger.firebase(
          'Match timed out: $matchId (winner: ${winnerId ?? "tie"})',
        );
      }
    } catch (e) {
      SecureLogger.error('Failed to handle timeout', error: e);
      rethrow;
    }
  }

  Future<String> joinByRoomCode({
    required String roomCode,
    required String userId,
    required String displayName,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_matchesCollection)
          .where('roomCode', isEqualTo: roomCode)
          .where('status', isEqualTo: MatchStatus.waiting.toJson())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Invalid room code or room not available');
      }

      final matchDoc = snapshot.docs.first;
      final matchRoom = MatchRoom.fromJson(matchDoc.data());

      if (matchRoom.hasPlayer(userId)) {
        throw Exception('You are already in this match');
      }

      if (matchRoom.isFull) {
        throw Exception('Room is full');
      }

      final player2 = MatchPlayer.initial(
        userId: userId,
        displayName: displayName,
      );

      await matchDoc.reference.update({
        'player2': player2.toJson(),
        'status': MatchStatus.playing.toJson(),
        'startedAt': DateTime.now().toIso8601String(),
        'lastActivityAt': DateTime.now().toIso8601String(),
      });

      SecureLogger.firebase(
        'Joined match via code: ${matchDoc.id} (code: $roomCode)',
      );

      return matchDoc.id;
    } catch (e) {
      SecureLogger.error('Failed to join match by code', error: e);
      rethrow;
    }
  }

  Future<void> updateConnectionState({
    required String matchId,
    required String userId,
    required bool isConnected,
  }) async {
    try {
      final matchDoc = _firestore.collection(_matchesCollection).doc(matchId);
      final snapshot = await matchDoc.get();

      if (!snapshot.exists) {
        throw Exception(_matchNotFound);
      }

      final matchRoom = MatchRoom.fromJson(snapshot.data()!);
      final isPlayer1 = matchRoom.player1?.userId == userId;

      if (!isPlayer1 && matchRoom.player2?.userId != userId) {
        throw Exception(_userNotInMatch);
      }

      final currentPlayer = isPlayer1 ? matchRoom.player1! : matchRoom.player2!;
      final updatedPlayer = currentPlayer.copyWith(
        lastSeenAt: DateTime.now(),
        isConnected: isConnected,
      );

      await matchDoc.update({
        isPlayer1 ? 'player1' : 'player2': updatedPlayer.toJson(),
        'lastActivityAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      SecureLogger.error('Failed to update connection state', error: e);
      rethrow;
    }
  }

  Future<void> updatePlayerStats({
    required String matchId,
    required String userId,
    required int mistakeCount,
    required int hintsUsed,
  }) async {
    try {
      final matchDoc = _firestore.collection(_matchesCollection).doc(matchId);
      final snapshot = await matchDoc.get();

      if (!snapshot.exists) {
        throw Exception(_matchNotFound);
      }

      final matchRoom = MatchRoom.fromJson(snapshot.data()!);
      final isPlayer1 = matchRoom.player1?.userId == userId;

      if (!isPlayer1 && matchRoom.player2?.userId != userId) {
        throw Exception(_userNotInMatch);
      }

      final currentPlayer = isPlayer1 ? matchRoom.player1! : matchRoom.player2!;
      final updatedPlayer = currentPlayer.copyWith(
        mistakeCount: mistakeCount,
        hintsUsed: hintsUsed,
      );

      await matchDoc.update({
        isPlayer1 ? 'player1' : 'player2': updatedPlayer.toJson(),
      });
    } catch (e) {
      SecureLogger.error('Failed to update player stats', error: e);
      rethrow;
    }
  }

  int _countFilledCells(SudokuBoard board) {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board.getCell(row, col).value != null) count++;
      }
    }
    return count;
  }

  String _generateRoomCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  SudokuDifficulty _parseDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return SudokuDifficulty.easy;
      case 'medium':
        return SudokuDifficulty.medium;
      case 'hard':
        return SudokuDifficulty.hard;
      case 'expert':
        return SudokuDifficulty.expert;
      default:
        return SudokuDifficulty.medium;
    }
  }
}
