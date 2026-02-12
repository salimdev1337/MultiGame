import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/widgets/shared/game_header_buttons.dart';
import 'package:multigame/widgets/shared/game_header_displays.dart';

/// Universal game header with glassmorphic design.
/// Sub-components: [GameHeaderBackButton], [GameHeaderSettingsButton],
/// [GameHeaderScoreCounter], [GameHeaderTimer].
class GameHeader extends StatelessWidget implements PreferredSizeWidget {
  const GameHeader({
    super.key,
    this.title,
    this.score,
    this.timer,
    this.onBack,
    this.onSettings,
    this.actions = const [],
    this.showBackButton = true,
    this.backgroundColor,
  });

  final String? title;
  final int? score;
  final Duration? timer;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final List<Widget> actions;
  final bool showBackButton;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: (backgroundColor ?? DSColors.surface).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: DSColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: DSSpacing.md,
                vertical: DSSpacing.sm,
              ),
              child: Row(
                children: [
                  if (showBackButton) ...[
                    GameHeaderBackButton(onPressed: onBack),
                    SizedBox(width: DSSpacing.sm),
                  ],
                  if (title != null) ...[
                    Expanded(
                      child: Text(
                        title!,
                        style: DSTypography.headlineSmall.copyWith(
                          color: DSColors.textPrimary,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (score != null) ...[
                    GameHeaderScoreCounter(score: score!),
                    SizedBox(width: DSSpacing.md),
                  ],
                  if (timer != null) ...[
                    GameHeaderTimer(duration: timer!),
                    SizedBox(width: DSSpacing.md),
                  ],
                  ...actions,
                  if (onSettings != null) ...[
                    if (actions.isNotEmpty) SizedBox(width: DSSpacing.xs),
                    GameHeaderSettingsButton(onPressed: onSettings),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
