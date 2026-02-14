import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Animated back button with ripple/scale effect
class GameHeaderBackButton extends StatefulWidget {
  const GameHeaderBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<GameHeaderBackButton> createState() => _GameHeaderBackButtonState();
}

class _GameHeaderBackButtonState extends State<GameHeaderBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: DSAnimations.fast, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(DSSpacing.sm),
          child: Container(
            padding: EdgeInsets.all(DSSpacing.xs),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: DSColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated settings button with rotation effect
class GameHeaderSettingsButton extends StatefulWidget {
  const GameHeaderSettingsButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<GameHeaderSettingsButton> createState() =>
      _GameHeaderSettingsButtonState();
}

class _GameHeaderSettingsButtonState extends State<GameHeaderSettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _rotationAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(DSSpacing.sm),
          child: Container(
            padding: EdgeInsets.all(DSSpacing.xs),
            child: Icon(
              Icons.settings_rounded,
              color: DSColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
