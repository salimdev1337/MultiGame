/// Premium Achievement Card Widget
/// Enhanced achievement cards with animations and visual effects
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/achievement_model.dart';
import 'package:confetti/confetti.dart';

/// Premium animated achievement card
class PremiumAchievementCard extends StatefulWidget {
  final AchievementModel achievement;
  final int index;

  const PremiumAchievementCard({
    super.key,
    required this.achievement,
    this.index = 0,
  });

  @override
  State<PremiumAchievementCard> createState() =>
      _PremiumAchievementCardState();
}

class _PremiumAchievementCardState extends State<PremiumAchievementCard> {
  late ConfettiController _confettiController;
  final bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Show confetti for newly unlocked achievements
    if (widget.achievement.isUnlocked && _showConfetti) {
      Future.delayed(Duration(milliseconds: 300 * widget.index), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DSSpacing.xs),
      child: Stack(
        children: [
          // Main card
          Container(
            padding: DSSpacing.paddingMD,
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: DSSpacing.borderRadiusLG,
              border: Border.all(
                color: widget.achievement.isUnlocked
                    ? DSColors.withOpacity(DSColors.primary, 0.5)
                    : DSColors.withOpacity(DSColors.textTertiary, 0.2),
                width: widget.achievement.isUnlocked ? 2 : 1,
              ),
              boxShadow: widget.achievement.isUnlocked
                  ? DSShadows.shadowPrimary
                  : null,
            ),
            child: Row(
              children: [
                // Icon with glow effect
                _buildIcon(),

                DSSpacing.gapHorizontalMD,

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.achievement.title,
                        style: DSTypography.titleMedium.copyWith(
                          color: widget.achievement.isUnlocked
                              ? DSColors.textPrimary
                              : DSColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      DSSpacing.gapVerticalXXS,

                      // Description
                      Text(
                        widget.achievement.description,
                        style: DSTypography.bodySmall.copyWith(
                          color: widget.achievement.isUnlocked
                              ? DSColors.textSecondary
                              : DSColors.withOpacity(
                                  DSColors.textTertiary,
                                  0.7,
                                ),
                        ),
                      ),

                      // Progress bar (if locked and has progress)
                      if (!widget.achievement.isUnlocked &&
                          widget.achievement.currentProgress != null &&
                          widget.achievement.targetProgress != null) ...[
                        DSSpacing.gapVerticalXS,
                        _buildProgressBar(),
                      ],
                    ],
                  ),
                ),

                // Check icon or lock
                DSSpacing.gapHorizontalMD,
                _buildStatusIcon(),
              ],
            ),
          ).animate(
            delay: Duration(milliseconds: 50 * widget.index),
          ).fadeIn(
            duration: DSAnimations.normal,
            curve: DSAnimations.easeOut,
          ).slideX(
            begin: 0.2,
            duration: DSAnimations.normal,
            curve: DSAnimations.easeOutCubic,
          ),

          // Confetti overlay
          if (widget.achievement.isUnlocked)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.3,
                  shouldLoop: false,
                  colors: const [
                    DSColors.primary,
                    DSColors.secondary,
                    DSColors.success,
                    DSColors.warning,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: widget.achievement.isUnlocked
            ? DSColors.gradientPrimary
            : null,
        color: widget.achievement.isUnlocked
            ? null
            : DSColors.withOpacity(DSColors.textTertiary, 0.1),
        borderRadius: DSSpacing.borderRadiusMD,
        boxShadow: widget.achievement.isUnlocked
            ? DSShadows.shadowPrimary
            : null,
      ),
      child: Center(
        child: Text(
          widget.achievement.isUnlocked
              ? widget.achievement.icon
              : '🔒',
          style: const TextStyle(
            fontSize: 28,
          ),
        ),
      ),
    ).animate(
      target: widget.achievement.isUnlocked ? 1 : 0,
    ).scale(
      duration: DSAnimations.slow,
      curve: DSAnimations.elasticOut,
    );
  }

  Widget _buildStatusIcon() {
    if (widget.achievement.isUnlocked) {
      return Container(
        padding: DSSpacing.paddingXXS,
        decoration: BoxDecoration(
          gradient: DSColors.gradientSuccess,
          shape: BoxShape.circle,
          boxShadow: DSShadows.shadowSuccess,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 24,
        ),
      ).animate().scale(
        duration: DSAnimations.slow,
        delay: 200.milliseconds,
        curve: DSAnimations.elasticOut,
      );
    }

    return const Icon(
      Icons.lock_outline_rounded,
      color: DSColors.textTertiary,
      size: 24,
    );
  }

  Widget _buildProgressBar() {
    final progress = (widget.achievement.currentProgress! /
            widget.achievement.targetProgress!)
        .clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Background
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: DSColors.surfaceElevated,
                      borderRadius: DSSpacing.borderRadiusFull,
                    ),
                  ),
                  // Progress
                  AnimatedContainer(
                    duration: DSAnimations.slow,
                    curve: DSAnimations.easeOutCubic,
                    height: 6,
                    width: MediaQuery.of(context).size.width * progress * 0.6,
                    decoration: BoxDecoration(
                      gradient: DSColors.gradientPrimary,
                      borderRadius: DSSpacing.borderRadiusFull,
                    ),
                  ),
                ],
              ),
            ),
            DSSpacing.gapHorizontalXS,
            Text(
              '${widget.achievement.currentProgress}/${widget.achievement.targetProgress}',
              style: DSTypography.labelSmall.copyWith(
                color: DSColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Achievement showcase section header
class AchievementSectionHeader extends StatelessWidget {
  const AchievementSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Your Achievements section',
      child: Padding(
      padding: const EdgeInsets.fromLTRB(
        DSSpacing.lg,
        DSSpacing.xl,
        DSSpacing.lg,
        DSSpacing.md,
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                DSColors.gradientPrimary.createShader(bounds),
            child: Text(
              'Your Achievements',
              style: DSTypography.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          DSSpacing.gapHorizontalXS,
          Text(
            '🏆',
            style: TextStyle(
              fontSize: 28,
              shadows: DSShadows.textShadowGlow(DSColors.warning),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).shimmer(
            duration: 2.seconds,
            color: DSColors.withOpacity(DSColors.warning, 0.5),
          ),
        ],
      ).animate().fadeIn(
        duration: DSAnimations.normal,
      ).slideX(
        begin: -0.2,
        duration: DSAnimations.normal,
        curve: DSAnimations.easeOutCubic,
      ),
      ),
    );
  }
}
