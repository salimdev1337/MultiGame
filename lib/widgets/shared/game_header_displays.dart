import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Live score counter with smooth number transitions
class GameHeaderScoreCounter extends StatefulWidget {
  const GameHeaderScoreCounter({super.key, required this.score});

  final int score;

  @override
  State<GameHeaderScoreCounter> createState() =>
      _GameHeaderScoreCounterState();
}

class _GameHeaderScoreCounterState extends State<GameHeaderScoreCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _scoreAnimation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );
    _scoreAnimation = IntTween(begin: widget.score, end: widget.score)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(GameHeaderScoreCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = IntTween(begin: _previousScore, end: widget.score)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0.0);
      _previousScore = widget.score;
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
      animation: _scoreAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: DSSpacing.sm,
            vertical: DSSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: DSColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DSSpacing.sm),
            border: Border.all(
              color: DSColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, color: DSColors.primary, size: 16),
              SizedBox(width: DSSpacing.xxs),
              Text(
                _scoreAnimation.value.toString(),
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Timer display with pulsing effect when running low
class GameHeaderTimer extends StatefulWidget {
  const GameHeaderTimer({super.key, required this.duration});

  final Duration duration;

  @override
  State<GameHeaderTimer> createState() => _GameHeaderTimerState();
}

class _GameHeaderTimerState extends State<GameHeaderTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(GameHeaderTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration.inSeconds <= 10 && widget.duration.inSeconds > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final seconds = widget.duration.inSeconds;
    if (seconds <= 10) return DSColors.error;
    if (seconds <= 30) return DSColors.warning;
    return DSColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DSSpacing.sm,
          vertical: DSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _getTimerColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DSSpacing.sm),
          border: Border.all(
            color: _getTimerColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, color: _getTimerColor(), size: 16),
            SizedBox(width: DSSpacing.xxs),
            Text(
              _formatDuration(widget.duration),
              style: DSTypography.labelLarge.copyWith(
                color: _getTimerColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
