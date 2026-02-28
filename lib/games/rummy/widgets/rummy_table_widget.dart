import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../models/rummy_meld.dart';
import '../models/rummy_player.dart';
import 'playing_card_widget.dart';

class RummyTableWidget extends StatelessWidget {
  const RummyTableWidget({
    super.key,
    required this.players,
    required this.meldMinimum,
    required this.completingMeldIds,
    this.onOwnMeldTap,
    this.onCardDroppedOnMeld,
    this.highlightOwnMelds = false,
  });

  final List<RummyPlayer> players;
  final int meldMinimum;
  final Set<String> completingMeldIds;
  final void Function(int meldIdx)? onOwnMeldTap;
  final void Function(PlayingCard card, int meldIdx)? onCardDroppedOnMeld;
  final bool highlightOwnMelds;

  @override
  Widget build(BuildContext context) {
    final hasAnyMelds = players.any((p) => p.melds.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table',
            style: DSTypography.labelSmall
                .copyWith(color: DSColors.textSecondary, fontSize: 9),
          ),
          const SizedBox(height: 2),
          if (!hasAnyMelds)
            Text(
              'No melds yet',
              style: DSTypography.labelSmall.copyWith(
                color: DSColors.textTertiary,
                fontStyle: FontStyle.italic,
                fontSize: 9,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final player in players)
                  if (player.melds.isNotEmpty)
                    _PlayerMeldGroup(
                      player: player,
                      completingMeldIds: completingMeldIds,
                      onMeldTap: player.isHuman ? onOwnMeldTap : null,
                      onCardDroppedOnMeld:
                          player.isHuman ? onCardDroppedOnMeld : null,
                      highlightMelds: player.isHuman && highlightOwnMelds,
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayerMeldGroup extends StatelessWidget {
  const _PlayerMeldGroup({
    required this.player,
    required this.completingMeldIds,
    this.onMeldTap,
    this.onCardDroppedOnMeld,
    this.highlightMelds = false,
  });

  final RummyPlayer player;
  final Set<String> completingMeldIds;
  final void Function(int meldIdx)? onMeldTap;
  final void Function(PlayingCard card, int meldIdx)? onCardDroppedOnMeld;
  final bool highlightMelds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          player.name,
          style: DSTypography.labelSmall.copyWith(
            color:
                player.isHuman ? DSColors.rummyAccent : DSColors.textTertiary,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: player.melds.asMap().entries.map((entry) {
            final meldKey = entry.value.cards.isNotEmpty
                ? entry.value.cards.first.id
                : '';
            return _SmallMeldGroup(
              meld: entry.value,
              isCompleting: completingMeldIds.contains(meldKey),
              onTap: onMeldTap != null ? () => onMeldTap!(entry.key) : null,
              onCardDropped: onCardDroppedOnMeld != null
                  ? (card) => onCardDroppedOnMeld!(card, entry.key)
                  : null,
              highlighted: highlightMelds,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SmallMeldGroup extends StatefulWidget {
  const _SmallMeldGroup({
    required this.meld,
    required this.isCompleting,
    this.onTap,
    this.onCardDropped,
    this.highlighted = false,
  });

  final RummyMeld meld;
  final bool isCompleting;
  final VoidCallback? onTap;
  final void Function(PlayingCard)? onCardDropped;
  final bool highlighted;

  @override
  State<_SmallMeldGroup> createState() => _SmallMeldGroupState();
}

class _SmallMeldGroupState extends State<_SmallMeldGroup>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryScale;
  late final AnimationController _flashCtrl;
  bool _hovering = false;

  static const double _scale = 0.5;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entryScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
    );
    _entryCtrl.forward();

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (widget.isCompleting) {
      _flashCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_SmallMeldGroup old) {
    super.didUpdateWidget(old);
    if (widget.isCompleting && !old.isCompleting) {
      _flashCtrl.repeat(reverse: true);
    } else if (!widget.isCompleting && old.isCompleting) {
      _flashCtrl.stop();
      _flashCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(right: 3, bottom: 2),
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: DSColors.rummyFelt.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: _hovering
                ? DSColors.rummyAccent
                : widget.onTap != null || widget.onCardDropped != null
                    ? DSColors.rummyAccent.withValues(alpha: 0.85)
                    : DSColors.rummyAccent.withValues(alpha: 0.3),
            width: _hovering ? 2.0 : (widget.onTap != null ? 1.5 : 0.8),
          ),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: DSColors.rummyAccent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.meld.cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: PlayingCardWidget(
                    card: card,
                    width: kCardWidth * _scale,
                    height: kCardHeight * _scale,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    final dropWrapped = widget.onCardDropped == null
        ? container
        : DragTarget<PlayingCard>(
            onWillAcceptWithDetails: (_) {
              setState(() => _hovering = true);
              return true;
            },
            onLeave: (_) => setState(() => _hovering = false),
            onAcceptWithDetails: (details) {
              setState(() => _hovering = false);
              widget.onCardDropped!(details.data);
            },
            builder: (_, _, _) => container,
          );

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Transform.scale(
        scale: _entryScale.value,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          dropWrapped,
          if (widget.isCompleting)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flashCtrl,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: DSColors.rummyAccent
                        .withValues(alpha: _flashCtrl.value * 0.55),
                    boxShadow: [
                      BoxShadow(
                        color: DSColors.rummyAccent
                            .withValues(alpha: _flashCtrl.value * 0.7),
                        blurRadius: 10 * _flashCtrl.value,
                        spreadRadius: 3 * _flashCtrl.value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
