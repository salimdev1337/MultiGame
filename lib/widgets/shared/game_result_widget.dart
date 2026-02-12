import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Data types ──────────────────────────────────────────────────────────────

/// A single stat entry for [GameResultWidget].
class GameResultStat {
  final String label;
  final String value;

  /// [list] layout: highlights value in [GameResultConfig.accentColor].
  final bool isHighlighted;

  /// [cards] layout: optional overlay widget shown at Positioned(top:0, right:0).
  /// Example: a small trophy icon on the "BEST" stat card (Snake).
  final Widget? cardDecoration;

  const GameResultStat(
    this.label,
    this.value, {
    this.isHighlighted = false,
    this.cardDecoration,
  });
}

/// Describes a button in [GameResultWidget].
class GameResultAction {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final GameResultButtonStyle style;

  /// Override button background color (defaults to [GameResultConfig.accentColor]).
  final Color? color;

  /// [depth3d] style only: the thick bottom border color for 3D effect.
  final Color? borderBottomColor;

  /// Override text color (used by depth3d secondary with dark background).
  final Color? labelColor;

  const GameResultAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.style = GameResultButtonStyle.gradient,
    this.color,
    this.borderBottomColor,
    this.labelColor,
  });
}

/// How stats are displayed in [GameResultWidget].
enum GameResultStatsLayout {
  /// Vertical list of rows: label on left, value on right, dividers between.
  /// Used by Sudoku Classic and Rush.
  list,

  /// Horizontal side-by-side cards with centered label + large value number.
  /// Used by Snake and Puzzle.
  cards,
}

/// How [GameResultWidget] is presented.
enum GameResultPresentation {
  /// [showModalBottomSheet] with drag handle and top-rounded corners.
  bottomSheet,

  /// [showDialog] centered on screen.
  dialog,
}

/// Button rendering style.
enum GameResultButtonStyle {
  /// Gradient [InkWell] with glow shadow — Sudoku primary.
  gradient,

  /// [ElevatedButton] with solid accent color — Snake/2048 primary.
  solid,

  /// [OutlinedButton] with white border — Snake secondary.
  outline,

  /// [TextButton] with muted white text — Sudoku secondary.
  text,

  /// Container with thick bottom border for 3D press effect — Puzzle.
  depth3d,
}

// ─── Config ──────────────────────────────────────────────────────────────────

/// Full configuration for [GameResultWidget].
/// Each game builds its own config and calls [GameResultWidget.show].
class GameResultConfig {
  final bool isVictory;
  final String title;

  /// Override title style (Snake: 28/bold/ls4, 2048: 30/w900/ls0.5, Puzzle: 36/w900/italic).
  /// Defaults to 26pt w800 white.
  final TextStyle? titleStyle;

  /// Full icon widget — each game builds its own (Icon, Stack, emoji Text, etc.).
  final Widget icon;

  /// Optional subtitle: Text, RichText, or Column. Null = no subtitle.
  final Widget? subtitle;

  final Color accentColor;

  /// Gradient colors for [GameResultButtonStyle.gradient] button.
  /// Null = solid accentColor.
  final List<Color>? accentGradient;

  /// Stats to display. Empty list = no stats section.
  final List<GameResultStat> stats;

  final GameResultStatsLayout statsLayout;

  /// Font size for stat values in [GameResultStatsLayout.cards].
  /// Snake uses 32, Puzzle uses 24.
  final double statCardValueFontSize;

  /// Horizontal gap between stat cards. Snake: 12, Puzzle: 16.
  final double statCardSpacing;

  final GameResultAction primary;
  final GameResultAction? secondary;

  /// Optional section rendered below stats (Puzzle: achievement badge).
  final Widget? extraSection;

  /// Optional footer rendered below all buttons (Snake: game mode chip).
  final Widget? footer;

  final GameResultPresentation presentation;

  /// When true (Snake): adds double BackdropFilter blur effect.
  final bool backdropBlur;

  /// When true (Sudoku): plays ScaleTransition + FadeTransition entry animation.
  /// When false: content is immediately visible.
  final bool animated;

  /// Outer container corner radius.
  /// Defaults: bottomSheet→28 (top only), dialog→24.
  final double? containerBorderRadius;

  /// Outer container background color.
  /// Defaults to Color(0xFF1a1d24).
  final Color? containerColor;

  /// Content padding. Defaults: bottomSheet→LTRB(24,12,24,0), dialog→all(24).
  final EdgeInsets? contentPadding;

  /// Wraps content in [SingleChildScrollView] (Puzzle: true).
  final bool scrollable;

  /// Max width constraint on the container. Default: maxWidth 340.
  final BoxConstraints? constraints;

  const GameResultConfig({
    required this.isVictory,
    required this.title,
    this.titleStyle,
    required this.icon,
    this.subtitle,
    required this.accentColor,
    this.accentGradient,
    this.stats = const [],
    this.statsLayout = GameResultStatsLayout.list,
    this.statCardValueFontSize = 32,
    this.statCardSpacing = 12,
    required this.primary,
    this.secondary,
    this.extraSection,
    this.footer,
    required this.presentation,
    this.backdropBlur = false,
    this.animated = false,
    this.containerBorderRadius,
    this.containerColor,
    this.contentPadding,
    this.scrollable = false,
    this.constraints,
  });
}

// ─── Widget ──────────────────────────────────────────────────────────────────

/// A shared result overlay used by Sudoku, Snake, 2048, and Puzzle.
///
/// Each game passes a [GameResultConfig] to [GameResultWidget.show] which
/// handles routing to either a bottom sheet or dialog.
///
/// Visual design, animations, colors, and button styles are all preserved
/// per-game via the config parameters.
class GameResultWidget extends StatefulWidget {
  final GameResultConfig config;

  const GameResultWidget({super.key, required this.config});

  /// Presents this widget as a bottom sheet or dialog based on [config.presentation].
  static Future<T?> show<T>(BuildContext context, GameResultConfig config) {
    if (config.presentation == GameResultPresentation.bottomSheet) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: false,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (_) => GameResultWidget(config: config),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) {
        final content = GameResultWidget(config: config);
        if (config.backdropBlur) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: content,
            ),
          );
        }
        return Dialog(
          backgroundColor: Colors.transparent,
          child: content,
        );
      },
    );
  }

  @override
  State<GameResultWidget> createState() => _GameResultWidgetState();
}

class _GameResultWidgetState extends State<GameResultWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _iconScale;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final startValue = widget.config.animated ? 0.0 : 1.0;
    _iconScale = Tween<double>(begin: startValue, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _contentFade = Tween<double>(begin: startValue, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    if (widget.config.animated) {
      _enterController.forward();
    } else {
      _enterController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final isBottomSheet =
        config.presentation == GameResultPresentation.bottomSheet;
    final radius =
        config.containerBorderRadius ?? (isBottomSheet ? 28.0 : 24.0);
    final borderRadius = isBottomSheet
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);
    final bgColor = config.containerColor ?? const Color(0xFF1a1d24);
    final padding = config.contentPadding ??
        (isBottomSheet
            ? const EdgeInsets.fromLTRB(24, 12, 24, 0)
            : const EdgeInsets.all(24));

    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar (bottom sheet only)
        if (isBottomSheet)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

        const SizedBox(height: 28),

        // Animated icon
        ScaleTransition(
          scale: _iconScale,
          child: config.icon,
        ),

        const SizedBox(height: 16),

        // Title + optional subtitle
        FadeTransition(
          opacity: _contentFade,
          child: Column(
            children: [
              Text(
                config.title,
                textAlign: TextAlign.center,
                style: config.titleStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (config.subtitle != null) ...[
                const SizedBox(height: 8),
                config.subtitle!,
              ],
            ],
          ),
        ),

        // Stats section
        if (config.stats.isNotEmpty) ...[
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _contentFade,
            child: config.statsLayout == GameResultStatsLayout.list
                ? _buildStatsList(config)
                : _buildStatsCards(config),
          ),
        ],

        // Extra section (e.g. achievement badge)
        if (config.extraSection != null) ...[
          const SizedBox(height: 20),
          config.extraSection!,
        ],

        const SizedBox(height: 20),

        // Primary button
        FadeTransition(
          opacity: _contentFade,
          child: SizedBox(
            width: double.infinity,
            child: _buildButton(config.primary, config),
          ),
        ),

        // Secondary button
        if (config.secondary != null) ...[
          SizedBox(height: isBottomSheet ? 10 : 12),
          FadeTransition(
            opacity: _contentFade,
            child: SizedBox(
              width: double.infinity,
              child: _buildButton(config.secondary!, config),
            ),
          ),
        ],

        // Footer (e.g. game mode chip)
        if (config.footer != null) ...[
          const SizedBox(height: 16),
          config.footer!,
        ],

        SizedBox(height: isBottomSheet ? 8 : 12),
      ],
    );

    if (config.scrollable) {
      body = SingleChildScrollView(child: body);
    }

    Widget container = Container(
      constraints: config.constraints ?? const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: isBottomSheet
          ? SafeArea(
              top: false,
              child: Padding(padding: padding, child: body),
            )
          : ClipRRect(
              borderRadius: borderRadius,
              child: config.backdropBlur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(padding: padding, child: body),
                    )
                  : Padding(padding: padding, child: body),
            ),
    );

    return container;
  }

  // ─── Stats layouts ──────────────────────────────────────────────────────────

  Widget _buildStatsList(GameResultConfig config) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: config.stats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: stat.isHighlighted
                            ? config.accentColor
                            : Colors.white,
                        shadows: stat.isHighlighted
                            ? [
                                Shadow(
                                  color: config.accentColor
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards(GameResultConfig config) {
    final children = <Widget>[];
    for (int i = 0; i < config.stats.length; i++) {
      if (i > 0) children.add(SizedBox(width: config.statCardSpacing));
      final stat = config.stats[i];
      final cardColumn = Column(
        children: [
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: config.statCardValueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      );
      children.add(
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: stat.cardDecoration != null
                ? Stack(
                    children: [
                      cardColumn,
                      Positioned(top: 0, right: 0, child: stat.cardDecoration!),
                    ],
                  )
                : cardColumn,
          ),
        ),
      );
    }
    return Row(children: children);
  }

  // ─── Button builders ────────────────────────────────────────────────────────

  Widget _buildButton(GameResultAction action, GameResultConfig config) {
    switch (action.style) {
      case GameResultButtonStyle.gradient:
        final gradient =
            config.accentGradient ?? [config.accentColor, config.accentColor];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: config.accentColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (action.icon != null) ...[
                      Icon(action.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      action.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case GameResultButtonStyle.solid:
        final btnColor = action.color ?? config.accentColor;
        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: action.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              foregroundColor: action.labelColor ?? Colors.white,
              elevation: 0,
              shadowColor: btnColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 24),
                  const SizedBox(width: 8),
                ],
                Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      case GameResultButtonStyle.outline:
        return SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: action.onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      case GameResultButtonStyle.text:
        return TextButton(
          onPressed: action.onTap,
          child: Text(
            action.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        );

      case GameResultButtonStyle.depth3d:
        final btnColor = action.color ?? config.accentColor;
        final bottomColor = action.borderBottomColor ?? Colors.black;
        return Material(
          color: btnColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  bottom: BorderSide(color: bottomColor, width: 4),
                ),
                boxShadow: action.labelColor == null
                    ? [
                        BoxShadow(
                          color: btnColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: action.labelColor ?? Colors.white,
                    fontSize: action.labelColor != null ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
