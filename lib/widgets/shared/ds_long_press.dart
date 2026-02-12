/// Design System - Long Press Widget
/// Interactive long-press button with progress indicator
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Long press button with circular progress indicator
///
/// Shows a visual progress indicator while the user holds down the button.
/// Triggers the action only after the full duration is completed.
///
/// Use cases:
/// - Delete confirmation (hold to delete)
/// - Critical actions (hold to confirm)
/// - Game power-ups (hold to charge)
class DSLongPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPressComplete;
  final Duration duration;
  final Color? progressColor;
  final Color? backgroundColor;
  final double progressWidth;
  final bool hapticFeedback;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressCancel;

  const DSLongPressButton({
    super.key,
    required this.child,
    required this.onLongPressComplete,
    this.duration = const Duration(seconds: 2),
    this.progressColor,
    this.backgroundColor,
    this.progressWidth = 4.0,
    this.hapticFeedback = true,
    this.onLongPressStart,
    this.onLongPressCancel,
  });

  @override
  State<DSLongPressButton> createState() => _DSLongPressButtonState();
}

class _DSLongPressButtonState extends State<DSLongPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Long press completed
        widget.onLongPressComplete();
        _reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressStart() {
    setState(() {
      _isPressed = true;
    });

    widget.onLongPressStart?.call();
    _controller.forward();
  }

  void _onPressEnd() {
    if (_controller.isAnimating && !_controller.isCompleted) {
      widget.onLongPressCancel?.call();
    }
    _reset();
  }

  void _reset() {
    setState(() {
      _isPressed = false;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _onPressStart(),
      onLongPressEnd: (_) => _onPressEnd(),
      onLongPressCancel: _onPressEnd,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: DSAnimations.fast,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main content
            widget.child,

            // Progress indicator
            if (_isPressed)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: widget.progressWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.progressColor ?? DSColors.primary,
                      ),
                      backgroundColor: widget.backgroundColor ??
                          DSColors.surface.withValues(alpha: (0.3 * 255)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Long press action widget - specifically for destructive actions
///
/// Pre-configured with warning colors and haptics for delete/destructive actions
class DSLongPressDelete extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;
  final Duration duration;
  final IconData icon;

  const DSLongPressDelete({
    super.key,
    this.label = 'Hold to Delete',
    required this.onDelete,
    this.duration = const Duration(milliseconds: 1500),
    this.icon = Icons.delete_outline,
  });

  @override
  Widget build(BuildContext context) {
    return DSLongPressButton(
      duration: duration,
      progressColor: DSColors.error,
      onLongPressComplete: onDelete,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DSSpacing.lg,
          vertical: DSSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: DSColors.error.withValues(alpha: (0.1 * 255)),
          borderRadius: DSSpacing.borderRadiusLG,
          border: Border.all(
            color: DSColors.error.withValues(alpha: (0.3 * 255)),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: DSColors.error,
              size: DSSpacing.iconMedium,
            ),
            DSSpacing.gapHorizontalSM,
            Text(
              label,
              style: DSTypography.labelLarge.copyWith(
                color: DSColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Long press confirmation widget - for important confirmations
class DSLongPressConfirm extends StatelessWidget {
  final String label;
  final VoidCallback onConfirm;
  final Duration duration;
  final IconData icon;

  const DSLongPressConfirm({
    super.key,
    this.label = 'Hold to Confirm',
    required this.onConfirm,
    this.duration = const Duration(milliseconds: 1500),
    this.icon = Icons.check_circle_outline,
  });

  @override
  Widget build(BuildContext context) {
    return DSLongPressButton(
      duration: duration,
      progressColor: DSColors.success,
      onLongPressComplete: onConfirm,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DSSpacing.lg,
          vertical: DSSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: DSColors.gradientPrimary,
          borderRadius: DSSpacing.borderRadiusLG,
          boxShadow: DSShadows.shadowPrimary,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: DSSpacing.iconMedium,
            ),
            DSSpacing.gapHorizontalSM,
            Text(
              label,
              style: DSTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular long press button with icon
///
/// Use for compact long-press actions with circular design
class DSLongPressCircular extends StatelessWidget {
  final IconData icon;
  final VoidCallback onLongPressComplete;
  final Duration duration;
  final Color? color;
  final double size;

  const DSLongPressCircular({
    super.key,
    required this.icon,
    required this.onLongPressComplete,
    this.duration = const Duration(seconds: 2),
    this.color,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return DSLongPressButton(
      duration: duration,
      progressColor: color ?? DSColors.primary,
      onLongPressComplete: onLongPressComplete,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              (color ?? DSColors.primary).withValues(alpha: (0.2 * 255)),
              (color ?? DSColors.primary).withValues(alpha: (0.05 * 255)),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? DSColors.primary,
          size: size * 0.5,
        ),
      ),
    );
  }
}
