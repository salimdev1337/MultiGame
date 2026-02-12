import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:multigame/design_system/design_system.dart';

/// Smooth movement interpolation for snake segments
class SnakeSegmentAnimation extends StatefulWidget {
  const SnakeSegmentAnimation({
    super.key,
    required this.child,
    required this.from,
    required this.to,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final Offset from;
  final Offset to;
  final Duration duration;

  @override
  State<SnakeSegmentAnimation> createState() => _SnakeSegmentAnimationState();
}

class _SnakeSegmentAnimationState extends State<SnakeSegmentAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.from,
      end: widget.to,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(SnakeSegmentAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.to != oldWidget.to) {
      _offsetAnimation = Tween<Offset>(
        begin: widget.from,
        end: widget.to,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.linear,
        ),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Particle burst effect for food collection
class FoodCollectionBurst extends StatefulWidget {
  const FoodCollectionBurst({
    super.key,
    required this.position,
    required this.show,
    this.color,
  });

  final Offset position;
  final bool show;
  final Color? color;

  @override
  State<FoodCollectionBurst> createState() => _FoodCollectionBurstState();
}

class _FoodCollectionBurstState extends State<FoodCollectionBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BurstParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    if (widget.show) {
      _initializeParticles();
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _particles.clear();
        });
      }
    });
  }

  @override
  void didUpdateWidget(FoodCollectionBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _initializeParticles();
      _controller.forward(from: 0);
    }
  }

  void _initializeParticles() {
    _particles.clear();
    final random = math.Random();
    final color = widget.color ?? DSColors.snakeAccent;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final speed = random.nextDouble() * 50 + 30;

      _particles.add(
        BurstParticle(
          x: widget.position.dx,
          y: widget.position.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: random.nextDouble() * 4 + 3,
          color: color,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || _particles.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BurstPainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class BurstParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;

  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class BurstPainter extends CustomPainter {
  final List<BurstParticle> particles;
  final double progress;

  BurstPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x + particle.vx * progress;
      final y = particle.y + particle.vy * progress;
      final alpha = 1.0 - progress;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(BurstPainter oldDelegate) => true;
}

/// Power-up glow effect
class PowerUpGlow extends StatefulWidget {
  const PowerUpGlow({
    super.key,
    required this.child,
    required this.active,
    this.color,
  });

  final Widget child;
  final bool active;
  final Color? color;

  @override
  State<PowerUpGlow> createState() => _PowerUpGlowState();
}

class _PowerUpGlowState extends State<PowerUpGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PowerUpGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: widget.active
              ? BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: (widget.color ?? DSColors.snakePrimary)
                          .withValues(alpha: 0.6),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    ),
                  ],
                )
              : null,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Death animation with screen shake
class DeathAnimation extends StatefulWidget {
  const DeathAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.onComplete,
  });

  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  @override
  State<DeathAnimation> createState() => _DeathAnimationState();
}

class _DeathAnimationState extends State<DeathAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(DeathAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Snake game background animation
class SnakeBackgroundAnimation extends StatefulWidget {
  const SnakeBackgroundAnimation({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SnakeBackgroundAnimation> createState() =>
      _SnakeBackgroundAnimationState();
}

class _SnakeBackgroundAnimationState extends State<SnakeBackgroundAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DSColors.backgroundPrimary,
                    DSColors.snakePrimary.withValues(alpha: 0.05),
                    DSColors.backgroundSecondary,
                  ],
                  stops: [
                    0.0,
                    0.5 + math.sin(_controller.value * 2 * math.pi) * 0.2,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
