import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Custom tooltip widget with arrow pointer and animations
class DSTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final DSTooltipPosition position;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showArrow;
  final Duration waitDuration;
  final Duration showDuration;

  const DSTooltip({
    super.key,
    required this.child,
    required this.message,
    this.position = DSTooltipPosition.top,
    this.backgroundColor,
    this.textColor,
    this.showArrow = true,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  });

  @override
  State<DSTooltip> createState() => _DSTooltipState();
}

class _DSTooltipState extends State<DSTooltip>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: DSAnimations.fast,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() async {
    if (_overlayEntry != null) return;

    await Future.delayed(widget.waitDuration);
    if (!_isHovering || !mounted) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        message: widget.message,
        position: widget.position,
        targetOffset: offset,
        targetSize: size,
        fadeAnimation: _fadeAnimation,
        scaleAnimation: _scaleAnimation,
        backgroundColor: widget.backgroundColor,
        textColor: widget.textColor,
        showArrow: widget.showArrow,
      ),
    );

    overlay.insert(_overlayEntry!);
    _controller.forward();

    // Auto-hide after duration
    Future.delayed(widget.showDuration, () {
      if (_isHovering) return; // Don't hide if still hovering
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _controller.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovering = true);
        _showTooltip();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        _removeOverlay();
      },
      child: GestureDetector(
        onLongPress: () {
          setState(() => _isHovering = true);
          _showTooltip();
        },
        onLongPressEnd: (_) {
          setState(() => _isHovering = false);
          _removeOverlay();
        },
        child: widget.child,
      ),
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  final String message;
  final DSTooltipPosition position;
  final Offset targetOffset;
  final Size targetSize;
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showArrow;

  const _TooltipOverlay({
    required this.message,
    required this.position,
    required this.targetOffset,
    required this.targetSize,
    required this.fadeAnimation,
    required this.scaleAnimation,
    this.backgroundColor,
    this.textColor,
    required this.showArrow,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const arrowSize = 8.0;
    const tooltipPadding = 12.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: fadeAnimation.value,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Stack(
                  children: [
                    Positioned(
                      left: _calculateLeft(screenSize, tooltipPadding),
                      top: _calculateTop(screenSize, tooltipPadding, arrowSize),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (position == DSTooltipPosition.bottom && showArrow)
                            _buildArrow(pointingUp: true),
                          _buildTooltipBox(),
                          if (position == DSTooltipPosition.top && showArrow)
                            _buildArrow(pointingUp: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTooltipBox() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: EdgeInsets.symmetric(
        horizontal: DSSpacing.sm,
        vertical: DSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? DSColors.surfaceElevated,
        borderRadius: DSSpacing.borderRadiusMD,
        border: Border.all(
          color: (backgroundColor ?? DSColors.surfaceElevated)
              .withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        style: DSTypography.bodySmall.copyWith(
          color: textColor ?? DSColors.textPrimary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildArrow({required bool pointingUp}) {
    return CustomPaint(
      size: const Size(16, 8),
      painter: _ArrowPainter(
        color: backgroundColor ?? DSColors.surfaceElevated,
        pointingUp: pointingUp,
      ),
    );
  }

  double _calculateLeft(Size screenSize, double padding) {
    final centerX = targetOffset.dx + targetSize.width / 2;
    final left = centerX - 100; // Half of max tooltip width

    // Keep within screen bounds
    if (left < padding) return padding;
    if (left + 200 > screenSize.width - padding) {
      return screenSize.width - 200 - padding;
    }
    return left;
  }

  double _calculateTop(Size screenSize, double padding, double arrowSize) {
    switch (position) {
      case DSTooltipPosition.top:
        return targetOffset.dy - 60 - arrowSize; // Approximate tooltip height
      case DSTooltipPosition.bottom:
        return targetOffset.dy + targetSize.height + arrowSize;
      case DSTooltipPosition.left:
        return targetOffset.dy + targetSize.height / 2 - 30;
      case DSTooltipPosition.right:
        return targetOffset.dy + targetSize.height / 2 - 30;
    }
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointingUp;

  _ArrowPainter({
    required this.color,
    required this.pointingUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (pointingUp) {
      // Arrow pointing up
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Arrow pointing down
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw border on arrow
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointingUp != pointingUp;
  }
}

/// Tooltip position relative to target widget
enum DSTooltipPosition {
  top,
  bottom,
  left,
  right,
}
