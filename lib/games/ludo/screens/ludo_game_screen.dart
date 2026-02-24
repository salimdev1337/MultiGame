import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/ludo_enums.dart';
import '../providers/ludo_notifier.dart';
import '../widgets/ludo_app_bar.dart';
import '../widgets/ludo_board_view.dart';
import '../widgets/ludo_bomb_indicator.dart';
import '../widgets/ludo_mode_selector.dart';
import '../widgets/ludo_won_screen.dart';

class LudoGamePage extends ConsumerWidget {
  const LudoGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: DSColors.ludoBgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DSColors.ludoBgTop, DSColors.ludoBgBottom],
          ),
        ),
        child: SafeArea(
          child: switch (phase) {
            LudoPhase.idle => const LudoModeSelector(),
            _ => const _LudoGameBody(),
          },
        ),
      ),
    );
  }
}

class _LudoGameBody extends ConsumerStatefulWidget {
  const _LudoGameBody();

  @override
  ConsumerState<_LudoGameBody> createState() => _LudoGameBodyState();
}

class _LudoGameBodyState extends ConsumerState<_LudoGameBody> {
  bool _is3D = false;
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(ludoProvider.select((s) => s.phase));

    if (phase == LudoPhase.won) {
      return const LudoWonScreen();
    }

    return Stack(
      children: [
        Column(
          children: [
            LudoAppBar(
              is3D: _is3D,
              onToggle3D: () => setState(() => _is3D = !_is3D),
              isDark: _isDark,
              onToggleDark: () => setState(() => _isDark = !_isDark),
            ),
            Expanded(child: LudoBoardView(is3D: _is3D, isDark: _isDark)),
          ],
        ),
        const LudoTurboOvershootListener(),
      ],
    );
  }
}
