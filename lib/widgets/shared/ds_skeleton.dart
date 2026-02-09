/// Design System - Skeleton Loading Component
/// Animated skeleton screens for loading states
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:multigame/design_system/design_system.dart';

/// Skeleton shape types
enum DSSkeletonShape {
  rectangle,
  circle,
  roundedRectangle,
}

/// Basic skeleton widget with shimmer effect
class DSSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final DSSkeletonShape shape;
  final BorderRadius? borderRadius;

  const DSSkeleton({
    super.key,
    this.width,
    this.height,
    this.shape = DSSkeletonShape.rectangle,
    this.borderRadius,
  });

  /// Factory: Circle skeleton (for avatars)
  factory DSSkeleton.circle({
    required double size,
  }) {
    return DSSkeleton(
      width: size,
      height: size,
      shape: DSSkeletonShape.circle,
    );
  }

  /// Factory: Rectangle with rounded corners
  factory DSSkeleton.rounded({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return DSSkeleton(
      width: width,
      height: height,
      shape: DSSkeletonShape.roundedRectangle,
      borderRadius: borderRadius ?? DSSpacing.borderRadiusMD,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DSColors.shimmerBase,
      highlightColor: DSColors.shimmerHighlight,
      period: DSAnimations.shimmer.duration,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DSColors.shimmerBase,
          shape: shape == DSSkeletonShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: shape == DSSkeletonShape.roundedRectangle
              ? (borderRadius ?? DSSpacing.borderRadiusMD)
              : null,
        ),
      ),
    );
  }
}

/// Skeleton for text lines
class DSSkeletonText extends StatelessWidget {
  final int lines;
  final double? width;
  final double lineHeight;
  final double spacing;

  const DSSkeletonText({
    super.key,
    this.lines = 3,
    this.width,
    this.lineHeight = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        // Make last line shorter
        final lineWidth = index == lines - 1
            ? (width ?? double.infinity) * 0.7
            : width;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index < lines - 1 ? spacing : 0,
          ),
          child: DSSkeleton.rounded(
            width: lineWidth,
            height: lineHeight,
            borderRadius: DSSpacing.borderRadiusXS,
          ),
        );
      }),
    );
  }
}

/// Skeleton for game cards
class DSSkeletonGameCard extends StatelessWidget {
  const DSSkeletonGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DSSkeleton.rounded(
      width: double.infinity,
      height: 280,
      borderRadius: DSSpacing.borderRadiusLG,
    );
  }
}

/// Skeleton for list items
class DSSkeletonListItem extends StatelessWidget {
  final bool hasAvatar;
  final bool hasTrailing;

  const DSSkeletonListItem({
    super.key,
    this.hasAvatar = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DSSpacing.paddingMD,
      child: Row(
        children: [
          if (hasAvatar) ...[
            DSSkeleton.circle(size: 48),
            DSSpacing.gapHorizontalMD,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSSkeleton.rounded(
                  width: double.infinity,
                  height: 16,
                ),
                DSSpacing.gapVerticalXS,
                DSSkeleton.rounded(
                  width: 150,
                  height: 12,
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            DSSpacing.gapHorizontalMD,
            DSSkeleton.rounded(
              width: 60,
              height: 32,
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for achievement cards
class DSSkeletonAchievementCard extends StatelessWidget {
  const DSSkeletonAchievementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DSSpacing.xs),
      child: DSSkeletonListItem(
        hasAvatar: true,
        hasTrailing: true,
      ),
    );
  }
}

/// Skeleton for profile header
class DSSkeletonProfileHeader extends StatelessWidget {
  const DSSkeletonProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DSSkeleton.circle(size: 120),
        DSSpacing.gapVerticalLG,
        DSSkeleton.rounded(
          width: 200,
          height: 28,
        ),
        DSSpacing.gapVerticalSM,
        DSSkeleton.rounded(
          width: 150,
          height: 16,
        ),
      ],
    );
  }
}

/// Skeleton for leaderboard entry
class DSSkeletonLeaderboardEntry extends StatelessWidget {
  final int rank;

  const DSSkeletonLeaderboardEntry({
    super.key,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: DSSpacing.paddingMD,
      child: Row(
        children: [
          // Rank number
          DSSkeleton.rounded(
            width: 32,
            height: 32,
          ),
          DSSpacing.gapHorizontalMD,
          // Avatar
          DSSkeleton.circle(size: 48),
          DSSpacing.gapHorizontalMD,
          // Name and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSSkeleton.rounded(
                  width: double.infinity,
                  height: 16,
                ),
                DSSpacing.gapVerticalXS,
                DSSkeleton.rounded(
                  width: 100,
                  height: 12,
                ),
              ],
            ),
          ),
          // Score
          DSSkeleton.rounded(
            width: 80,
            height: 24,
          ),
        ],
      ),
    );
  }
}

/// Full-screen skeleton loader
class DSSkeletonFullScreen extends StatelessWidget {
  final String? message;

  const DSSkeletonFullScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DSSkeleton.circle(size: 64),
          DSSpacing.gapVerticalLG,
          if (message != null)
            Text(
              message!,
              style: DSTypography.bodyMedium,
            ),
        ],
      ),
    );
  }
}
