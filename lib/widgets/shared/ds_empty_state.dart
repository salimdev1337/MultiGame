/// Design System - Empty State Components
/// Beautiful empty states with icons, messages, and actions
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/widgets/shared/ds_button.dart';

/// Empty state widget with icon, title, message, and action button
///
/// Use this to display beautiful empty states throughout the app:
/// - No data/results
/// - No achievements
/// - No games played
/// - No notifications
/// - Error states
class DSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool animated;
  final Widget? customIllustration;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.animated = true,
    this.customIllustration,
  });

  /// No data empty state
  factory DSEmptyState.noData({
    String title = 'No Data',
    String message = 'There\'s nothing to show here yet.',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.textTertiary,
    );
  }

  /// No results empty state (for search, filters)
  factory DSEmptyState.noResults({
    String title = 'No Results',
    String message = 'Try adjusting your search or filters.',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.search_off_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.textTertiary,
    );
  }

  /// No achievements empty state
  factory DSEmptyState.noAchievements({
    String title = 'No Achievements Yet',
    String message = 'Complete puzzles and games to unlock achievements!',
    String? actionLabel = 'Start Playing',
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.emoji_events_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.warning,
    );
  }

  /// No games played empty state
  factory DSEmptyState.noGamesPlayed({
    String title = 'No Games Played',
    String message = 'Start playing to see your stats and progress!',
    String? actionLabel = 'Browse Games',
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.sports_esports_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.primary,
    );
  }

  /// Error empty state
  factory DSEmptyState.error({
    String title = 'Something Went Wrong',
    String message = 'We encountered an error. Please try again.',
    String? actionLabel = 'Retry',
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.error,
    );
  }

  /// Network error empty state
  factory DSEmptyState.networkError({
    String title = 'No Connection',
    String message = 'Check your internet connection and try again.',
    String? actionLabel = 'Retry',
    VoidCallback? onAction,
  }) {
    return DSEmptyState(
      icon: Icons.wifi_off_outlined,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      iconColor: DSColors.warning,
    );
  }

  /// Coming soon empty state
  factory DSEmptyState.comingSoon({
    String title = 'Coming Soon',
    String message = 'This feature is currently under development.',
  }) {
    return DSEmptyState(
      icon: Icons.hourglass_empty_outlined,
      title: title,
      message: message,
      iconColor: DSColors.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: DSSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or Custom Illustration
            if (customIllustration != null)
              customIllustration!
            else
              _buildIconContainer(),

            DSSpacing.gapVerticalLG,

            // Title
            Text(
              title,
              style: DSTypography.titleLarge.copyWith(
                color: DSColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            DSSpacing.gapVerticalSM,

            // Message
            Text(
              message,
              style: DSTypography.bodyMedium.copyWith(
                color: DSColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action Button
            if (actionLabel != null && onAction != null) ...[
              DSSpacing.gapVerticalXL,
              DSButton.gradient(
                text: actionLabel!,
                gradient: DSColors.gradientPrimary,
                onPressed: onAction,
                icon: Icons.play_arrow_rounded,
              ),
            ],
          ],
        ),
      ),
    );

    // Return with or without animation
    if (animated) {
      return content
          .animate()
          .fadeIn(duration: DSAnimations.normal)
          .scale(
            duration: DSAnimations.slow,
            curve: DSAnimations.easeOutCubic,
          );
    }

    return content;
  }

  Widget _buildIconContainer() {
    return Container(
      padding: DSSpacing.paddingXL,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            DSColors.withOpacity(
              iconColor ?? DSColors.primary,
              0.1,
            ),
            Colors.transparent,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: _BreathingIcon(
        icon: icon,
        color: iconColor ?? DSColors.textTertiary,
      ),
    );
  }
}

/// Breathing animation for icon
class _BreathingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _BreathingIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.icon,
        size: 80,
        color: widget.color,
      ),
    );
  }
}

/// Empty state list - Shows empty state in a scrollable list
class DSEmptyStateList extends StatelessWidget {
  final DSEmptyState emptyState;

  const DSEmptyStateList({
    super.key,
    required this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: emptyState,
        ),
      ],
    );
  }
}
