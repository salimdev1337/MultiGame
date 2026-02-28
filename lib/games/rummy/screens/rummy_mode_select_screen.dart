import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/tunisian_background.dart';

class RummyModeSelectScreen extends ConsumerWidget {
  const RummyModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DSColors.rummyFelt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: DSColors.rummyAccent,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Rummy',
          style: DSTypography.titleMedium.copyWith(color: DSColors.rummyAccent),
        ),
      ),
      body: TunisianBackground(
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Choose Difficulty',
              style: DSTypography.titleLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            for (final diff in AiDifficulty.values)
              _DifficultyButton(difficulty: diff),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({required this.difficulty});
  final AiDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label =
        difficulty.name[0].toUpperCase() + difficulty.name.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: DSColors.rummyPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(220, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => ref.read(rummyProvider.notifier).startSolo(difficulty),
        child: Text(label, style: DSTypography.buttonLarge),
      ),
    );
  }
}
