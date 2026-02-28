import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';

class RummySortButtons extends ConsumerWidget {
  const RummySortButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(rummyProvider.select((s) => s.handSortMode));

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortChip(
            label: 'S',
            mode: HandSortMode.bySuit,
            activeMode: activeMode,
            onTap: () => ref.read(rummyProvider.notifier).sortHand(HandSortMode.bySuit),
          ),
          const SizedBox(height: 2),
          _SortChip(
            label: 'R',
            mode: HandSortMode.byRank,
            activeMode: activeMode,
            onTap: () => ref.read(rummyProvider.notifier).sortHand(HandSortMode.byRank),
          ),
          const SizedBox(height: 2),
          _SortChip(
            label: 'C',
            mode: HandSortMode.byColor,
            activeMode: activeMode,
            onTap: () => ref.read(rummyProvider.notifier).sortHand(HandSortMode.byColor),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.mode,
    required this.activeMode,
    required this.onTap,
  });

  final String label;
  final HandSortMode mode;
  final HandSortMode activeMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = activeMode == mode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? DSColors.rummyAccent : DSColors.rummyFelt.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? DSColors.rummyAccent : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
