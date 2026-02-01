import 'package:flutter/foundation.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

/// Mixin that provides common game statistics functionality
/// for saving scores and managing user information across all game providers.
///
/// This mixin extracts the duplicate code found in multiple game providers,
/// providing a centralized way to handle user info and score saving.
mixin GameStatsMixin on ChangeNotifier {
  /// The Firebase stats service for saving game data
  /// Must be implemented by the class using this mixin
  FirebaseStatsService get statsService;

  String? _userId;
  String? _displayName;

  /// Get the current user ID
  String? get userId => _userId;

  /// Get the current display name
  String? get displayName => _displayName;

  /// Set user information for saving stats
  ///
  /// This should be called when the user info is available,
  /// typically during provider initialization.
  void setUserInfo(String? userId, String? displayName) {
    _userId = userId;
    _displayName = displayName;
  }

  /// Save the game score to Firebase
  ///
  /// [gameType] - The type of game (e.g., 'puzzle', '2048', 'snake')
  /// [score] - The score to save
  ///
  /// This method will only save if userId is not null and score is greater than 0.
  void saveScore(String gameType, int score) {
    debugPrint('$gameType _saveScore called: userId=$_userId, score=$score');
    if (_userId != null && score > 0) {
      debugPrint('Saving $gameType score to Firebase: $score');
      statsService
          .saveUserStats(
            userId: _userId!,
            displayName: _displayName,
            gameType: gameType,
            score: score,
          )
          .then((_) {
            debugPrint('$gameType score saved successfully!');
          })
          .catchError((e) {
            debugPrint('Error saving $gameType score: $e');
          });
    } else {
      debugPrint('Not saving $gameType score: userId is null or score is 0');
    }
  }
}
