import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_player.dart';
import 'playing_card_widget.dart';

class RummyOpponentWidget extends StatelessWidget {
  const RummyOpponentWidget({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.horizontal = true,
  });

  final RummyPlayer player;
  final bool isCurrentTurn;
  final bool horizontal;

  static const double _scale = 0.55;
  static const double _cardW = kCardWidth * _scale;
  static const double _cardH = kCardHeight * _scale;

  @override
  Widget build(BuildContext context) {
    final cardCount = player.hand.length.clamp(0, 8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingNameChip(
          player: player,
          isCurrentTurn: isCurrentTurn,
        ),
        const SizedBox(height: 2),
        horizontal ? _horizontalCards(cardCount) : _verticalCards(cardCount),
      ],
    );
  }

  static const double _miniArcAngle = 0.05;
  static const double _miniArcLift = 5.0;

  static double _arcAngle(int i, int count) {
    if (count <= 1) {
      return 0;
    }
    final t = (i / (count - 1)) * 2 - 1;
    return t * _miniArcAngle;
  }

  static double _arcY(int i, int count) {
    if (count <= 1) {
      return 0;
    }
    final t = (i / (count - 1)) * 2 - 1;
    return t * t * _miniArcLift;
  }

  Widget _horizontalCards(int count) {
    final overlap = _cardW * 0.45;
    return SizedBox(
      height: _cardH + _miniArcLift,
      width: overlap * count + _cardW * 0.55,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              key: ValueKey(i),
              left: i * overlap,
              top: _arcY(i, count),
              child: Transform.rotate(
                angle: _arcAngle(i, count),
                alignment: Alignment.bottomCenter,
                child: _faceDownCard(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _verticalCards(int count) {
    final overlap = _cardH * 0.35;
    return SizedBox(
      width: _cardW + _miniArcLift,
      height: overlap * count + _cardH * 0.65,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              key: ValueKey(i),
              top: i * overlap,
              left: _arcY(i, count),
              child: Transform.rotate(
                angle: _arcAngle(i, count),
                alignment: Alignment.center,
                child: _faceDownCard(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _faceDownCard() {
    const dummyCard = PlayingCard(
      id: '_back',
      suit: suitSpades,
      rank: rankAce,
      isJoker: false,
    );
    return PlayingCardWidget(
      card: dummyCard,
      faceUp: false,
      width: _cardW,
      height: _cardH,
    );
  }
}

class _PulsingNameChip extends StatefulWidget {
  const _PulsingNameChip({
    required this.player,
    required this.isCurrentTurn,
  });

  final RummyPlayer player;
  final bool isCurrentTurn;

  @override
  State<_PulsingNameChip> createState() => _PulsingNameChipState();
}

class _PulsingNameChipState extends State<_PulsingNameChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isCurrentTurn) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingNameChip old) {
    super.didUpdateWidget(old);
    if (widget.isCurrentTurn && !old.isCurrentTurn) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isCurrentTurn && old.isCurrentTurn) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isCurrentTurn
            ? DSColors.rummyAccent.withValues(alpha: 0.9)
            : DSColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isCurrentTurn
              ? DSColors.rummyAccent
              : DSColors.surfaceHighlight,
          width: 1,
        ),
      ),
      child: Text(
        '${widget.player.name} (${widget.player.hand.length}) ${widget.player.score}pts',
        style: DSTypography.labelSmall.copyWith(
          color: widget.isCurrentTurn ? Colors.black : DSColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );

    if (!widget.isCurrentTurn) {
      return chip;
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: DSColors.rummyAccent.withValues(alpha: _ctrl.value * 0.6),
              blurRadius: 8 + _ctrl.value * 6,
              spreadRadius: _ctrl.value * 2,
            ),
          ],
        ),
        child: child,
      ),
      child: chip,
    );
  }
}
