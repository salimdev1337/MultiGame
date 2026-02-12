import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:multigame/design_system/design_system.dart';

/// Tile merge animation with scale and rotation
class TileMergeAnimation extends StatefulWidget {
  const TileMergeAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.onComplete,
  });

  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  @override
  State<TileMergeAnimation> createState() => _TileMergeAnimationState();
}

class _TileMergeAnimationState extends State<TileMergeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.tile2048Merge.duration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: DSAnimations.tile2048Merge.curve,
    ));

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(TileMergeAnimation oldWidget) {
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Score pop-up animation for tile merges
class ScorePopup extends StatefulWidget {
  const ScorePopup({
    super.key,
    required this.score,
    required this.position,
    required this.show,
    this.color,
  });

  final int score;
  final Offset position;
  final bool show;
  final Color? color;

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -50.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ScorePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
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
    if (!widget.show) return const SizedBox.shrink();

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                '+${widget.score}',
                style: DSTypography.headlineSmall.copyWith(
                  color: widget.color ?? DSColors.game2048Primary,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Background particles for high scores
class HighScoreParticles extends StatefulWidget {
  const HighScoreParticles({
    super.key,
    required this.show,
  });

  final bool show;

  @override
  State<HighScoreParticles> createState() => _HighScoreParticlesState();
}

class _HighScoreParticlesState extends State<HighScoreParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _initializeParticles();

    if (widget.show) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(HighScoreParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.repeat();
    } else if (!widget.show && oldWidget.show) {
      _controller.stop();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles.clear();
    for (int i = 0; i < 20; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          vx: (random.nextDouble() - 0.5) * 0.05,
          vy: (random.nextDouble() - 0.5) * 0.05,
          size: random.nextDouble() * 4 + 2,
          color: DSColors.game2048Accent.withValues(
            alpha: random.nextDouble() * 0.3 + 0.2,
          ),
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
    if (!widget.show) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
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

class Particle {
  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = ((particle.x + particle.vx * progress) % 1.0) * size.width;
      final y = ((particle.y + particle.vy * progress) % 1.0) * size.height;

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Gesture trail effect for swipes
class SwipeTrailEffect extends StatefulWidget {
  const SwipeTrailEffect({
    super.key,
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  State<SwipeTrailEffect> createState() => _SwipeTrailEffectState();
}

class _SwipeTrailEffectState extends State<SwipeTrailEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<TrailPoint> _trailPoints = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.fast,
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _trailPoints.clear();
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _trailPoints.add(
        TrailPoint(
          position: details.localPosition,
          timestamp: DateTime.now(),
        ),
      );

      // Keep only recent points
      if (_trailPoints.length > 20) {
        _trailPoints.removeAt(0);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        children: [
          widget.child,
          if (_trailPoints.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: TrailPainter(
                    points: _trailPoints,
                    color: widget.color ?? DSColors.primary,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TrailPoint {
  final Offset position;
  final DateTime timestamp;

  TrailPoint({required this.position, required this.timestamp});
}

class TrailPainter extends CustomPainter {
  final List<TrailPoint> points;
  final Color color;
  final double progress;

  TrailPainter({
    required this.points,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.position.dx, points.first.position.dy);

    for (int i = 1; i < points.length; i++) {
      final p = points[i].position;
      path.lineTo(p.dx, p.dy);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1.0 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrailPainter oldDelegate) => true;
}

/// Victory animation for reaching 2048
class Game2048Victory extends StatefulWidget {
  const Game2048Victory({
    super.key,
    required this.show,
    this.onContinue,
  });

  final bool show;
  final VoidCallback? onContinue;

  @override
  State<Game2048Victory> createState() => _Game2048VictoryState();
}

class _Game2048VictoryState extends State<Game2048Victory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DSAnimations.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(Game2048Victory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: DSColors.scrimDark,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.all(DSSpacing.xl),
              padding: EdgeInsets.all(DSSpacing.xl),
              decoration: BoxDecoration(
                gradient: DSColors.gradientPrimary,
                borderRadius: BorderRadius.circular(DSSpacing.lg),
                boxShadow: [
                  BoxShadow(
                    color: DSColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉',
                    style: const TextStyle(fontSize: 64),
                  ),
                  SizedBox(height: DSSpacing.md),
                  Text(
                    'You Win!',
                    style: DSTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: DSSpacing.sm),
                  Text(
                    'You reached 2048!',
                    style: DSTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (widget.onContinue != null) ...[
                    SizedBox(height: DSSpacing.lg),
                    ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: DSColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: DSSpacing.xl,
                          vertical: DSSpacing.md,
                        ),
                      ),
                      child: const Text('Continue Playing'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
