import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';

/// Top HUD bar: lives ❤️ | bombs 💣 | range 🔥 | timer.
/// All values are read from the local player (index 0).
class BombermanHud extends ConsumerWidget {
  const BombermanHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(
      bombermanProvider.select(
        (gs) {
          final p = gs.players.isNotEmpty ? gs.players[0] : null;
          return (
            lives: p?.lives ?? 0,
            maxBombs: p?.maxBombs ?? 1,
            activeBombs: p?.activeBombs ?? 0,
            range: p?.range ?? 1,
            time: gs.roundTimeSeconds,
          );
        },
      ),
    );

    final availableBombs = (s.maxBombs - s.activeBombs).clamp(0, s.maxBombs);
    final danger = s.time <= 30;
    final mins = s.time ~/ 60;
    final secs = s.time % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      color: const Color(0xFF070910),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Lives ────────────────────────────────────────────────────────
          _IconPips(
            filledIcon: Icons.favorite_rounded,
            emptyIcon: Icons.favorite_border_rounded,
            filledColor: const Color(0xFFef4444),
            emptyColor: const Color(0xFF4b1010),
            count: s.lives,
            max: 3,
            label: 'HP',
          ),

          _kDivider,

          // ── Bombs available ───────────────────────────────────────────────
          _IconPips(
            filledIcon: Icons.circle_rounded,
            emptyIcon: Icons.circle_outlined,
            filledColor: const Color(0xFFf59e0b),
            emptyColor: const Color(0xFF3d2a06),
            count: availableBombs,
            max: s.maxBombs.clamp(1, 5),
            label: 'BOMB',
          ),

          _kDivider,

          // ── Blast range ───────────────────────────────────────────────────
          _RangePips(range: s.range),

          const Spacer(),

          // ── Timer ─────────────────────────────────────────────────────────
          _TimerChip(timeStr: timeStr, danger: danger),
        ],
      ),
    );
  }

  static const _kDivider = SizedBox(width: 14);
}

// ─── Individual icon pips (lives / bombs) ────────────────────────────────────

class _IconPips extends StatelessWidget {
  final IconData filledIcon;
  final IconData emptyIcon;
  final Color filledColor;
  final Color emptyColor;
  final int count;
  final int max;
  final String label;

  const _IconPips({
    required this.filledIcon,
    required this.emptyIcon,
    required this.filledColor,
    required this.emptyColor,
    required this.count,
    required this.max,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x73FFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: List.generate(max, (i) {
            final filled = i < count;
            return Icon(
              filled ? filledIcon : emptyIcon,
              color: filled ? filledColor : emptyColor,
              size: 16,
            );
          }),
        ),
      ],
    );
  }
}

// ─── Blast range pips (horizontal colour-coded bars) ─────────────────────────

class _RangePips extends StatelessWidget {
  final int range;

  const _RangePips({required this.range});

  static const _kMaxDisplay = 6;

  // Colour shifts from orange → red as range grows
  static Color _pipColor(int i, int range) {
    final t = (i / (_kMaxDisplay - 1)).clamp(0.0, 1.0);
    return Color.lerp(
      const Color(0xFFf97316),
      const Color(0xFFef4444),
      t,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final display = range.clamp(1, _kMaxDisplay);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RANGE',
          style: TextStyle(
            color: Color(0x73FFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: List.generate(_kMaxDisplay, (i) {
            final active = i < display;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: active
                    ? _pipColor(i, display)
                    : const Color(0xFF1e2030),
                borderRadius: BorderRadius.circular(3),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _pipColor(i, display).withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Timer chip ───────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final String timeStr;
  final bool danger;

  const _TimerChip({required this.timeStr, required this.danger});

  @override
  Widget build(BuildContext context) {
    final fgColor =
        danger ? const Color(0xFFef4444) : const Color(0xFFFFFFFF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: danger
            ? const Color(0xFF2d0a0a)
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: danger
              ? const Color(0xFFef4444).withValues(alpha: 0.5)
              : const Color(0xFF374151),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Icon(
            Icons.timer_rounded,
            color: fgColor.withValues(alpha: 0.8),
            size: 14,
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: fgColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
