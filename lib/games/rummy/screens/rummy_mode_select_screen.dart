import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';

import '../models/rummy_game_state.dart';
import '../providers/rummy_notifier.dart';
import '../widgets/tunisian_background.dart';

class RummyModeSelectScreen extends ConsumerStatefulWidget {
  const RummyModeSelectScreen({super.key});

  @override
  ConsumerState<RummyModeSelectScreen> createState() =>
      _RummyModeSelectScreenState();
}

class _RummyModeSelectScreenState extends ConsumerState<RummyModeSelectScreen> {
  bool _forcedMode = false;

  @override
  Widget build(BuildContext context) {
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
                _DifficultyButton(difficulty: diff, forcedMode: _forcedMode),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: Text(
                  'Forced Mode',
                  style: DSTypography.labelSmall.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  'Open only with the discarded card',
                  style: DSTypography.labelSmall.copyWith(color: Colors.white60),
                ),
                value: _forcedMode,
                onChanged: (v) => setState(() => _forcedMode = v),
                activeTrackColor: DSColors.rummyAccent,
              ),
              const SizedBox(height: 8),
              const _WiFiMultiplayerButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WiFiMultiplayerButton extends StatelessWidget {
  const _WiFiMultiplayerButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: DSColors.rummyAccent,
          side: BorderSide(color: DSColors.rummyAccent.withValues(alpha: 0.6)),
          minimumSize: const Size(220, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.wifi, size: 18),
        label: Text('WiFi Multiplayer', style: DSTypography.buttonLarge),
        onPressed: () => context.push(AppRoutes.rummyLobby),
      ),
    );
  }
}

class _DifficultyButton extends ConsumerWidget {
  const _DifficultyButton({required this.difficulty, required this.forcedMode});
  final AiDifficulty difficulty;
  final bool forcedMode;

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
        onPressed: () => ref.read(rummyProvider.notifier).startSolo(
              difficulty,
              gameMode: forcedMode ? RummyGameMode.forced : RummyGameMode.normal,
            ),
        child: Text(label, style: DSTypography.buttonLarge),
      ),
    );
  }
}
