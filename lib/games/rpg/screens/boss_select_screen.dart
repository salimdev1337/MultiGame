import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/games/rpg/models/boss_config.dart';
import 'package:multigame/games/rpg/models/rpg_enums.dart';
import 'package:multigame/games/rpg/providers/rpg_notifier.dart';

class BossSelectPage extends ConsumerWidget {
  const BossSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rpgProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white54),
                    onPressed: () => context.go('/'),
                  ),
                  const Expanded(
                    child: Text(
                      'SHADOWFALL CHRONICLES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFCC2200),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  // Reset button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white24),
                    tooltip: 'Reset progress',
                    onPressed: () => _confirmReset(context, ref),
                  ),
                ],
              ),
            ),

            // Player stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatChip('HP', '${state.playerStats.maxHp}'),
                  const SizedBox(width: 8),
                  _StatChip('ATK', '${state.playerStats.attack}'),
                  const SizedBox(width: 8),
                  _StatChip('DODGE', '${state.playerStats.maxStaminaPips}'),
                  if (state.weapon != null) ...[
                    const SizedBox(width: 8),
                    _StatChip('WPN', state.weapon!.name, short: true),
                  ],
                  if (state.armor != null) ...[
                    const SizedBox(width: 8),
                    _StatChip('ARM', state.armor!.name, short: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boss list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _ChapterCard(
                    chapter: 1,
                    config: BossConfig.warden,
                    state: state,
                    onTap: () => _startFight(context, ref, BossId.warden),
                  ),
                  const SizedBox(height: 12),
                  _ChapterCard(
                    chapter: 2,
                    config: BossConfig.shaman,
                    state: state,
                    onTap: () => _startFight(context, ref, BossId.shaman),
                  ),
                  const SizedBox(height: 12),
                  _ChapterCard(
                    chapter: 3,
                    config: BossConfig.hollowKing,
                    state: state,
                    onTap: () => _startFight(context, ref, BossId.hollowKing),
                  ),
                  const SizedBox(height: 12),
                  _ChapterCard(
                    chapter: 4,
                    config: BossConfig.shadowlord,
                    state: state,
                    onTap: () => _startFight(context, ref, BossId.shadowlord),
                    isFinal: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startFight(BuildContext context, WidgetRef ref, BossId id) {
    final state = ref.read(rpgProvider);
    if (!state.isBossUnlocked(id)) {
      return;
    }
    ref.read(rpgProvider.notifier).selectBoss(id);
    context.go('/play/rpg');
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Reset Progress?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All progress will be lost.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(rpgProvider.notifier).resetProgress();
              Navigator.pop(ctx);
            },
            child: const Text('RESET', style: TextStyle(color: Color(0xFFCC2200))),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, {this.short = false});
  final String label;
  final String value;
  final bool short;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333366), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
          Text(
            short && value.length > 8 ? '${value.substring(0, 7)}…' : value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.config,
    required this.state,
    required this.onTap,
    this.isFinal = false,
  });

  final int chapter;
  final BossConfig config;
  final RpgState state;
  final VoidCallback onTap;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    final unlocked = state.isBossUnlocked(config.id);
    final defeated = state.isBossDefeated(config.id);

    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: unlocked ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: defeated
                  ? const Color(0xFF664400)
                  : isFinal
                      ? const Color(0xFF440044)
                      : const Color(0xFF333344),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Chapter label
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: defeated
                      ? const Color(0xFF331100)
                      : const Color(0xFF1A1A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    isFinal ? 'F' : 'C$chapter',
                    style: TextStyle(
                      color: defeated
                          ? const Color(0xFF664400)
                          : const Color(0xFF6666AA),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Boss info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: TextStyle(
                        color: defeated
                            ? Colors.white38
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      config.title,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HP: ${config.baseHp}  •  ${config.phases.length} phases',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Status icon
              if (defeated)
                const Icon(Icons.check_circle, color: Color(0xFF664400), size: 24)
              else if (!unlocked)
                const Icon(Icons.lock, color: Colors.white24, size: 20)
              else
                const Icon(Icons.chevron_right, color: Colors.white38, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
