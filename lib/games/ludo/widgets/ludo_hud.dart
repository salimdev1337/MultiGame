import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../models/ludo_enums.dart';
import '../models/ludo_player.dart';
import '../providers/ludo_notifier.dart';

class LudoWildcardPicker extends ConsumerWidget {
  const LudoWildcardPicker({super.key, required this.currentPlayer, required this.onRoll});

  final LudoPlayer? currentPlayer;
  final VoidCallback onRoll;

  static Color _playerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => DSColors.ludoPlayerRed,
        LudoPlayerColor.green  => DSColors.ludoPlayerGreen,
        LudoPlayerColor.blue   => DSColors.ludoPlayerBlue,
        LudoPlayerColor.yellow => DSColors.ludoPlayerYellow,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consecutiveSixes = ref.watch(
      ludoProvider.select(
        (s) => s.players.isEmpty ? 0 : s.currentPlayer.consecutiveSixes,
      ),
    );
    final canUse6 = consecutiveSixes < 2;
    final c = currentPlayer != null
        ? _playerColor(currentPlayer!.color)
        : DSColors.ludoPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Wildcard — Pick your dice value',
            style: DSTypography.labelMedium.copyWith(
              color: DSColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final v = i + 1;
              final blocked = v == 6 && !canUse6;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: blocked
                      ? null
                      : () => ref
                            .read(ludoProvider.notifier)
                            .selectWildcardValue(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: blocked
                          ? const Color(0xFF1A1A2E)
                          : c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: blocked
                            ? const Color(0xFF252545)
                            : c,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$v',
                        style: DSTypography.titleMedium.copyWith(
                          color: blocked ? DSColors.textSecondary : c,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class LudoHud extends StatelessWidget {
  const LudoHud({
    super.key,
    required this.phase,
    required this.currentPlayer,
    required this.onRoll,
  });

  final LudoPhase phase;
  final LudoPlayer? currentPlayer;
  final VoidCallback onRoll;

  static Color _playerColor(LudoPlayerColor c) => switch (c) {
        LudoPlayerColor.red    => DSColors.ludoPlayerRed,
        LudoPlayerColor.green  => DSColors.ludoPlayerGreen,
        LudoPlayerColor.blue   => DSColors.ludoPlayerBlue,
        LudoPlayerColor.yellow => DSColors.ludoPlayerYellow,
      };

  @override
  Widget build(BuildContext context) {
    if (phase == LudoPhase.rolling && currentPlayer != null && !currentPlayer!.isBot) {
      final c = _playerColor(currentPlayer!.color);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: c, width: 3)),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentPlayer!.name,
                        style: DSTypography.labelMedium.copyWith(
                          color: DSColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your turn',
                        style: DSTypography.labelSmall.copyWith(
                          color: DSColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRoll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c,
                      Color.lerp(c, const Color(0xFF000000), 0.25)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.casino_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Roll Dice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (phase == LudoPhase.rolling && currentPlayer != null && currentPlayer!.isBot) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF252545)),
            ),
            child: Text(
              'Bot is thinking...',
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (phase == LudoPhase.selectingToken) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF252545)),
            ),
            child: Text(
              'Tap a highlighted token to move',
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    if (phase == LudoPhase.selectingWildcard) {
      return LudoWildcardPicker(currentPlayer: currentPlayer, onRoll: onRoll);
    }

    return const SizedBox(height: 20);
  }
}
