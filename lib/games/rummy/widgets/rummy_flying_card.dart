import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/playing_card.dart';
import 'playing_card_widget.dart';

class FlyingCardData {
  FlyingCardData({
    required this.id,
    required this.card,
    required this.from,
    required this.to,
    this.faceUp = true,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
  });

  final String id;
  final PlayingCard card;
  final Offset from;
  final Offset to;
  final bool faceUp;
  final Duration duration;
  final Duration delay;
}

class RummyFlyingCard extends StatefulWidget {
  const RummyFlyingCard({
    super.key,
    required this.data,
    required this.onComplete,
  });

  final FlyingCardData data;
  final VoidCallback onComplete;

  @override
  State<RummyFlyingCard> createState() => _RummyFlyingCardState();
}

class _RummyFlyingCardState extends State<RummyFlyingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _posAnim;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.data.duration,
    );
    _posAnim = Tween<Offset>(
      begin: widget.data.from,
      end: widget.data.to,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    if (widget.data.delay == Duration.zero) {
      _controller.forward();
      _started = true;
    } else {
      Future.delayed(widget.data.delay, () {
        if (mounted) {
          _controller.forward();
          _started = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldFlip => !widget.data.faceUp;

  @override
  Widget build(BuildContext context) {
    if (!_started && widget.data.delay != Duration.zero) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final progress = _controller.value;
        final showFace = !_shouldFlip || progress >= 0.5;
        final flipAngle = _shouldFlip
            ? (progress < 0.5 ? progress * math.pi : (1 - progress) * math.pi)
            : 0.0;

        return Positioned(
          left: _posAnim.value.dx,
          top: _posAnim.value.dy,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(flipAngle),
            child: PlayingCardWidget(
              card: widget.data.card,
              faceUp: showFace,
            ),
          ),
        );
      },
    );
  }
}
