import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:multigame/design_system/design_system.dart';

/// Magnetic snap animation for puzzle pieces
class MagneticSnapAnimation extends StatefulWidget {
  const MagneticSnapAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.snapDistance = 20.0,
    this.onSnapComplete,
  });

  final Widget child;
  final bool trigger;
  final double snapDistance;
  final VoidCallback? onSnapComplete;

  @override
  State<MagneticSnapAnimation> createState() => _MagneticSnapAnimationState();
}

class _MagneticSnapAnimationState extends State<MagneticSnapAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.puzzleSnap.duration,
      vsync: this,
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: DSAnimations.puzzleSnap.curve,
          ),
        );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSnapComplete?.call();
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(MagneticSnapAnimation oldWidget) {
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
        return Container(
          decoration: BoxDecoration(
            boxShadow: _glowAnimation.value > 0
                ? [
                    BoxShadow(
                      color: DSColors.puzzlePrimary.withValues(
                        alpha: _glowAnimation.value * 0.5,
                      ),
                      blurRadius: 15 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ]
                : null,
          ),
          child: Transform.scale(scale: _scaleAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Puzzle completion celebration with image reveal
class PuzzleCompletionCelebration extends StatefulWidget {
  const PuzzleCompletionCelebration({
    super.key,
    required this.imageWidget,
    required this.show,
    this.onComplete,
  });

  final Widget imageWidget;
  final bool show;
  final VoidCallback? onComplete;

  @override
  State<PuzzleCompletionCelebration> createState() =>
      _PuzzleCompletionCelebrationState();
}

class _PuzzleCompletionCelebrationState
    extends State<PuzzleCompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _celebrationController;
  late Animation<double> _revealAnimation;
  late Animation<double> _scaleAnimation;
  final List<ConfettiParticle> _confetti = [];

  @override
  void initState() {
    super.initState();

    _revealController = AnimationController(
      duration: DSAnimations.slower,
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: DSAnimations.elasticOut,
      ),
    );

    if (widget.show) {
      _startCelebration();
    }

    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _startCelebration() {
    _initializeConfetti();
    _revealController.forward();
    _celebrationController.forward();
  }

  void _initializeConfetti() {
    _confetti.clear();
    final random = math.Random();
    for (int i = 0; i < 100; i++) {
      _confetti.add(
        ConfettiParticle(
          x: random.nextDouble(),
          y: -0.1 - random.nextDouble() * 0.2,
          vx: (random.nextDouble() - 0.5) * 0.5,
          vy: random.nextDouble() * 0.4 + 0.3,
          rotation: random.nextDouble() * 2 * math.pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.3,
          color: _getRandomColor(random),
          size: random.nextDouble() * 10 + 5,
        ),
      );
    }
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      DSColors.puzzlePrimary,
      DSColors.puzzleAccent,
      DSColors.primary,
      DSColors.secondary,
      DSColors.success,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void didUpdateWidget(PuzzleCompletionCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _revealController.reset();
      _celebrationController.reset();
      _startCelebration();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: DSColors.scrimLight),
          ),
        ),

        // Confetti
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _confetti,
                    progress: _celebrationController.value,
                  ),
                );
              },
            ),
          ),
        ),

        // Revealed image
        Center(
          child: AnimatedBuilder(
            animation: _revealController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DSSpacing.lg),
                    boxShadow: [
                      BoxShadow(
                        color: DSColors.puzzlePrimary.withValues(alpha: 0.3),
                        blurRadius: 30 * _revealAnimation.value,
                        spreadRadius: 10 * _revealAnimation.value,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DSSpacing.lg),
                    child: Stack(
                      children: [
                        widget.imageWidget,
                        // Overlay with fade
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                DSColors.puzzlePrimary.withValues(
                                  alpha: (1.0 - _revealAnimation.value) * 0.5,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Victory text
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _revealController,
            builder: (context, child) {
              return Opacity(
                opacity: _revealAnimation.value,
                child: Column(
                  children: [
                    Text(
                      '🎉',
                      style: TextStyle(fontSize: 64 * _scaleAnimation.value),
                    ),
                    SizedBox(height: DSSpacing.md),
                    Text(
                      'Puzzle Complete!',
                      style: DSTypography.displaySmall.copyWith(
                        color: DSColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
      final x = (particle.x + particle.vx * progress) * size.width;
      final y = (particle.y + particle.vy * progress) * size.height;
      final rotation = particle.rotation + particle.rotationSpeed * progress;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1.0 - progress * 0.3)
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

/// Shuffle animation with card flip effect
class ShuffleAnimation extends StatefulWidget {
  const ShuffleAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 800),
  });

  final Widget child;
  final bool trigger;
  final Duration duration;

  @override
  State<ShuffleAnimation> createState() => _ShuffleAnimationState();
}

class _ShuffleAnimationState extends State<ShuffleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ShuffleAnimation oldWidget) {
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
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Piece movement trail effect
class PieceMovementTrail extends StatefulWidget {
  const PieceMovementTrail({
    super.key,
    required this.child,
    required this.isMoving,
  });

  final Widget child;
  final bool isMoving;

  @override
  State<PieceMovementTrail> createState() => _PieceMovementTrailState();
}

class _PieceMovementTrailState extends State<PieceMovementTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    if (widget.isMoving) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PieceMovementTrail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving && !oldWidget.isMoving) {
      _controller.repeat();
    } else if (!widget.isMoving && oldWidget.isMoving) {
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
    return Container(
      decoration: widget.isMoving
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: DSColors.puzzlePrimary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: widget.child,
    );
  }
}
