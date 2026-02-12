import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

class StickyRankCard extends StatefulWidget {
  final int currentRank;
  final int? previousRank;
  final String displayName;
  final int score;
  final int totalPlayers;
  final VoidCallback? onChallengeTap;

  const StickyRankCard({
    super.key,
    required this.currentRank,
    this.previousRank,
    required this.displayName,
    required this.score,
    required this.totalPlayers,
    this.onChallengeTap,
  });

  @override
  State<StickyRankCard> createState() => _StickyRankCardState();
}

class _StickyRankCardState extends State<StickyRankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get rankChange {
    if (widget.previousRank == null) return null;
    return widget.previousRank! - widget.currentRank;
  }

  int get nextMilestone {
    if (widget.currentRank <= 10) return 10;
    if (widget.currentRank <= 50) return 50;
    if (widget.currentRank <= 100) return 100;
    if (widget.currentRank <= 500) return 500;
    return 1000;
  }

  double get milestoneProgress {
    final start = nextMilestone == 10
        ? widget.totalPlayers.toDouble()
        : (nextMilestone * 2).toDouble();
    final end = nextMilestone.toDouble();
    final current = widget.currentRank.toDouble();

    return ((start - current) / (start - end)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final rankChangeDesc = rankChange == null
        ? ''
        : rankChange! > 0
            ? ', up ${rankChange!} position${rankChange! > 1 ? 's' : ''}'
            : ', down ${rankChange!.abs()} position${rankChange!.abs() > 1 ? 's' : ''}';

    return Semantics(
      label: 'Your rank: ${widget.currentRank} out of ${widget.totalPlayers}'
          ' players, ${widget.score} points$rankChangeDesc',
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: DSSpacing.paddingMD,
          padding: DSSpacing.paddingLG,
          decoration: BoxDecoration(
            gradient: DSColors.gradientGlass,
            borderRadius: DSSpacing.borderRadiusLG,
            border: Border.all(
              color: DSColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              ...DSShadows.shadowLg,
              ...DSShadows.shadowPrimary,
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: DSColors.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: DSShadows.shadowPrimary,
                    ),
                    child: Center(
                      child: Text(
                        '#${widget.currentRank}',
                        style: DSTypography.titleLarge.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DSSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'YOUR RANK',
                              style: DSTypography.labelSmall.copyWith(
                                color: DSColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (rankChange != null) ...[
                              SizedBox(width: DSSpacing.xs),
                              _RankChangeIndicator(change: rankChange!),
                            ],
                          ],
                        ),
                        SizedBox(height: DSSpacing.xxs),
                        Text(
                          widget.displayName,
                          style: DSTypography.titleMedium.copyWith(
                            color: DSColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.score.toString(),
                        style: DSTypography.headlineMedium.copyWith(
                          color: DSColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Top ${((widget.currentRank / widget.totalPlayers) * 100).toStringAsFixed(0)}%',
                        style: DSTypography.labelSmall.copyWith(
                          color: DSColors.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: DSSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next Milestone: Top $nextMilestone',
                        style: DSTypography.labelSmall.copyWith(
                          color: DSColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(milestoneProgress * 100).toStringAsFixed(0)}%',
                        style: DSTypography.labelSmall.copyWith(
                          color: DSColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DSSpacing.xxs),
                  ClipRRect(
                    borderRadius: DSSpacing.borderRadiusSM,
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: milestoneProgress,
                        backgroundColor: DSColors.surface,
                        valueColor: AlwaysStoppedAnimation(DSColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.onChallengeTap != null) ...[
                SizedBox(height: DSSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onChallengeTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.secondary,
                      foregroundColor: Colors.white,
                      padding: DSSpacing.paddingMD,
                      shape: RoundedRectangleBorder(
                        borderRadius: DSSpacing.borderRadiusMD,
                      ),
                    ),
                    icon: const Icon(Icons.sports_esports),
                    label: const Text(
                      'Challenge Players',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RankChangeIndicator extends StatelessWidget {
  final int change;

  const _RankChangeIndicator({required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == 0) return const SizedBox.shrink();

    final isPositive = change > 0;
    final color = isPositive ? DSColors.success : DSColors.error;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: DSSpacing.borderRadiusSM,
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            change.abs().toString(),
            style: DSTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
