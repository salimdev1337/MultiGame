import 'package:flutter/material.dart';
import 'package:multigame/models/achievement_model.dart';
import 'game_dialog.dart';

/// Dialog for displaying newly unlocked achievements
class AchievementDialog extends StatelessWidget {
  final List<AchievementModel> achievements;
  final VoidCallback? onClose;

  const AchievementDialog({
    super.key,
    required this.achievements,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GameDialog(
      title: achievements.length > 1
          ? '${achievements.length} New Achievements!'
          : 'Achievement Unlocked!',
      titleIcon: Icons.emoji_events,
      primaryColor: const Color(0xFFffc107),
      barrierDismissible: false,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements
              .map((achievement) => _buildAchievementCard(context, achievement))
              .toList(),
        ),
      ),
      actions: [
        DialogButton(
          text: 'Continue',
          isPrimary: true,
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
      BuildContext context, AchievementModel achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFffc107).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFffc107).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFffc107),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple function to show achievement dialog
Future<void> showAchievementDialog(
  BuildContext context,
  List<AchievementModel> achievements, {
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AchievementDialog(
      achievements: achievements,
      onClose: onClose,
    ),
  );
}
