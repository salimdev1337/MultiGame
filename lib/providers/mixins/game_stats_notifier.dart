/// Base class for game notifiers that need Firebase stats + streak saving.
///
/// Replaces the old [GameStatsMixin] on ChangeNotifier.
/// Extend this instead of [Notifier] in all game state classes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/user_auth_notifier.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/services/data/streak_service.dart';
import 'package:multigame/utils/secure_logger.dart';

abstract class GameStatsNotifier<T> extends AutoDisposeNotifier<T> {
  FirebaseStatsService get statsService;

  final StreakService _streakService = StreakService();

  String? _userId;
  String? _displayName;

  static const int _maxRetries = 3;

  /// Override in tests to speed up retry delays.
  Duration retryDelay(int factor) => Duration(seconds: factor);

  String? get userId => _userId;
  String? get displayName => _displayName;

  void setUserInfo(String? userId, String? displayName) {
    _userId = userId;
    _displayName = displayName;
  }

  Future<bool> saveScore(String gameType, int score) async {
    SecureLogger.log(
      'Score save initiated: $gameType (score: $score)',
      tag: 'GameStats',
    );

    // Lazily resolve user info from the auth provider if not explicitly set.
    if (_userId == null) {
      try {
        final authState = ref.read(userAuthProvider);
        _userId = authState.userId;
        _displayName = authState.displayName;
      } catch (_) {
        // Auth provider unavailable (e.g., in unit tests) — stay null.
      }
    }

    if (_userId == null || score <= 0) {
      final reason = _userId == null ? 'no userId' : 'zero score';
      SecureLogger.log(
        'Score save skipped for $gameType: $reason',
        tag: 'GameStats',
      );
      return false;
    }

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          final factor = 1 << (attempt - 1);
          await Future.delayed(retryDelay(factor));
          SecureLogger.log(
            'Retrying score save (attempt $attempt/$_maxRetries)',
            tag: 'GameStats',
          );
        }

        await statsService.saveUserStats(
          userId: _userId!,
          displayName: _displayName,
          gameType: gameType,
          score: score,
        );

        try {
          await _streakService.updateStreak();
        } catch (e) {
          SecureLogger.error(
            'Failed to update streak',
            error: e,
            tag: 'GameStats',
          );
        }

        SecureLogger.firebase(
          'saveUserStats - success',
          details: '$gameType (attempt: $attempt)',
        );
        return true;
      } catch (e) {
        if (attempt == _maxRetries) {
          SecureLogger.error(
            'Failed to save $gameType score after ${_maxRetries + 1} attempts',
            error: e,
            tag: 'GameStats',
          );
          return false;
        }
      }
    }

    return false;
  }
}
