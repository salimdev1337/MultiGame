import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../providers/rummy_notifier.dart';

class RummyActionBar extends ConsumerWidget {
  const RummyActionBar({
    super.key,
    required this.notifier,
    required this.isOpen,
    required this.canUndo,
    required this.canReturnDiscardCard,
  });

  final RummyNotifier notifier;
  final bool isOpen;
  final bool canUndo;
  final bool canReturnDiscardCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (selectedCardIds, humanHand) = ref.watch(rummyProvider.select((s) => (
      s.selectedCardIds,
      s.players.isNotEmpty ? s.players[0].hand : const <PlayingCard>[],
    )));
    final selectedCount = selectedCardIds.length;
    final showLay = selectedCount >= 3;
    final showDiscard = selectedCount == 1;
    final showOrTapHint = showLay && isOpen;

    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Visibility(
              visible: canUndo,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _RummyActionBtn(
                icon: Icons.undo,
                label: 'Undo',
                colorDark: const Color(0xFF37474F),
                colorLight: const Color(0xFF546E7A),
                glowColor: const Color(0xFF607D8B),
                onPressed: canUndo ? notifier.undo : null,
              ),
            ),
            if (canReturnDiscardCard) ...[
              const SizedBox(width: 4),
              _RummyActionBtn(
                icon: Icons.replay,
                label: 'Return',
                colorDark: DSColors.rummyAccent.withValues(alpha: 0.85),
                colorLight: DSColors.rummyAccent,
                glowColor: DSColors.rummyAccent,
                textColor: Colors.black87,
                onPressed: notifier.returnDiscardCard,
              ),
            ],
            const Spacer(),
            if (showOrTapHint)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  'or tap meld',
                  style: DSTypography.labelSmall.copyWith(
                    color: Colors.white54,
                    fontSize: 8,
                  ),
                ),
              ),
            Visibility(
              visible: showLay,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _RummyActionBtn(
                  icon: Icons.check,
                  label: 'Lay Meld',
                  colorDark: DSColors.rummyPrimary,
                  colorLight: const Color(0xFF26A69A),
                  glowColor: DSColors.rummyPrimary,
                  onPressed: showLay
                      ? () {
                          final error = notifier.laySelectedMeld();
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                duration: const Duration(seconds: 2),
                                backgroundColor: DSColors.error,
                              ),
                            );
                          }
                        }
                      : null,
                ),
              ),
            ),
            Visibility(
              visible: showDiscard,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _RummyActionBtn(
                icon: Icons.arrow_upward,
                label: 'Discard',
                colorDark: DSColors.error,
                colorLight: const Color(0xFFEF5350),
                glowColor: DSColors.error,
                onPressed: showDiscard
                    ? () =>
                        _discardSelected(context, selectedCardIds, humanHand)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _discardSelected(
    BuildContext context,
    List<String> selectedCardIds,
    List<PlayingCard> humanHand,
  ) {
    if (selectedCardIds.isEmpty || humanHand.isEmpty) {
      return;
    }
    final selectedId = selectedCardIds.first;
    final card = humanHand.firstWhere(
      (c) => c.id == selectedId,
      orElse: () => humanHand.first,
    );
    notifier.discard(card);
  }
}

class _RummyActionBtn extends StatelessWidget {
  const _RummyActionBtn({
    required this.icon,
    required this.label,
    required this.colorDark,
    required this.colorLight,
    required this.glowColor,
    required this.onPressed,
    this.textColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color colorDark;
  final Color colorLight;
  final Color glowColor;
  final VoidCallback? onPressed;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorDark, colorLight]),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
