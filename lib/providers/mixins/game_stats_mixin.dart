import 'package:flutter/foundation.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/data/streak_service.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Mixin that provides common game statistics functionality
/// for saving scores and managing user information across all game providers.
///
/// This mixin extracts the duplicate code found in multiple game providers,
/// providing a centralized way to handle user info and score saving.
mixin GameStatsMixin on ChangeNotifier {
  /// The Firebase stats service for saving game data
  /// Must be implemented by the class using this mixin
  FirebaseStatsService get statsService;

  /// Streak service for tracking daily play streaks
  final StreakService _streakService = StreakService();

  String? _userId;
  String? _displayName;
  String? _lastError;
  bool _isSavingScore = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 3;

  /// Delay multiplier for retries (use milliseconds in tests, seconds in production)
  /// Set to 1 for production (seconds), 1 for tests (milliseconds)
  @visibleForTesting
  Duration Function(int exponentialFactor) retryDelayCalculator = (factor) =>
      Duration(seconds: factor);

  /// Get the current user ID
  String? get userId => _userId;

  /// Get the current display name
  String? get displayName => _displayName;

  /// Get the last error message (null if no error)
  String? get lastError => _lastError;

  /// Whether a score save operation is in progress
  bool get isSavingScore => _isSavingScore;

  /// Current retry attempt (0 if not retrying)
  int get retryAttempt => _retryAttempt;

  /// Clear the last error message
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Set user information for saving stats
  ///
  /// This should be called when the user info is available,
  /// typically during provider initialization.
  void setUserInfo(String? userId, String? displayName) {
    _userId = userId;
    _displayName = displayName;
  }

  /// Save the game score to Firebase with automatic retry on failure
  ///
  /// [gameType] - The type of game (e.g., 'puzzle', '2048', 'snake')
  /// [score] - The score to save
  ///
  /// This method will only save if userId is not null and score is greater than 0.
  /// On failure, it will retry up to 3 times with exponential backoff (1s, 2s, 4s).
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveScore(String gameType, int score) async {
    SecureLogger.log(
      'Score save initiated: $gameType (score: $score)',
      tag: 'GameStats',
    );

    if (_userId == null || score <= 0) {
      final reason = _userId == null ? 'no userId' : 'zero score';
      SecureLogger.log(
        'Score save skipped for $gameType: $reason',
        tag: 'GameStats',
      );
      return false;
    }

    _isSavingScore = true;
    _lastError = null;
    _retryAttempt = 0;
    notifyListeners();

    // Try saving with retries
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          _retryAttempt = attempt;
          notifyListeners();

          // Exponential backoff: 1s, 2s, 4s (or 1ms, 2ms, 4ms in tests)
          final delayFactor = 1 << (attempt - 1);
          final delay = retryDelayCalculator(delayFactor);
          SecureLogger.log(
            'Retrying score save (attempt $attempt/$_maxRetries) after ${delayFactor}s delay',
            tag: 'GameStats',
          );
          await Future.delayed(delay);
        }

        SecureLogger.firebase(
          'saveUserStats',
          details: 'gameType: $gameType, score: $score, attempt: $attempt',
        );
        await statsService.saveUserStats(
          userId: _userId!,
          displayName: _displayName,
          gameType: gameType,
          score: score,
        );

        // Success!
        SecureLogger.firebase(
          'saveUserStats - success',
          details: '$gameType (attempt: $attempt)',
        );

        // Update streak on successful game completion
        try {
          await _streakService.updateStreak();
          SecureLogger.log(
            'Streak updated after game completion',
            tag: 'GameStats',
          );
        } catch (e) {
          // Don't fail the score save if streak update fails
          SecureLogger.error(
            'Failed to update streak',
            error: e,
            tag: 'GameStats',
          );
        }

        _isSavingScore = false;
        _retryAttempt = 0;
        notifyListeners();
        return true;
      } catch (e) {
        final isLastAttempt = attempt == _maxRetries;

        if (isLastAttempt) {
          // Final attempt failed - give up
          SecureLogger.error(
            'Failed to save $gameType score after ${_maxRetries + 1} attempts',
            error: e,
            tag: 'GameStats',
          );
          _lastError =
              'Failed to save score after ${_maxRetries + 1} attempts. Check your internet connection.';
          _isSavingScore = false;
          _retryAttempt = 0;
          notifyListeners();
          return false;
        } else {
          // Will retry
          SecureLogger.log(
            'Score save attempt $attempt failed, will retry: ${e.toString()}',
            tag: 'GameStats',
          );
        }
      }
    }

    // Should never reach here, but handle it
    _isSavingScore = false;
    _retryAttempt = 0;
    notifyListeners();
    return false;
  }
}
