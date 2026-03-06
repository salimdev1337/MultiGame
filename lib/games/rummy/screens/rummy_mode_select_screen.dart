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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choose Difficulty',
                  style: DSTypography.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 32),
                for (final diff in AiDifficulty.values)
                  _DifficultyCard(difficulty: diff, forcedMode: _forcedMode),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  title: Text(
                    'Forced Mode',
                    style:
                        DSTypography.labelSmall.copyWith(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Open only with the discarded card',
                    style: DSTypography.labelSmall
                        .copyWith(color: Colors.white60),
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
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.rummyLobby),
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, minHeight: 52),
          decoration: BoxDecoration(
            color: DSColors.rummyAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DSColors.rummyAccent,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi, size: 18, color: DSColors.rummyPrimary),
                const SizedBox(width: 8),
                Text(
                  'WiFi Multiplayer',
                  style: DSTypography.buttonLarge
                      .copyWith(color: DSColors.rummyAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends ConsumerStatefulWidget {
  const _DifficultyCard({required this.difficulty, required this.forcedMode});
  final AiDifficulty difficulty;
  final bool forcedMode;

  @override
  ConsumerState<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends ConsumerState<_DifficultyCard> {
  bool _pressed = false;

  static ({
    Color gradientDark,
    Color gradientLight,
    IconData icon,
    String subtitle,
  }) _style(AiDifficulty d) {
    switch (d) {
      case AiDifficulty.easy:
        return (
          gradientDark: const Color(0xFF2E7D32),
          gradientLight: const Color(0xFF43A047),
          icon: Icons.sentiment_satisfied,
          subtitle: 'Relaxed & forgiving',
        );
      case AiDifficulty.medium:
        return (
          gradientDark: const Color(0xFFE65100),
          gradientLight: const Color(0xFFFF8F00),
          icon: Icons.local_fire_department,
          subtitle: 'Balanced challenge',
        );
      case AiDifficulty.hard:
        return (
          gradientDark: const Color(0xFFB71C1C),
          gradientLight: const Color(0xFFE53935),
          icon: Icons.whatshot,
          subtitle: 'Show no mercy',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style(widget.difficulty);
    final label = widget.difficulty.name[0].toUpperCase() +
        widget.difficulty.name.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              ref.read(rummyProvider.notifier).startSolo(
                    widget.difficulty,
                    gameMode: widget.forcedMode
                        ? RummyGameMode.forced
                        : RummyGameMode.normal,
                  );
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [style.gradientDark, style.gradientLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: style.gradientLight.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(style.icon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: DSTypography.buttonLarge),
                          Text(
                            style.subtitle,
                            style: DSTypography.labelSmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
