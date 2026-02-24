import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../models/ludo_enums.dart';
import '../providers/ludo_notifier.dart';

Widget _tokenDot(Color color) {
  return Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.6),
          blurRadius: 8,
        ),
      ],
    ),
  );
}

class LudoWonScreen extends ConsumerWidget {
  const LudoWonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(ludoProvider.select((s) => s.players));
    final mode = ref.watch(ludoProvider.select((s) => s.mode));

    final finished = players.where((p) => p.hasWon).toList()
      ..sort((a, b) => a.finishPosition.compareTo(b.finishPosition));

    final winnerName = finished.isNotEmpty ? finished.first.name : 'Someone';

    final title = mode == LudoMode.twoVsTwo
        ? 'Team ${finished.isNotEmpty ? (finished.first.teamIndex == 0 ? "Red & Green" : "Blue & Yellow") : "?"} Wins!'
        : '$winnerName Wins!';

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            DSColors.ludoPrimary.withValues(alpha: 0.10),
            const Color(0xFF0D0D1A),
          ],
          radius: 1.0,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'WINNER',
                style: DSTypography.labelSmall.copyWith(
                  color: DSColors.ludoPrimary,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                    Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: Text(
                  title,
                  style: DSTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tokenDot(DSColors.ludoPlayerRed),
                  const SizedBox(width: 6),
                  _tokenDot(DSColors.ludoPlayerBlue),
                  const SizedBox(width: 6),
                  _tokenDot(DSColors.ludoPlayerGreen),
                  const SizedBox(width: 6),
                  _tokenDot(DSColors.ludoPlayerYellow),
                ],
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  final s = ref.read(ludoProvider);
                  switch (s.mode) {
                    case LudoMode.soloVsBots:
                      ref
                          .read(ludoProvider.notifier)
                          .startSolo(s.difficulty, diceMode: s.diceMode);
                    case LudoMode.freeForAll3:
                      ref
                          .read(ludoProvider.notifier)
                          .startFreeForAll(playerCount: 3, diceMode: s.diceMode);
                    case LudoMode.freeForAll4:
                      ref
                          .read(ludoProvider.notifier)
                          .startFreeForAll(playerCount: 4, diceMode: s.diceMode);
                    case LudoMode.twoVsTwo:
                      ref
                          .read(ludoProvider.notifier)
                          .startTeamVsTeam(diceMode: s.diceMode);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DSColors.ludoPrimary,
                        Color.lerp(
                          DSColors.ludoPrimary,
                          Colors.black,
                          0.20,
                        )!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DSColors.ludoPrimary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.replay_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Play Again',
                        style: DSTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.read(ludoProvider.notifier).goToIdle(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Main Menu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DSColors.ludoPrimary,
                  side: BorderSide(
                    color: DSColors.ludoPrimary.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
