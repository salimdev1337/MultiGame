/// Design System - Premium Button Component
/// Enhanced button with animations, gradients, and effects
library;

import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Button variant types
enum DSButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  gradient,
  glassmorphic,
}

/// Button sizes
enum DSButtonSize {
  small,
  medium,
  large,
}

/// Premium animated button widget
class DSButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final IconData? icon;
  final bool iconLeading;
  final bool loading;
  final bool fullWidth;
  final Gradient? gradient;
  final List<BoxShadow>? customShadow;

  /// Accessible label for screen readers. Defaults to [text] if not provided.
  final String? semanticLabel;

  const DSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.medium,
    this.icon,
    this.iconLeading = true,
    this.loading = false,
    this.fullWidth = false,
    this.gradient,
    this.customShadow,
    this.semanticLabel,
  });

  /// Factory: Primary button
  factory DSButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.primary,
      icon: icon,
      loading: loading,
    );
  }

  /// Factory: Gradient button
  factory DSButton.gradient({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Gradient? gradient,
    bool loading = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.gradient,
      icon: icon,
      gradient: gradient,
      loading: loading,
    );
  }

  /// Factory: Outline button
  factory DSButton.outline({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool loading = false,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.outline,
      icon: icon,
      loading: loading,
    );
  }

  /// Factory: Ghost button
  factory DSButton.ghost({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return DSButton(
      text: text,
      onPressed: onPressed,
      variant: DSButtonVariant.ghost,
      icon: icon,
    );
  }

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DSAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: DSAnimations.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  EdgeInsets get _padding {
    switch (widget.size) {
      case DSButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: DSSpacing.sm,
          vertical: DSSpacing.xxs,
        );
      case DSButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: DSSpacing.lg,
          vertical: DSSpacing.xs,
        );
      case DSButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: DSSpacing.xl,
          vertical: DSSpacing.sm,
        );
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case DSButtonSize.small:
        return 14;
      case DSButtonSize.medium:
        return 16;
      case DSButtonSize.large:
        return 18;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case DSButtonSize.small:
        return 18;
      case DSButtonSize.medium:
        return 20;
      case DSButtonSize.large:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.loading;
    final label = widget.loading
        ? 'Loading'
        : (widget.semanticLabel ?? widget.text);

    return Semantics(
      label: label,
      button: true,
      enabled: !isDisabled,
      child: ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: DSAnimations.fast,
          width: widget.fullWidth ? double.infinity : null,
          padding: _padding,
          decoration: _buildDecoration(isDisabled),
          child: Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTextColor(isDisabled),
                    ),
                  ),
                )
              else if (widget.icon != null && widget.iconLeading) ...[
                Icon(
                  widget.icon,
                  size: _iconSize,
                  color: _getTextColor(isDisabled),
                ),
                DSSpacing.gapHorizontalXS,
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(isDisabled),
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.icon != null && !widget.iconLeading && !widget.loading)
                ...[
                DSSpacing.gapHorizontalXS,
                Icon(
                  widget.icon,
                  size: _iconSize,
                  color: _getTextColor(isDisabled),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  BoxDecoration _buildDecoration(bool isDisabled) {
    switch (widget.variant) {
      case DSButtonVariant.primary:
        return BoxDecoration(
          color: isDisabled
              ? DSColors.withOpacity(DSColors.primary, 0.5)
              : DSColors.primary,
          borderRadius: DSSpacing.borderRadiusMD,
          boxShadow: isDisabled
              ? null
              : (widget.customShadow ?? DSShadows.shadowPrimary),
        );

      case DSButtonVariant.secondary:
        return BoxDecoration(
          color: isDisabled
              ? DSColors.withOpacity(DSColors.secondary, 0.5)
              : DSColors.secondary,
          borderRadius: DSSpacing.borderRadiusMD,
          boxShadow: isDisabled ? null : DSShadows.shadowSecondary,
        );

      case DSButtonVariant.gradient:
        return BoxDecoration(
          gradient: isDisabled
              ? null
              : (widget.gradient ?? DSColors.gradientPrimary),
          color: isDisabled ? DSColors.surfaceElevated : null,
          borderRadius: DSSpacing.borderRadiusMD,
          boxShadow: isDisabled ? null : DSShadows.shadowLg,
        );

      case DSButtonVariant.outline:
        return BoxDecoration(
          color: _isPressed
              ? DSColors.withOpacity(DSColors.primary, 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isDisabled
                ? DSColors.textTertiary
                : DSColors.primary,
            width: DSSpacing.borderMedium,
          ),
          borderRadius: DSSpacing.borderRadiusMD,
        );

      case DSButtonVariant.ghost:
        return BoxDecoration(
          color: _isPressed
              ? DSColors.withOpacity(DSColors.primary, 0.1)
              : Colors.transparent,
          borderRadius: DSSpacing.borderRadiusMD,
        );

      case DSButtonVariant.glassmorphic:
        return BoxDecoration(
          gradient: DSColors.gradientGlass,
          border: Border.all(
            color: DSColors.withOpacity(Colors.white, 0.2),
            width: 1,
          ),
          borderRadius: DSSpacing.borderRadiusMD,
          boxShadow: isDisabled ? null : DSShadows.glassshadow,
        );
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) {
      return DSColors.textDisabled;
    }

    switch (widget.variant) {
      case DSButtonVariant.primary:
      case DSButtonVariant.secondary:
      case DSButtonVariant.gradient:
      case DSButtonVariant.glassmorphic:
        return Colors.white;
      case DSButtonVariant.outline:
      case DSButtonVariant.ghost:
        return DSColors.primary;
    }
  }
}
