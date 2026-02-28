import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/playing_card.dart';
import '../providers/rummy_notifier.dart';

class RummyActionBar extends StatelessWidget {
  const RummyActionBar({
    super.key,
    required this.notifier,
    required this.selectedCardIds,
    required this.isOpen,
    required this.canUndo,
    required this.humanHand,
  });

  final RummyNotifier notifier;
  final List<String> selectedCardIds;
  final bool isOpen;
  final bool canUndo;
  final List<PlayingCard> humanHand;

  @override
  Widget build(BuildContext context) {
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
              child: SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.undo, size: 14),
                  label: const Text('Undo', style: TextStyle(fontSize: 11)),
                  onPressed: canUndo ? notifier.undo : null,
                ),
              ),
            ),
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
                child: SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.rummyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Lay Meld', style: TextStyle(fontSize: 11)),
                    onPressed: showLay
                        ? () {
                            final error = notifier.laySelectedMeld();
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: showDiscard,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 14),
                  label: const Text('Discard', style: TextStyle(fontSize: 11)),
                  onPressed: showDiscard ? () => _discardSelected(context) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _discardSelected(BuildContext context) {
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
