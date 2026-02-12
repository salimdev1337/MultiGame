import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

/// Animated stat card with entrance animation and comparison indicators
class AnimatedStatCard extends StatefulWidget {
  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
    this.improvementPercent,
    this.delay = Duration.zero,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? color;
  final double? improvementPercent; // Positive = improved, Negative = decreased
  final Duration delay;

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DSAnimations.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? DSColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: '${widget.title}: ${widget.value}'
            '${widget.subtitle != null ? ", ${widget.subtitle}" : ""}',
        excludeSemantics: true,
        child: Container(
        padding: EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: BorderRadius.circular(DSSpacing.md),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and improvement indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(DSSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DSSpacing.sm),
                  ),
                  child: Icon(
                    widget.icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (widget.improvementPercent != null)
                  _ImprovementIndicator(
                    percent: widget.improvementPercent!,
                  ),
              ],
            ),
            SizedBox(height: DSSpacing.md),

            // Title
            Text(
              widget.title,
              style: DSTypography.labelMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
            SizedBox(height: DSSpacing.xs),

            // Value
            Text(
              widget.value,
              style: DSTypography.headlineLarge.copyWith(
                color: DSColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Subtitle
            if (widget.subtitle != null) ...[
              SizedBox(height: DSSpacing.xxs),
              Text(
                widget.subtitle!,
                style: DSTypography.labelSmall.copyWith(
                  color: DSColors.textTertiary,
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

/// Improvement indicator showing percentage change
class _ImprovementIndicator extends StatelessWidget {
  const _ImprovementIndicator({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final isPositive = percent > 0;
    final color = isPositive ? DSColors.success : DSColors.error;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DSSpacing.xs,
        vertical: DSSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DSSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
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

/// Personal best stat card with trophy icon
class PersonalBestCard extends StatefulWidget {
  const PersonalBestCard({
    super.key,
    required this.gameType,
    required this.bestScore,
    required this.date,
    this.delay = Duration.zero,
  });

  final String gameType;
  final int bestScore;
  final String date;
  final Duration delay;

  @override
  State<PersonalBestCard> createState() => _PersonalBestCardState();
}

class _PersonalBestCardState extends State<PersonalBestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.slow,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DSAnimations.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getGameColor() {
    return DSColors.getGameColor(widget.gameType);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGameColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Personal best ${widget.gameType}: ${widget.bestScore}, set on ${widget.date}',
        excludeSemantics: true,
        child: Container(
        padding: EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(DSSpacing.md),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Trophy icon
            Container(
              padding: EdgeInsets.all(DSSpacing.sm),
              decoration: BoxDecoration(
                gradient: DSColors.gradientGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DSColors.warning.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: DSSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.gameType,
                    style: DSTypography.labelMedium.copyWith(
                      color: DSColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: DSSpacing.xxs),
                  Text(
                    widget.bestScore.toString(),
                    style: DSTypography.headlineMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: DSSpacing.xxs),
                  Text(
                    widget.date,
                    style: DSTypography.labelSmall.copyWith(
                      color: DSColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Stats grid container with staggered entrance animations
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.stats,
    this.crossAxisCount = 2,
  });

  final List<AnimatedStatCard> stats;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: DSSpacing.md,
        mainAxisSpacing: DSSpacing.md,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return stats[index];
      },
    );
  }
}
