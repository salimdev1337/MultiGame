import 'package:flutter/material.dart';

/// Base dialog widget with consistent game styling
class GameDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final Color? primaryColor;
  final IconData? titleIcon;
  final double maxWidth;
  final EdgeInsets? contentPadding;

  const GameDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.barrierDismissible = true,
    this.primaryColor,
    this.titleIcon,
    this.maxWidth = 400,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogColor = primaryColor ?? theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dialogColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: dialogColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Icon(titleIcon, color: dialogColor, size: 28),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: dialogColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            ],
            Flexible(
              child: Padding(
                padding: contentPadding ?? const EdgeInsets.all(24),
                child: content,
              ),
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Styled button for dialogs
class DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;
  final IconData? icon;

  const DialogButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor =
        color ??
        (isPrimary
            ? theme.colorScheme.primary
            : Colors.white.withValues(alpha: 0.1));

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
