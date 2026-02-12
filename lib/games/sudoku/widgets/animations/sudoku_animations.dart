import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:multigame/design_system/design_system.dart';

/// Victory confetti animation for Sudoku game completion
class SudokuVictoryConfetti extends StatefulWidget {
  const SudokuVictoryConfetti({
    super.key,
    required this.child,
    this.show = true,
  });

  final Widget child;
  final bool show;

  @override
  State<SudokuVictoryConfetti> createState() => _SudokuVictoryConfettiState();
}

class _SudokuVictoryConfettiState extends State<SudokuVictoryConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.show) {
      _initializeParticles();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SudokuVictoryConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _initializeParticles();
      _controller.forward(from: 0);
    }
  }

  void _initializeParticles() {
    _particles.clear();
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          x: random.nextDouble(),
          y: -0.1,
          vx: (random.nextDouble() - 0.5) * 0.5,
          vy: random.nextDouble() * 0.5 + 0.3,
          rotation: random.nextDouble() * 2 * math.pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
          color: _getRandomColor(random),
          size: random.nextDouble() * 8 + 4,
        ),
      );
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      DSColors.primary,
      DSColors.secondary,
      DSColors.success,
      DSColors.warning,
      DSColors.sudokuAccent,
    ];
    return colors[random.nextInt(colors.length)];
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
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update particle position
      final x = (particle.x + particle.vx * progress) * size.width;
      final y = (particle.y + particle.vy * progress) * size.height;
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

/// Glassmorphic pause overlay for Sudoku
class SudokuPauseOverlay extends StatelessWidget {
  const SudokuPauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.scrimDark,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(DSSpacing.xl),
            padding: EdgeInsets.all(DSSpacing.xl),
            decoration: BoxDecoration(
              gradient: DSColors.gradientGlass,
              borderRadius: BorderRadius.circular(DSSpacing.lg),
              border: Border.all(
                color: DSColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause icon
                Container(
                  padding: EdgeInsets.all(DSSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DSColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.pause_rounded,
                    size: 48,
                    color: DSColors.primary,
                  ),
                ),
                SizedBox(height: DSSpacing.lg),

                // Title
                Text(
                  'Game Paused',
                  style: DSTypography.headlineMedium.copyWith(
                    color: DSColors.textPrimary,
                  ),
                ),
                SizedBox(height: DSSpacing.md),

                Text(
                  'Take your time!',
                  style: DSTypography.bodyMedium.copyWith(
                    color: DSColors.textSecondary,
                  ),
                ),
                SizedBox(height: DSSpacing.xl),

                // Action buttons
                _PauseButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Resume',
                  color: DSColors.success,
                  onPressed: onResume,
                ),
                SizedBox(height: DSSpacing.md),

                _PauseButton(
                  icon: Icons.refresh_rounded,
                  label: 'Restart',
                  color: DSColors.warning,
                  onPressed: onRestart,
                ),
                SizedBox(height: DSSpacing.md),

                _PauseButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Quit',
                  color: DSColors.error,
                  onPressed: onQuit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DSSpacing.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DSSpacing.lg,
            vertical: DSSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DSSpacing.md),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: DSSpacing.sm),
              Text(
                label,
                style: DSTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error shake animation wrapper
class ShakeAnimation extends StatefulWidget {
  const ShakeAnimation({
    super.key,
    required this.child,
    required this.shake,
    this.onComplete,
  });

  final Widget child;
  final bool shake;
  final VoidCallback? onComplete;

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
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
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Spotlight effect for hint reveal
class SpotlightEffect extends StatefulWidget {
  const SpotlightEffect({
    super.key,
    required this.child,
    required this.show,
    this.position = Offset.zero,
  });

  final Widget child;
  final bool show;
  final Offset position;

  @override
  State<SpotlightEffect> createState() => _SpotlightEffectState();
}

class _SpotlightEffectState extends State<SpotlightEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SpotlightEffect oldWidget) {
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
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SpotlightPainter(
                      position: widget.position,
                      progress: _controller.value,
                      color: DSColors.sudokuAccent,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Offset position;
  final double progress;
  final Color color;

  SpotlightPainter({
    required this.position,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.3 * progress),
          color.withValues(alpha: 0.1 * progress),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: position,
          radius: 100 * progress,
        ),
      );

    canvas.drawCircle(position, 100 * progress, paint);
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) => true;
}

/// Pop animation for number placement
class PopAnimation extends StatefulWidget {
  const PopAnimation({
    super.key,
    required this.child,
    required this.trigger,
  });

  final Widget child;
  final bool trigger;

  @override
  State<PopAnimation> createState() => _PopAnimationState();
}

class _PopAnimationState extends State<PopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.fast,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: DSAnimations.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(PopAnimation oldWidget) {
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}
