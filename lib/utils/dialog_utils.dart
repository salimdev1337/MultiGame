import 'package:flutter/material.dart';
import 'package:multigame/widgets/dialogs/game_dialog.dart';

/// Utility functions for showing common dialogs

/// Show a confirmation dialog
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  IconData? icon,
  Color? primaryColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => GameDialog(
      title: title,
      titleIcon: icon,
      primaryColor: primaryColor,
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        DialogButton(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        DialogButton(
          text: confirmText,
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Show an information dialog
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'OK',
  IconData? icon,
  Color? primaryColor,
}) {
  return showDialog(
    context: context,
    builder: (context) => GameDialog(
      title: title,
      titleIcon: icon,
      primaryColor: primaryColor,
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        DialogButton(
          text: buttonText,
          isPrimary: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Show a game over dialog with score and actions
Future<void> showGameOverDialog(
  BuildContext context, {
  required String title,
  required int score,
  String scoreLabel = 'Score',
  VoidCallback? onRestart,
  VoidCallback? onHome,
  bool barrierDismissible = false,
  Color? primaryColor,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => GameDialog(
      title: title,
      titleIcon: Icons.emoji_events,
      primaryColor: primaryColor,
      barrierDismissible: barrierDismissible,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$scoreLabel: $score',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        if (onHome != null)
          DialogButton(
            text: 'Home',
            icon: Icons.home,
            onPressed: () {
              Navigator.of(context).pop();
              onHome();
            },
          ),
        if (onRestart != null)
          DialogButton(
            text: 'Play Again',
            icon: Icons.replay,
            isPrimary: true,
            onPressed: () {
              Navigator.of(context).pop();
              onRestart();
            },
          ),
      ],
    ),
  );
}

/// Show a loading dialog
void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Close the loading dialog
void closeLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}
