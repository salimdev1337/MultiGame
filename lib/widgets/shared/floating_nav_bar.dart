/// Floating Navigation Bar Widget
/// Premium glassmorphic navigation bar with animations
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:multigame/design_system/design_system.dart';

/// Navigation item data
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Floating glassmorphic navigation bar
class FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DSAnimations.fast,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      widget.onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DSSpacing.md,
        vertical: DSSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: DSSpacing.borderRadiusXL,
        boxShadow: DSShadows.shadowXl,
      ),
      child: ClipRRect(
        borderRadius: DSSpacing.borderRadiusXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DSColors.withOpacity(DSColors.surface, 0.8),
                  DSColors.withOpacity(DSColors.surfaceElevated, 0.6),
                ],
              ),
              borderRadius: DSSpacing.borderRadiusXL,
              border: Border.all(
                color: DSColors.withOpacity(Colors.white, 0.1),
                width: 1.5,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DSSpacing.sm,
                  vertical: DSSpacing.xs,
                ),
                child: Stack(
                  children: [
                    // Animated background indicator
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final progress = _controller.value;
                        final startPos = _calculatePosition(_previousIndex);
                        final endPos = _calculatePosition(widget.currentIndex);
                        final currentPos = startPos + (endPos - startPos) * progress;

                        return Positioned(
                          left: currentPos,
                          top: 4,
                          bottom: 4,
                          child: Container(
                            width: _getItemWidth(context),
                            decoration: BoxDecoration(
                              gradient: DSColors.gradientPrimary,
                              borderRadius: DSSpacing.borderRadiusLG,
                              boxShadow: DSShadows.shadowPrimary,
                            ),
                          ).animate().fadeIn(
                            duration: DSAnimations.fastest,
                          ),
                        );
                      },
                    ),

                    // Navigation items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        widget.items.length,
                        (index) => _buildNavItem(
                          item: widget.items[index],
                          index: index,
                          isActive: index == widget.currentIndex,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      duration: DSAnimations.normal,
      curve: DSAnimations.easeOutCubic,
    ).fadeIn();
  }

  Widget _buildNavItem({
    required NavItem item,
    required int index,
    required bool isActive,
  }) {
    final tabLabel = isActive
        ? '${item.label} tab, selected'
        : '${item.label} tab';
    final badgeHint = (item.badgeCount != null && item.badgeCount! > 0)
        ? ', ${item.badgeCount} notification${item.badgeCount! > 1 ? 's' : ''}'
        : '';

    return Expanded(
      child: Semantics(
        label: '$tabLabel$badgeHint',
        hint: 'Double tap to switch to ${item.label}',
        button: true,
        selected: isActive,
        child: GestureDetector(
          onTap: () => _handleTap(index),
          behavior: HitTestBehavior.opaque,
          child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DSSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with animation
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: DSAnimations.fast,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      key: ValueKey(isActive),
                      size: 28,
                      color: isActive
                          ? Colors.white
                          : DSColors.textTertiary,
                    ),
                  ).animate(
                    target: isActive ? 1 : 0,
                  ).scale(
                    duration: DSAnimations.normal,
                    curve: DSAnimations.elasticOut,
                  ),

                  // Badge indicator
                  if (item.badgeCount != null && item.badgeCount! > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: DSColors.gradientError,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DSColors.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          item.badgeCount! > 9
                              ? '9+'
                              : item.badgeCount.toString(),
                          style: DSTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      ).scale(
                        duration: 1.seconds,
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.1, 1.1),
                      ),
                    ),
                ],
              ),

              DSSpacing.gapVerticalXXS,

              // Label
              AnimatedDefaultTextStyle(
                duration: DSAnimations.fast,
                curve: DSAnimations.easeOutCubic,
                style: DSTypography.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : DSColors.textTertiary,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  double _calculatePosition(int index) {
    final itemWidth = _getItemWidth(context);
    final spacing = (MediaQuery.of(context).size.width -
        (DSSpacing.md * 2) - (DSSpacing.sm * 2)) / widget.items.length;
    return (spacing * index) + (spacing - itemWidth) / 2;
  }

  double _getItemWidth(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width -
        (DSSpacing.md * 2) - (DSSpacing.sm * 2);
    return totalWidth / widget.items.length;
  }
}

/// Preset navigation items for MultiGame
class MultiGameNavItems {
  static const List<NavItem> items = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItem(
      icon: Icons.games_outlined,
      activeIcon: Icons.games_rounded,
      label: 'Game',
    ),
    NavItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'Leaderboard',
    ),
    NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];
}
