import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Coach mark widget for highlighting features to first-time users
class CoachMark extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final CoachMarkPosition position;
  final bool show;

  const CoachMark({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    required this.onNext,
    this.onSkip,
    this.showSkip = true,
    this.position = CoachMarkPosition.bottom,
    this.show = true,
  });

  @override
  State<CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<CoachMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.show) {
      _startAnimations();
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Repeat pulse animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  Future<void> _startAnimations() async {
    await Future.delayed(DSAnimations.fast);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    _controller.reverse().then((_) {
      widget.onNext();
    });
  }

  void _handleSkip() {
    _controller.reverse().then((_) {
      widget.onSkip?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) {
      return widget.child;
    }

    return Stack(
      children: [
        // Child widget with key
        RepaintBoundary(
          child: Container(
            key: _targetKey,
            child: widget.child,
          ),
        ),

        // Overlay
        if (widget.show)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildOverlay(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Dimmed background
        Positioned.fill(
          child: GestureDetector(
            onTap: () {}, // Prevent taps
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),

        // Highlight circle around target
        _buildHighlight(),

        // Info card
        Positioned(
          left: DSSpacing.md,
          right: DSSpacing.md,
          bottom: widget.position == CoachMarkPosition.bottom
              ? DSSpacing.xl
              : null,
          top: widget.position == CoachMarkPosition.top
              ? DSSpacing.xl
              : null,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildInfoCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlight() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _HighlightPainter(
            targetKey: _targetKey,
            pulseScale: _pulseAnimation.value,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: DSSpacing.paddingLG,
      decoration: BoxDecoration(
        gradient: DSColors.gradientGlass,
        borderRadius: DSSpacing.borderRadiusLG,
        border: Border.all(
          color: DSColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DSColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DSSpacing.xxs),
                decoration: BoxDecoration(
                  gradient: DSColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(DSSpacing.radiusSM),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: DSSpacing.iconMedium,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: DSSpacing.sm),
              Expanded(
                child: Text(
                  widget.title,
                  style: DSTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: DSColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: DSSpacing.sm),

          // Description
          Text(
            widget.description,
            style: DSTypography.bodyMedium.copyWith(
              color: DSColors.textSecondary,
              height: 1.5,
            ),
          ),

          SizedBox(height: DSSpacing.md),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.showSkip)
                TextButton(
                  onPressed: _handleSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: DSColors.textSecondary,
                  ),
                  child: Text(
                    'Skip',
                    style: DSTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              SizedBox(width: DSSpacing.xs),
              ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DSColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: DSSpacing.borderRadiusMD,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: DSSpacing.lg,
                    vertical: DSSpacing.xs,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Got it',
                      style: DSTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: DSSpacing.xxs),
                    Icon(Icons.check_rounded, size: DSSpacing.iconSmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final double pulseScale;

  _HighlightPainter({
    required this.targetKey,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final targetSize = renderBox.size;
    final targetPosition = renderBox.localToGlobal(Offset.zero);

    // Calculate circle properties
    final radius = (targetSize.width > targetSize.height
            ? targetSize.width
            : targetSize.height) /
        2 *
        1.3 *
        pulseScale;
    final center = Offset(
      targetPosition.dx + targetSize.width / 2,
      targetPosition.dy + targetSize.height / 2,
    );

    // Draw pulsing circle
    final paint = Paint()
      ..color = const Color(0xFF00d4ff).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, paint);

    // Draw inner glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00d4ff).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale;
  }
}

/// Position of coach mark info card
enum CoachMarkPosition {
  top,
  bottom,
}
