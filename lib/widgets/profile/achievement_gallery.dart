import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/achievement_model.dart';

/// Achievement gallery with category tabs and reveal animations
class AchievementGallery extends StatefulWidget {
  const AchievementGallery({
    super.key,
    required this.achievements,
    this.onAchievementTap,
    this.onShare,
  });

  final List<AchievementModel> achievements;
  final Function(AchievementModel)? onAchievementTap;
  final Function(AchievementModel)? onShare;

  @override
  State<AchievementGallery> createState() => _AchievementGalleryState();
}

class _AchievementGalleryState extends State<AchievementGallery>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    final categories = _getCategories();
    _tabController = TabController(length: categories.length, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategory = categories[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    return ['All', 'Completion', 'Efficiency', 'Speed'];
  }

  List<AchievementModel> _getFilteredAchievements() {
    if (_selectedCategory == 'All') {
      return widget.achievements;
    }

    return widget.achievements.where((a) {
      if (_selectedCategory == 'Completion') {
        return a.id.contains('win') ||
            a.id.contains('fan') ||
            a.id.contains('master');
      } else if (_selectedCategory == 'Efficiency') {
        return a.id.contains('efficient');
      } else if (_selectedCategory == 'Speed') {
        return a.id.contains('speed');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();
    final filteredAchievements = _getFilteredAchievements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category tabs
        _AnimatedCategoryTabs(
          categories: categories,
          controller: _tabController,
        ),
        SizedBox(height: DSSpacing.lg),

        // Achievement grid
        _AchievementGrid(
          achievements: filteredAchievements,
          onTap: widget.onAchievementTap,
          onShare: widget.onShare,
        ),
      ],
    );
  }
}

/// Animated category tabs
class _AnimatedCategoryTabs extends StatelessWidget {
  const _AnimatedCategoryTabs({
    required this.categories,
    required this.controller,
  });

  final List<String> categories;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(DSSpacing.md),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        indicator: BoxDecoration(
          gradient: DSColors.gradientPrimary,
          borderRadius: BorderRadius.circular(DSSpacing.md),
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: DSColors.textSecondary,
        labelStyle: DSTypography.labelMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: DSTypography.labelMedium,
        tabs: categories.map((category) {
          return Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: DSSpacing.sm),
              child: Text(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Achievement grid with reveal animations
class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({
    required this.achievements,
    this.onTap,
    this.onShare,
  });

  final List<AchievementModel> achievements;
  final Function(AchievementModel)? onTap;
  final Function(AchievementModel)? onShare;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: DSSpacing.md,
        mainAxisSpacing: DSSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];

        return _AchievementCard(
          achievement: achievement,
          delay: Duration(milliseconds: index * 50),
          onTap: () => onTap?.call(achievement),
          onShare: () => onShare?.call(achievement),
        );
      },
    );
  }
}

/// Individual achievement card with reveal animation
class _AchievementCard extends StatefulWidget {
  const _AchievementCard({
    required this.achievement,
    required this.delay,
    this.onTap,
    this.onShare,
  });

  final AchievementModel achievement;
  final Duration delay;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: DSAnimations.slow, vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DSAnimations.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRarityColor() {
    if (widget.achievement.id.contains('master') ||
        widget.achievement.id.contains('pro') ||
        widget.achievement.id.contains('demon')) {
      return DSColors.rarityLegendary;
    } else if (widget.achievement.id.contains('expert') ||
        widget.achievement.id.contains('efficient')) {
      return DSColors.rarityEpic;
    } else if (widget.achievement.id.contains('fan')) {
      return DSColors.rarityRare;
    }
    return DSColors.rarityCommon;
  }

  String _getRarityLabel() {
    if (widget.achievement.id.contains('master') ||
        widget.achievement.id.contains('pro') ||
        widget.achievement.id.contains('demon')) {
      return 'Legendary';
    } else if (widget.achievement.id.contains('expert') ||
        widget.achievement.id.contains('efficient')) {
      return 'Epic';
    } else if (widget.achievement.id.contains('fan')) {
      return 'Rare';
    }
    return 'Common';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor();
    final isUnlocked = widget.achievement.isUnlocked;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DSSpacing.md),
          child: Container(
            padding: EdgeInsets.all(DSSpacing.md),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.1)
                  : DSColors.surface,
              borderRadius: BorderRadius.circular(DSSpacing.md),
              border: Border.all(
                color: isUnlocked
                    ? color.withValues(alpha: 0.3)
                    : DSColors.textTertiary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon (emoji)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)],
                          )
                        : null,
                    color: isUnlocked
                        ? null
                        : DSColors.textTertiary.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      widget.achievement.icon,
                      style: TextStyle(
                        fontSize: 30,
                        color: isUnlocked ? null : DSColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: DSSpacing.sm),

                // Title
                Text(
                  widget.achievement.title,
                  style: DSTypography.labelMedium.copyWith(
                    color: isUnlocked
                        ? DSColors.textPrimary
                        : DSColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: DSSpacing.xxs),

                // Progress or rarity
                if (isUnlocked)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DSSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DSSpacing.xs),
                    ),
                    child: Text(
                      _getRarityLabel(),
                      style: DSTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: DSColors.textTertiary,
                  ),

                // Share button for unlocked achievements
                if (isUnlocked && widget.onShare != null) ...[
                  SizedBox(height: DSSpacing.xs),
                  IconButton(
                    icon: Icon(Icons.share_rounded, size: 18, color: color),
                    onPressed: widget.onShare,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Achievement detail modal with hero transition
class AchievementDetailModal extends StatefulWidget {
  const AchievementDetailModal({
    super.key,
    required this.achievement,
    this.onShare,
  });

  final AchievementModel achievement;
  final VoidCallback? onShare;

  @override
  State<AchievementDetailModal> createState() => _AchievementDetailModalState();
}

class _AchievementDetailModalState extends State<AchievementDetailModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: DSAnimations.normal,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: DSAnimations.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRarityColor() {
    if (widget.achievement.id.contains('master') ||
        widget.achievement.id.contains('pro') ||
        widget.achievement.id.contains('demon')) {
      return DSColors.rarityLegendary;
    } else if (widget.achievement.id.contains('expert') ||
        widget.achievement.id.contains('efficient')) {
      return DSColors.rarityEpic;
    } else if (widget.achievement.id.contains('fan')) {
      return DSColors.rarityRare;
    }
    return DSColors.rarityCommon;
  }

  String _getRarityLabel() {
    if (widget.achievement.id.contains('master') ||
        widget.achievement.id.contains('pro') ||
        widget.achievement.id.contains('demon')) {
      return 'Legendary';
    } else if (widget.achievement.id.contains('expert') ||
        widget.achievement.id.contains('efficient')) {
      return 'Epic';
    } else if (widget.achievement.id.contains('fan')) {
      return 'Rare';
    }
    return 'Common';
  }

  double _getProgress() {
    if (widget.achievement.currentProgress == null ||
        widget.achievement.targetProgress == null) {
      return 0.0;
    }
    return (widget.achievement.currentProgress! /
            widget.achievement.targetProgress!)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor();
    final isUnlocked = widget.achievement.isUnlocked;
    final progress = _getProgress();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(DSSpacing.lg),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(DSSpacing.lg),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon (emoji)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: [color, color.withValues(alpha: 0.6)],
                          )
                        : null,
                    color: isUnlocked
                        ? null
                        : DSColors.textTertiary.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      widget.achievement.icon,
                      style: TextStyle(
                        fontSize: 50,
                        color: isUnlocked ? null : DSColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: DSSpacing.md),

                // Title
                Text(
                  widget.achievement.title,
                  style: DSTypography.headlineSmall.copyWith(
                    color: DSColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DSSpacing.xs),

                // Rarity
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DSSpacing.md,
                    vertical: DSSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DSSpacing.sm),
                  ),
                  child: Text(
                    _getRarityLabel(),
                    style: DSTypography.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: DSSpacing.md),

                // Description
                Text(
                  widget.achievement.description,
                  style: DSTypography.bodyMedium.copyWith(
                    color: DSColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DSSpacing.lg),

                // Progress bar (if not unlocked)
                if (!isUnlocked) ...[
                  _ProgressIndicator(
                    progress: progress,
                    color: color,
                    current: widget.achievement.currentProgress ?? 0,
                    target: widget.achievement.targetProgress ?? 1,
                  ),
                  SizedBox(height: DSSpacing.lg),
                ],

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isUnlocked && widget.onShare != null) ...[
                      TextButton.icon(
                        onPressed: widget.onShare,
                        icon: Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(foregroundColor: color),
                      ),
                      SizedBox(width: DSSpacing.sm),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator for locked achievements
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.progress,
    required this.color,
    required this.current,
    required this.target,
  });

  final double progress;
  final Color color;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: DSTypography.labelMedium.copyWith(
                color: DSColors.textSecondary,
              ),
            ),
            Text(
              '$current / $target',
              style: DSTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: DSSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(DSSpacing.sm),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: DSColors.surface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
