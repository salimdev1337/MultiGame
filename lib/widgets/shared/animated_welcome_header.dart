/// Animated Welcome Header Widget
/// Premium animated header with gradient text and profile info
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';

/// Animated welcome header with user info
class AnimatedWelcomeHeader extends StatelessWidget {
  final String nickname;
  final int totalCompleted;
  final int currentStreak;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  const AnimatedWelcomeHeader({
    super.key,
    required this.nickname,
    this.totalCompleted = 0,
    this.currentStreak = 0,
    this.onSettingsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DSSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with settings button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Welcome text with fade-in animation
              Text(
                'Welcome back,',
                style: DSTypography.bodyLarge.copyWith(
                  color: DSColors.textSecondary,
                ),
              ).animate().fadeIn(
                duration: DSAnimations.fast,
                curve: DSAnimations.easeOut,
              ),

              // Settings button with scale animation
              IconButton(
                onPressed: onSettingsTap,
                icon: const Icon(
                  Icons.settings_rounded,
                  color: DSColors.textSecondary,
                ),
                tooltip: 'Settings',
              ).animate().scale(
                duration: DSAnimations.fast,
                delay: DSAnimations.faster,
                curve: DSAnimations.elasticOut,
              ),
            ],
          ),

          DSSpacing.gapVerticalXS,

          // Nickname with gradient text and slide animation
          GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                Flexible(
                  child:
                      ShaderMask(
                            shaderCallback: (bounds) =>
                                DSColors.gradientPrimary.createShader(bounds),
                            child: Text(
                              nickname,
                              style: DSTypography.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                          .animate()
                          .slideX(
                            begin: -0.3,
                            duration: DSAnimations.normal,
                            delay: 100.milliseconds,
                            curve: DSAnimations.easeOutCubic,
                          )
                          .fadeIn(duration: DSAnimations.fast),
                ),

                DSSpacing.gapHorizontalMD,

                // Achievement badge with bounce animation
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DSSpacing.sm,
                    vertical: DSSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: DSColors.gradientPrimary,
                    borderRadius: DSSpacing.borderRadiusFull,
                    boxShadow: DSShadows.shadowPrimary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 16)),
                      DSSpacing.gapHorizontalXS,
                      Text(
                        totalCompleted.toString(),
                        style: DSTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(
                  duration: DSAnimations.slow,
                  delay: 300.milliseconds,
                  curve: DSAnimations.elasticOut,
                ),
              ],
            ),
          ),

          DSSpacing.gapVerticalMD,

          // Quick stats row with stagger animation
          _buildQuickStats().animate().fadeIn(
            duration: DSAnimations.normal,
            delay: 400.milliseconds,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _StatBadge(
          icon: Icons.emoji_events_rounded,
          label: 'Achievements',
          value: totalCompleted.toString(),
          color: DSColors.warning,
        ),
        DSSpacing.gapHorizontalMD,
        _StatBadge(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: '${currentStreak}d',
          color: DSColors.secondary,
        ),
        DSSpacing.gapHorizontalMD,
        _StatBadge(
          icon: Icons.trending_up_rounded,
          label: 'Level',
          value: _calculateLevel(totalCompleted).toString(),
          color: DSColors.success,
        ),
      ],
    );
  }

  int _calculateLevel(int achievements) {
    // Simple level calculation: 1 level per 5 achievements
    return (achievements / 5).floor() + 1;
  }
}

/// Stat badge component
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DSSpacing.xs,
        vertical: DSSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: DSColors.surfaceElevated,
        borderRadius: DSSpacing.borderRadiusMD,
        border: Border.all(color: DSColors.withOpacity(color, 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          DSSpacing.gapHorizontalXXS,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: DSTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: DSTypography.bodySmall.copyWith(
                  fontSize: 9,
                  color: DSColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// XP Progress Bar Widget
class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int nextLevelXP;
  final int level;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.nextLevelXP,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXP / nextLevelXP).clamp(0.0, 1.0);

    return Padding(
      padding: DSSpacing.paddingHorizontalMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: DSTypography.labelLarge.copyWith(
                  color: DSColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$currentXP / $nextLevelXP XP',
                style: DSTypography.labelSmall.copyWith(
                  color: DSColors.textTertiary,
                ),
              ),
            ],
          ),
          DSSpacing.gapVerticalXS,
          Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: DSColors.surfaceElevated,
                  borderRadius: DSSpacing.borderRadiusFull,
                ),
              ),
              // Progress fill with gradient
              AnimatedContainer(
                duration: DSAnimations.slow,
                curve: DSAnimations.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: DSColors.gradientPrimary,
                  borderRadius: DSSpacing.borderRadiusFull,
                  boxShadow: DSShadows.shadowPrimary,
                ),
              ),
            ],
          ).animate().fadeIn(duration: DSAnimations.fast),
        ],
      ),
    );
  }
}
