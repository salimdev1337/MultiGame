import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:multigame/design_system/design_system.dart';

/// Parallax background layers for infinite runner
class ParallaxBackground extends StatefulWidget {
  const ParallaxBackground({
    super.key,
    required this.layers,
    required this.scrollSpeed,
  });

  final List<ParallaxLayer> layers;
  final double scrollSpeed;

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
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
      children: widget.layers.map((layer) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = (_controller.value * widget.scrollSpeed * layer.speed) % 1.0;
            return Transform.translate(
              offset: Offset(-offset * MediaQuery.of(context).size.width, 0),
              child: Row(
                children: [
                  layer.widget,
                  layer.widget,
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class ParallaxLayer {
  final Widget widget;
  final double speed;

  ParallaxLayer({required this.widget, required this.speed});
}

/// Screen shake effect for obstacle collisions
class ScreenShakeEffect extends StatefulWidget {
  const ScreenShakeEffect({
    super.key,
    required this.child,
    required this.trigger,
    this.intensity = 10.0,
  });

  final Widget child;
  final bool trigger;
  final double intensity;

  @override
  State<ScreenShakeEffect> createState() => _ScreenShakeEffectState();
}

class _ScreenShakeEffectState extends State<ScreenShakeEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: widget.intensity),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.intensity, end: -widget.intensity),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.intensity, end: widget.intensity * 0.5),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.intensity * 0.5, end: -widget.intensity * 0.5),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.intensity * 0.5, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(ScreenShakeEffect oldWidget) {
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
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Jump arc trail effect
class JumpTrailEffect extends StatefulWidget {
  const JumpTrailEffect({
    super.key,
    required this.show,
    required this.playerPosition,
  });

  final bool show;
  final Offset playerPosition;

  @override
  State<JumpTrailEffect> createState() => _JumpTrailEffectState();
}

class _JumpTrailEffectState extends State<JumpTrailEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<TrailParticle> _trailParticles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.fast,
      vsync: this,
    )..repeat();

    _controller.addListener(_updateTrail);
  }

  void _updateTrail() {
    if (widget.show) {
      setState(() {
        _trailParticles.add(
          TrailParticle(
            position: widget.playerPosition,
            timestamp: DateTime.now(),
          ),
        );

        // Remove old particles
        _trailParticles.removeWhere((p) {
          return DateTime.now().difference(p.timestamp).inMilliseconds > 300;
        });
      });
    } else {
      setState(() {
        _trailParticles.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: JumpTrailPainter(
        particles: _trailParticles,
        color: DSColors.runnerPrimary,
      ),
    );
  }
}

class TrailParticle {
  final Offset position;
  final DateTime timestamp;

  TrailParticle({required this.position, required this.timestamp});
}

class JumpTrailPainter extends CustomPainter {
  final List<TrailParticle> particles;
  final Color color;

  JumpTrailPainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final age = DateTime.now().difference(particle.timestamp).inMilliseconds;
      final alpha = 1.0 - (age / 300);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0) * 0.5)
        ..style = PaintingStyle.fill;

      final size = 8.0 * alpha.clamp(0.0, 1.0);
      canvas.drawCircle(particle.position, size, paint);
    }
  }

  @override
  bool shouldRepaint(JumpTrailPainter oldDelegate) => true;
}

/// Coin collection sparkle trail
class CoinCollectionSparkle extends StatefulWidget {
  const CoinCollectionSparkle({
    super.key,
    required this.position,
    required this.show,
  });

  final Offset position;
  final bool show;

  @override
  State<CoinCollectionSparkle> createState() => _CoinCollectionSparkleState();
}

class _CoinCollectionSparkleState extends State<CoinCollectionSparkle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SparkleParticle> _particles = [];

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
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(CoinCollectionSparkle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _initializeParticles();
      _controller.forward(from: 0);
    }
  }

  void _initializeParticles() {
    _particles.clear();
    final random = math.Random();

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final speed = random.nextDouble() * 40 + 20;

      _particles.add(
        SparkleParticle(
          x: widget.position.dx,
          y: widget.position.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 30, // Add upward bias
          size: random.nextDouble() * 3 + 2,
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
              painter: SparklePainter(
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

class SparkleParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;

  SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });
}

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> particles;
  final double progress;

  SparklePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final x = particle.x + particle.vx * progress;
      final y = particle.y + particle.vy * progress + 9.8 * progress * progress * 50;
      final alpha = 1.0 - progress;

      // Draw star shape
      final paint = Paint()
        ..color = DSColors.runnerAccent.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) - math.pi / 2;
        final radius = particle.size * (i % 2 == 0 ? 1.0 : 0.5);
        final px = x + math.cos(angle) * radius;
        final py = y + math.sin(angle) * radius;

        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) => true;
}

/// Speed lines effect at high velocity
class SpeedLinesEffect extends StatefulWidget {
  const SpeedLinesEffect({
    super.key,
    required this.velocity,
    this.threshold = 10.0,
  });

  final double velocity;
  final double threshold;

  @override
  State<SpeedLinesEffect> createState() => _SpeedLinesEffectState();
}

class _SpeedLinesEffectState extends State<SpeedLinesEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SpeedLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();

    _initializeLines();
  }

  void _initializeLines() {
    final random = math.Random();
    for (int i = 0; i < 10; i++) {
      _lines.add(
        SpeedLine(
          y: random.nextDouble(),
          length: random.nextDouble() * 50 + 20,
          thickness: random.nextDouble() * 2 + 1,
          speed: random.nextDouble() * 0.5 + 0.5,
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
    if (widget.velocity < widget.threshold) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: SpeedLinesPainter(
                lines: _lines,
                progress: _controller.value,
                intensity: ((widget.velocity - widget.threshold) / widget.threshold)
                    .clamp(0.0, 1.0),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SpeedLine {
  final double y;
  final double length;
  final double thickness;
  final double speed;

  SpeedLine({
    required this.y,
    required this.length,
    required this.thickness,
    required this.speed,
  });
}

class SpeedLinesPainter extends CustomPainter {
  final List<SpeedLine> lines;
  final double progress;
  final double intensity;

  SpeedLinesPainter({
    required this.lines,
    required this.progress,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final x = size.width - (progress * size.width * line.speed) % size.width;
      final y = line.y * size.height;

      final paint = Paint()
        ..color = DSColors.runnerPrimary.withValues(alpha: intensity * 0.3)
        ..strokeWidth = line.thickness
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - line.length, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SpeedLinesPainter oldDelegate) => true;
}
