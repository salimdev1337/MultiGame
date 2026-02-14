import 'package:share_plus/share_plus.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Handles sharing achievements and high scores to social media.
class ShareService {
  // ── Achievement Sharing ───────────────────────────────────────────────────

  Future<void> shareAchievement({
    required String achievementName,
    required String description,
  }) async {
    final text =
        '🏆 I just unlocked "$achievementName" in MultiGame!\n\n'
        '$description\n\n'
        '#MultiGame #Achievement';

    try {
      await Share.share(text);
      SecureLogger.log('Achievement shared: $achievementName', tag: 'Social');
    } catch (e) {
      SecureLogger.error('Failed to share achievement', error: e);
    }
  }

  // ── High Score Sharing ────────────────────────────────────────────────────

  Future<void> shareHighScore({
    required String gameType,
    required int score,
  }) async {
    final text =
        '🎮 New high score in $gameType! I scored $score points in MultiGame!\n\n'
        'Can you beat me? 🔥\n\n'
        '#MultiGame #HighScore #$gameType';

    try {
      await Share.share(text);
      SecureLogger.log('High score shared: $gameType $score', tag: 'Social');
    } catch (e) {
      SecureLogger.error('Failed to share high score', error: e);
    }
  }
}
