import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_accessibility.dart';

/// A button wrapper that guarantees:
/// - Minimum 48×48dp touch target (WCAG 2.5.5)
/// - Proper button semantics for screen readers
/// - Visible focus indicator for keyboard navigation
///
/// Wraps any existing widget to make it accessible; does not change visuals
/// beyond ensuring the tappable area meets the minimum size requirement.
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onPressed,
    this.semanticHint,
    this.enabled = true,
    this.focusBorderRadius,
  });

  final Widget child;
  final String semanticLabel;
  final String? semanticHint;
  final VoidCallback? onPressed;
  final bool enabled;
  final BorderRadius? focusBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: DSAccessibility.minTouchTarget,
          minHeight: DSAccessibility.minTouchTarget,
        ),
        child: Focus(
          child: Builder(
            builder: (context) {
              final hasFocus = Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: hasFocus
                    ? DSAccessibility.buildFocusIndicator(
                        borderRadius:
                            focusBorderRadius ?? BorderRadius.circular(8),
                      )
                    : null,
                child: GestureDetector(
                  onTap: enabled ? onPressed : null,
                  behavior: HitTestBehavior.opaque,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Icon button with guaranteed touch target and semantics.
///
/// Drop-in replacement for bare IconButton uses where you need
/// accessibility guarantees.
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.size = 24.0,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AccessibleButton(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      child: SizedBox(
        width: DSAccessibility.minTouchTarget,
        height: DSAccessibility.minTouchTarget,
        child: Center(
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}
