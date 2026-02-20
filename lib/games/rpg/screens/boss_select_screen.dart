import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/providers/rpg_notifier.dart';

class BossSelectPage extends ConsumerWidget {
  const BossSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rpgProvider);
    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: DSColors.backgroundSecondary,
        title: const Text('Select Boss', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.cycle > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0x33FFD700),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Text(
                  'New Game+ (Cycle ${state.cycle})',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              'Your Stats',
              style: DSTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            _StatsRow(stats: state.playerStats),
            const SizedBox(height: 24),
            Text(
              'Choose Your Opponent',
              style: DSTypography.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _BossCard(
                    bossId: BossId.golem,
                    config: BossConfig.golem,
                    defeated: state.isBossDefeated(BossId.golem),
                    cycle: state.cycle,
                    onTap: () {
                      ref.read(rpgProvider.notifier).selectBoss(BossId.golem);
                      context.push('/play/rpg');
                    },
                  ),
                  const SizedBox(height: 12),
                  _BossCard(
                    bossId: BossId.wraith,
                    config: BossConfig.wraith,
                    defeated: state.isBossDefeated(BossId.wraith),
                    cycle: state.cycle,
                    onTap: () {
                      ref.read(rpgProvider.notifier).selectBoss(BossId.wraith);
                      context.push('/play/rpg');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'HP', value: '${stats.maxHp}'),
        const SizedBox(width: 8),
        _StatChip(label: 'ATK', value: '${stats.attack}'),
        const SizedBox(width: 8),
        _StatChip(label: 'DEF', value: '${stats.defense}'),
        const SizedBox(width: 8),
        _StatChip(
          label: 'ABILITIES',
          value: '${stats.unlockedAbilities.length}',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BossCard extends StatelessWidget {
  const _BossCard({
    required this.bossId,
    required this.config,
    required this.defeated,
    required this.cycle,
    required this.onTap,
  });

  final BossId bossId;
  final BossConfig config;
  final bool defeated;
  final int cycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scaledHp = config.scaledHp(cycle);
    final bossColor = bossId == BossId.golem
        ? const Color(0xFF808080)
        : const Color(0xFF8000CC);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: defeated ? bossColor : bossColor.withValues(alpha: 0.4),
            width: defeated ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bossColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                bossId == BossId.golem
                    ? Icons.engineering
                    : Icons.dark_mode,
                color: bossColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        config.displayName,
                        style: TextStyle(
                          color: bossColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (defeated) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF19e6a2),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HP: $scaledHp  •  ${config.phases.length} Phases',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: bossColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
