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

class LudoModeSelector extends ConsumerStatefulWidget {
  const LudoModeSelector({super.key});

  @override
  ConsumerState<LudoModeSelector> createState() => _LudoModeSelectorState();
}

class _LudoModeSelectorState extends ConsumerState<LudoModeSelector> {
  LudoDifficulty _difficulty = LudoDifficulty.medium;
  LudoDiceMode _diceMode = LudoDiceMode.classic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFF6B6B),
                  Color(0xFFE91E63),
                ],
              ).createShader(bounds),
              child: Text(
                'LUDO',
                style: DSTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Text(
            'Race tokens home — roll, capture, and use powerups!',
            style: DSTypography.bodyMedium.copyWith(color: DSColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                color: DSColors.ludoPrimary,
              ),
              Text(
                'Bot Difficulty',
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LudoDifficultyRow(
            selected: _difficulty,
            onChanged: (d) => setState(() => _difficulty = d),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                color: DSColors.ludoPrimary,
              ),
              Text(
                'Dice Mode',
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LudoDiceModeRow(
            selected: _diceMode,
            onChanged: (m) => setState(() => _diceMode = m),
          ),
          const SizedBox(height: 32),
          LudoModeButton(
            label: 'Solo vs Bots',
            icon: Icons.smart_toy_rounded,
            color: DSColors.ludoPrimary,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startSolo(_difficulty, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          LudoModeButton(
            label: 'Free-for-All (3 Players)',
            icon: Icons.group_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 3, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          LudoModeButton(
            label: 'Free-for-All (4 Players)',
            icon: Icons.groups_rounded,
            color: DSColors.ludoAccent,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startFreeForAll(playerCount: 4, diceMode: _diceMode),
          ),
          const SizedBox(height: 12),
          LudoModeButton(
            label: '2v2 Teams',
            icon: Icons.people_alt_rounded,
            color: DSColors.connectFourPrimary,
            onTap: () => ref
                .read(ludoProvider.notifier)
                .startTeamVsTeam(diceMode: _diceMode),
          ),
        ],
      ),
    );
  }
}

class LudoDifficultyRow extends StatelessWidget {
  const LudoDifficultyRow({super.key, required this.selected, required this.onChanged});

  final LudoDifficulty selected;
  final ValueChanged<LudoDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LudoDifficulty.values.map((d) {
        final isActive = d == selected;
        final label = switch (d) {
          LudoDifficulty.easy => 'Easy',
          LudoDifficulty.medium => 'Medium',
          LudoDifficulty.hard => 'Hard',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? DSColors.ludoPrimary
                      : const Color(0xFF1A1A30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? DSColors.ludoPrimary
                        : const Color(0xFF252545),
                  ),
                ),
                child: Text(
                  label,
                  style: DSTypography.labelMedium.copyWith(
                    color: isActive ? Colors.white : DSColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LudoDiceModeRow extends StatelessWidget {
  const LudoDiceModeRow({super.key, required this.selected, required this.onChanged});

  final LudoDiceMode selected;
  final ValueChanged<LudoDiceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const magicColor = Color(0xFF9C27B0);
    return Row(
      children: LudoDiceMode.values.map((m) {
        final isActive = m == selected;
        final label = m == LudoDiceMode.classic ? 'Classic Dice' : 'Magic Dice';
        final activeColor =
            m == LudoDiceMode.magic ? magicColor : DSColors.ludoPrimary;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : const Color(0xFF1A1A30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? activeColor : const Color(0xFF252545),
                  ),
                ),
                child: Text(
                  label,
                  style: DSTypography.labelMedium.copyWith(
                    color: isActive ? Colors.white : DSColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LudoModeButton extends StatelessWidget {
  const LudoModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.12)!,
              color,
              Color.lerp(color, Colors.black, 0.20)!,
            ],
            stops: const [0.0, 0.3, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: DSTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
