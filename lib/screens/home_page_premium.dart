/// Premium Enhanced Home Page
/// Uses new design system components for better UX
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/achievement_model.dart';
import 'package:multigame/models/game_model.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/streak_service.dart';
import 'package:multigame/services/storage/nickname_service.dart';
import 'package:multigame/widgets/shared/animated_welcome_header.dart';
import 'package:multigame/widgets/shared/premium_game_carousel.dart';
import 'package:multigame/widgets/shared/premium_achievement_card.dart';
import 'package:multigame/widgets/shared/ds_skeleton.dart';
import 'package:multigame/widgets/shared/ds_button.dart';
import 'package:multigame/widgets/nickname_dialog.dart';
import 'package:multigame/screens/help_support_screen.dart';
import 'package:multigame/widgets/shared/ad_banner_widget.dart';

/// Enhanced home page with premium design system
class HomePagePremium extends StatefulWidget {
  final Function(GameModel) onGameSelected;

  const HomePagePremium({super.key, required this.onGameSelected});

  @override
  State<HomePagePremium> createState() => _HomePagePremiumState();
}

class _HomePagePremiumState extends State<HomePagePremium> {
  final AchievementService _achievementService = AchievementService();
  final NicknameService _nicknameService = NicknameService();
  final StreakService _streakService = StreakService();
  final GlobalKey _carouselKey = GlobalKey();
  List<AchievementModel> _achievements = [];
  bool _isLoading = true;
  int _totalCompleted = 0;
  int _currentStreak = 0;
  String _nickname = 'Puzzle Master';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Batch: fetch all data in parallel, then rebuild exactly once
    if (mounted) setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchNickname(),
        _fetchAchievementsData(),
        _fetchStreak(),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // Writes to field only — no setState (batched by _loadData)
  Future<void> _fetchNickname() async {
    final nickname = await _nicknameService.getNickname();
    _nickname = nickname ?? 'Puzzle Master';
  }

  // Writes to field only — no setState (batched by _loadData)
  Future<void> _fetchStreak() async {
    final streakData = await _streakService.getStreakData();
    _currentStreak = streakData.currentStreak;
  }

  Future<void> _showSettingsDialog() async {
    final newNickname = await showNicknameDialog(
      context,
      currentNickname: _nickname,
      isFirstTime: false,
    );

    if (newNickname != null && newNickname != _nickname) {
      await _nicknameService.saveNickname(newNickname);
      setState(() {
        _nickname = newNickname;
      });
    }
  }

  // Writes to fields only — no setState (batched by _loadData)
  Future<void> _fetchAchievementsData() async {
    final stats = await _achievementService.getAllStats();
    final unlockedStatus = await _achievementService.checkAchievements();

    _totalCompleted = stats['totalCompleted'] ?? 0;
    _achievements = AchievementModel.getAllAchievements(
      unlockedStatus: unlockedStatus,
      totalCompleted: _totalCompleted,
      best3x3Moves: stats['best3x3Moves'],
      best4x4Moves: stats['best4x4Moves'],
      bestTime: stats['bestOverallTime'],
    );
  }

  void _scrollToCarousel() {
    final context = _carouselKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: DSAnimations.slow,
        curve: DSAnimations.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      bottomNavigationBar: const AdBannerWidget(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              DSColors.withOpacity(DSColors.primary, 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: DSColors.primary,
            backgroundColor: DSColors.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Animated Welcome Header
                SliverToBoxAdapter(
                  child: AnimatedWelcomeHeader(
                    nickname: _nickname,
                    totalCompleted: _totalCompleted,
                    currentStreak: _currentStreak,
                    onSettingsTap: _showSettingsDialog,
                  ),
                ),

                // XP Progress Bar
                SliverToBoxAdapter(
                  child:
                      XPProgressBar(
                        currentXP: _totalCompleted * 100,
                        nextLevelXP: ((_totalCompleted ~/ 5) + 1) * 500,
                        level: (_totalCompleted ~/ 5) + 1,
                      ).animate().fadeIn(
                        duration: DSAnimations.normal,
                        delay: 500.milliseconds,
                      ),
                ),

                // Gap
                const SliverToBoxAdapter(child: DSSpacing.gapVerticalLG),

                // Premium Game Carousel
                SliverToBoxAdapter(
                  child: Container(
                    key: _carouselKey,
                    child: PremiumGameCarousel(
                      onGameSelected: widget.onGameSelected,
                    ),
                  ),
                ),

                // Gap
                const SliverToBoxAdapter(child: DSSpacing.gapVerticalXL),

                // Achievement Section Header
                const SliverToBoxAdapter(child: AchievementSectionHeader()),

                // Achievements List with skeleton loading
                if (_isLoading)
                  SliverPadding(
                    padding: DSSpacing.paddingHorizontalMD,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const DSSkeletonAchievementCard(),
                        childCount: 5,
                      ),
                    ),
                  )
                else if (_achievements.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: DSSpacing.paddingHorizontalMD,
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return PremiumAchievementCard(
                          achievement: _achievements[index],
                          index: index,
                        );
                      }, childCount: _achievements.length),
                    ),
                  ),

                // Help & Support Button (Phase 7)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: DSSpacing.paddingHorizontalMD,
                    child: Column(
                      children: [
                        DSSpacing.gapVerticalXL,
                        DSButton(
                          text: 'Help & Support',
                          icon: Icons.help_outline_rounded,
                          variant: DSButtonVariant.outline,
                          fullWidth: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom padding
                SliverToBoxAdapter(child: DSSpacing.gapVerticalXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: DSSpacing.paddingXL,
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: DSSpacing.paddingXL,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          DSColors.withOpacity(DSColors.primary, 0.1),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      size: 80,
                      color: DSColors.textTertiary,
                    ),
                  ),
                  DSSpacing.gapVerticalLG,
                  Text(
                    'No achievements yet',
                    style: DSTypography.titleLarge.copyWith(
                      color: DSColors.textSecondary,
                    ),
                  ),
                  DSSpacing.gapVerticalSM,
                  Text(
                    'Complete puzzles and games to unlock achievements!',
                    style: DSTypography.bodyMedium.copyWith(
                      color: DSColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  DSSpacing.gapVerticalXL,
                  DSButton.gradient(
                    text: 'Start Playing',
                    icon: Icons.play_arrow_rounded,
                    gradient: DSColors.gradientPrimary,
                    onPressed: _scrollToCarousel,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: DSAnimations.normal)
              .scale(
                duration: DSAnimations.slow,
                curve: DSAnimations.easeOutCubic,
              ),
    );
  }
}
