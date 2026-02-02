import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multigame/games/sudoku/models/match_room.dart';
import 'package:multigame/games/sudoku/models/match_player.dart';
import 'package:multigame/games/sudoku/models/match_status.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Service for managing online 1v1 Sudoku matches with Firestore
class MatchmakingService {
  final FirebaseFirestore _firestore;
  static const String _matchesCollection = 'sudoku_matches';

  MatchmakingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new match room and wait for opponent
  ///
  /// Returns the match ID
  Future<String> createMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    try {
      // Generate a new puzzle
      final generator = SudokuGenerator();
      final difficultyEnum = _parseDifficulty(difficulty);
      final puzzle = generator.generate(difficultyEnum);
      final puzzleData = puzzle.toValues();

      // Create player 1
      final player1 = MatchPlayer.initial(
        userId: userId,
        displayName: displayName,
      );

      // Create match room
      final docRef = _firestore.collection(_matchesCollection).doc();
      final matchRoom = MatchRoom.create(
        matchId: docRef.id,
        puzzleData: puzzleData,
        difficulty: difficulty,
        player1: player1,
      );

      await docRef.set(matchRoom.toJson());

      SecureLogger.firebase('Match created: ${docRef.id} ($difficulty)');

      return docRef.id;
    } catch (e) {
      SecureLogger.error('Failed to create match', error: e);
      rethrow;
    }
  }

  /// Find and join an available match
  ///
  /// Returns the match ID if joined successfully, null if no matches available
  Future<String?> joinAvailableMatch({
    required String userId,
    required String displayName,
    String? preferredDifficulty,
  }) async {
    try {
      // Query for waiting matches
      Query query = _firestore
          .collection(_matchesCollection)
          .where('status', isEqualTo: MatchStatus.waiting.toJson())
          .orderBy('createdAt', descending: false)
          .limit(1);

      // Filter by difficulty if specified
      if (preferredDifficulty != null) {
        query = query.where('difficulty', isEqualTo: preferredDifficulty);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        SecureLogger.log('No available matches found', tag: 'Matchmaking');
        return null;
      }

      final matchDoc = snapshot.docs.first;
      final matchRoom = MatchRoom.fromJson(matchDoc.data() as Map<String, dynamic>);

      // Check if user is already in the match (creator trying to join own match)
      if (matchRoom.player1?.userId == userId) {
        SecureLogger.log('Cannot join own match', tag: 'Matchmaking');
        return null;
      }

      // Create player 2
      final player2 = MatchPlayer.initial(
        userId: userId,
        displayName: displayName,
      );

      // Join the match
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

  /// Quick match: Find available match or create new one
  ///
  /// Returns the match ID
  Future<String> quickMatch({
    required String userId,
    required String displayName,
    required String difficulty,
  }) async {
    // Try to join an existing match first
    final matchId = await joinAvailableMatch(
      userId: userId,
      displayName: displayName,
      preferredDifficulty: difficulty,
    );

    if (matchId != null) {
      return matchId;
    }

    // No matches available, create new one
    return await createMatch(
      userId: userId,
      displayName: displayName,
      difficulty: difficulty,
    );
  }

  /// Listen to match updates in real-time
  Stream<MatchRoom> watchMatch(String matchId) {
    return _firestore
        .collection(_matchesCollection)
        .doc(matchId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Match not found');
      }
      return MatchRoom.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  /// Update player's board state
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
        throw Exception('Match not found');
      }

      final matchRoom = MatchRoom.fromJson(snapshot.data() as Map<String, dynamic>);
      final isPlayer1 = matchRoom.player1?.userId == userId;

      if (!isPlayer1 && matchRoom.player2?.userId != userId) {
        throw Exception('User not in match');
      }

      // Get current player data
      final currentPlayer = isPlayer1 ? matchRoom.player1! : matchRoom.player2!;

      // Count filled cells (excluding fixed cells from original puzzle)
      int filledCells = 0;
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          final cellValue = board.getCell(row, col).value;
          if (cellValue != null) {
            filledCells++;
          }
        }
      }

      // Create updated player data
      final updatedPlayer = currentPlayer.copyWith(
        boardState: board.toValues(),
        filledCells: filledCells,
        isCompleted: isCompleted,
        completionTime: isCompleted && currentPlayer.completionTime == null
            ? DateTime.now()
            : currentPlayer.completionTime,
      );

      // Prepare update data
      final updateData = <String, dynamic>{
        isPlayer1 ? 'player1' : 'player2': updatedPlayer.toJson(),
      };

      // Check if this player just won (completed first)
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

  /// Cancel a match (for when player leaves before/during game)
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

  /// Get match by ID
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

  /// Leave a match room
  Future<void> leaveMatch(String matchId, String userId) async {
    try {
      final matchRoom = await getMatch(matchId);
      if (matchRoom == null) return;

      // If match is still waiting or playing, cancel it
      if (matchRoom.status == MatchStatus.waiting ||
          matchRoom.status == MatchStatus.playing) {
        await cancelMatch(matchId);
      }
    } catch (e) {
      SecureLogger.error('Failed to leave match', error: e);
      rethrow;
    }
  }

  /// Clean up old matches (completed/cancelled matches older than 24 hours)
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
      // Don't rethrow - cleanup is not critical
    }
  }

  /// Handle match timeout
  Future<void> handleTimeout(String matchId) async {
    try {
      final matchRoom = await getMatch(matchId);
      if (matchRoom == null) return;

      if (matchRoom.hasTimedOut && matchRoom.winnerId == null) {
        // Determine winner based on progress (most filled cells wins)
        String? winnerId;
        if (matchRoom.player1 != null && matchRoom.player2 != null) {
          final p1Filled = matchRoom.player1!.filledCells;
          final p2Filled = matchRoom.player2!.filledCells;

          if (p1Filled > p2Filled) {
            winnerId = matchRoom.player1!.userId;
          } else if (p2Filled > p1Filled) {
            winnerId = matchRoom.player2!.userId;
          }
          // If tied, no winner
        }

        await _firestore.collection(_matchesCollection).doc(matchId).update({
          'status': MatchStatus.completed.toJson(),
          'winnerId': winnerId,
          'endedAt': DateTime.now().toIso8601String(),
        });

        SecureLogger.firebase('Match timed out: $matchId (winner: ${winnerId ?? "tie"})');
      }
    } catch (e) {
      SecureLogger.error('Failed to handle timeout', error: e);
      rethrow;
    }
  }

  /// Parse difficulty string to enum
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
