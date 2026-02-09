/// Design System - Premium Card Component
/// Enhanced card with animations, gradients, and glassmorphism
library;

import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Card variant types
enum DSCardVariant {
  elevated,
  outlined,
  filled,
  glassmorphic,
  gradient,
}

/// Premium animated card widget
class DSCard extends StatefulWidget {
  final Widget child;
  final DSCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? customShadow;
  final bool enableHoverEffect;
  final bool enableTiltEffect;
  final BorderRadius? borderRadius;

  const DSCard({
    super.key,
    required this.child,
    this.variant = DSCardVariant.elevated,
    this.onTap,
    this.padding,
    this.color,
    this.gradient,
    this.customShadow,
    this.enableHoverEffect = true,
    this.enableTiltEffect = false,
    this.borderRadius,
  });

  /// Factory: Elevated card with shadow
  factory DSCard.elevated({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? color,
  }) {
    return DSCard(
      variant: DSCardVariant.elevated,
      onTap: onTap,
      padding: padding,
      color: color,
      child: child,
    );
  }

  /// Factory: Glassmorphic card with blur effect
  factory DSCard.glass({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return DSCard(
      variant: DSCardVariant.glassmorphic,
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }

  /// Factory: Gradient card
  factory DSCard.gradient({
    required Widget child,
    required Gradient gradient,
    VoidCallback? onTap,
    EdgeInsets? padding,
  }) {
    return DSCard(
      variant: DSCardVariant.gradient,
      gradient: gradient,
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }

  /// Factory: Outlined card
  factory DSCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? borderColor,
  }) {
    return DSCard(
      variant: DSCardVariant.outlined,
      onTap: onTap,
      padding: padding,
      child: child,
    );
  }

  @override
  State<DSCard> createState() => _DSCardState();
}

class _DSCardState extends State<DSCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;
  Offset _tiltOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DSAnimations.fast,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DSAnimations.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: DSAnimations.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverEnter(PointerEvent event) {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _handleHoverExit(PointerEvent event) {
    if (!widget.enableHoverEffect) return;
    setState(() {
      _isHovered = false;
      _tiltOffset = Offset.zero;
    });
    _controller.reverse();
  }

  void _handleHoverMove(PointerEvent event) {
    if (!widget.enableTiltEffect || !_isHovered) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(event.position);
    final size = box.size;

    // Calculate tilt based on position (normalized to -1 to 1)
    final dx = (localPosition.dx / size.width - 0.5) * 0.02;
    final dy = (localPosition.dy / size.height - 0.5) * 0.02;

    setState(() {
      _tiltOffset = Offset(dx, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      onHover: _handleHoverMove,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_tiltOffset.dy)
            ..rotateY(-_tiltOffset.dx),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _elevationAnimation,
              builder: (context, child) {
                return Container(
                  padding: widget.padding ?? DSSpacing.paddingMD,
                  decoration: _buildDecoration(),
                  child: widget.child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    final baseShadow = widget.customShadow ?? DSShadows.shadowMd;
    final elevatedShadow = DSShadows.shadowLg;

    switch (widget.variant) {
      case DSCardVariant.elevated:
        return BoxDecoration(
          color: widget.color ?? DSColors.surface,
          borderRadius: widget.borderRadius ?? DSSpacing.borderRadiusLG,
          boxShadow: _isHovered ? elevatedShadow : baseShadow,
        );

      case DSCardVariant.outlined:
        return BoxDecoration(
          color: widget.color ?? Colors.transparent,
          borderRadius: widget.borderRadius ?? DSSpacing.borderRadiusLG,
          border: Border.all(
            color: _isHovered
                ? DSColors.primary
                : DSColors.withOpacity(DSColors.textTertiary, 0.3),
            width: _isHovered
                ? DSSpacing.borderMedium
                : DSSpacing.borderThin,
          ),
        );

      case DSCardVariant.filled:
        return BoxDecoration(
          color: widget.color ?? DSColors.surfaceElevated,
          borderRadius: widget.borderRadius ?? DSSpacing.borderRadiusLG,
        );

      case DSCardVariant.glassmorphic:
        return BoxDecoration(
          gradient: DSColors.gradientGlass,
          borderRadius: widget.borderRadius ?? DSSpacing.borderRadiusLG,
          border: Border.all(
            color: DSColors.withOpacity(Colors.white, 0.2),
            width: 1,
          ),
          boxShadow: _isHovered ? DSShadows.glassshadow : baseShadow,
        );

      case DSCardVariant.gradient:
        return BoxDecoration(
          gradient: widget.gradient ?? DSColors.gradientPrimary,
          borderRadius: widget.borderRadius ?? DSSpacing.borderRadiusLG,
          boxShadow: _isHovered ? elevatedShadow : baseShadow,
        );
    }
  }
}

/// Game card with image and info
class DSGameCard extends StatelessWidget {
  final String title;
  final String description;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLocked;
  final Color? accentColor;
  final Widget? badge;

  const DSGameCard({
    super.key,
    required this.title,
    required this.description,
    this.imageUrl,
    this.icon,
    this.onTap,
    this.isLocked = false,
    this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return DSCard(
      variant: DSCardVariant.elevated,
      onTap: isLocked ? null : onTap,
      padding: EdgeInsets.zero,
      enableHoverEffect: !isLocked,
      enableTiltEffect: !isLocked,
      child: ClipRRect(
        borderRadius: DSSpacing.borderRadiusLG,
        child: Stack(
          children: [
            // Background image or color
            Positioned.fill(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: DSColors.surfaceElevated,
                          child: Icon(
                            icon ?? Icons.games,
                            size: 64,
                            color: accentColor ?? DSColors.primary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: DSColors.surfaceElevated,
                      child: Icon(
                        icon ?? Icons.games,
                        size: 64,
                        color: accentColor ?? DSColors.primary,
                      ),
                    ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      DSColors.withOpacity(Colors.black, 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Lock overlay
            if (isLocked)
              Positioned.fill(
                child: Container(
                  color: DSColors.withOpacity(Colors.black, 0.6),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      size: 48,
                      color: DSColors.textSecondary,
                    ),
                  ),
                ),
              ),

            // Badge (top right)
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: badge!,
              ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: DSSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DSTypography.titleLarge.copyWith(
                        color: Colors.white,
                        shadows: DSShadows.textShadowMd,
                      ),
                    ),
                    DSSpacing.gapVerticalXS,
                    Text(
                      description,
                      style: DSTypography.bodyMedium.copyWith(
                        color: DSColors.withOpacity(Colors.white, 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
