/// Design System - Toast Notifications
/// Animated toast messages for success, error, warning, and info
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';

/// Toast type enum
enum DSToastType { success, error, warning, info }

/// Toast notification widget
///
/// Shows animated toast messages with icons and optional actions.
/// Auto-dismisses after specified duration.
class DSToast extends StatelessWidget {
  final String message;
  final DSToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DSToast({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  /// Show a success toast
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showToast(
      context,
      DSToast(
        message: message,
        type: DSToastType.success,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Show an error toast
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showToast(
      context,
      DSToast(
        message: message,
        type: DSToastType.error,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Show a warning toast
  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showToast(
      context,
      DSToast(
        message: message,
        type: DSToastType.warning,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Show an info toast
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showToast(
      context,
      DSToast(
        message: message,
        type: DSToastType.info,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  /// Internal method to show toast
  static void _showToast(BuildContext context, DSToast toast) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        toast: toast,
        onDismissComplete: () {
          toast.onDismiss?.call();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(toast.duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Color get _backgroundColor {
    switch (type) {
      case DSToastType.success:
        return DSColors.success;
      case DSToastType.error:
        return DSColors.error;
      case DSToastType.warning:
        return DSColors.warning;
      case DSToastType.info:
        return DSColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case DSToastType.success:
        return Icons.check_circle;
      case DSToastType.error:
        return Icons.error;
      case DSToastType.warning:
        return Icons.warning;
      case DSToastType.info:
        return Icons.info;
    }
  }

  String get _semanticLabel {
    final typeLabel = switch (type) {
      DSToastType.success => 'Success',
      DSToastType.error => 'Error',
      DSToastType.warning => 'Warning',
      DSToastType.info => 'Info',
    };
    return '$typeLabel notification: $message';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: _semanticLabel,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: DSSpacing.md),
        padding: EdgeInsets.all(DSSpacing.sm),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: DSSpacing.borderRadiusLG,
          boxShadow: [
            BoxShadow(
              color: _backgroundColor.withValues(alpha: (0.4 * 255)),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(DSSpacing.xxs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: (0.2 * 255)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                color: Colors.white,
                size: DSSpacing.iconMedium,
              ),
            ),

            DSSpacing.gapHorizontalMD,

            // Message
            Expanded(
              child: Text(
                message,
                style: DSTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Action button (optional)
            if (actionLabel != null && onAction != null) ...[
              DSSpacing.gapHorizontalSM,
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: (0.2 * 255)),
                  shape: RoundedRectangleBorder(
                    borderRadius: DSSpacing.borderRadiusMD,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: DSSpacing.sm,
                    vertical: DSSpacing.xs,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: DSTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Toast overlay widget with animations
class _ToastOverlay extends StatefulWidget {
  final DSToast toast;
  final VoidCallback? onDismissComplete;

  const _ToastOverlay({required this.toast, this.onDismissComplete});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );

    // Slide in from top
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: DSAnimations.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Schedule dismiss animation
    Future.delayed(widget.toast.duration - DSAnimations.normal, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + DSSpacing.md,
      left: 0,
      right: 0,
      child:
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: widget.toast,
              ),
            ),
          ).animate().shake(
            duration: widget.toast.type == DSToastType.error
                ? 500.milliseconds
                : 0.milliseconds,
            hz: 5,
            rotation: 0.03,
          ),
    );
  }
}

/// Extension methods for easy toast display
extension DSToastExtension on BuildContext {
  /// Show success toast
  void showSuccessToast(String message) {
    DSToast.success(this, message: message);
  }

  /// Show error toast
  void showErrorToast(String message) {
    DSToast.error(this, message: message);
  }

  /// Show warning toast
  void showWarningToast(String message) {
    DSToast.warning(this, message: message);
  }

  /// Show info toast
  void showInfoToast(String message) {
    DSToast.info(this, message: message);
  }
}
