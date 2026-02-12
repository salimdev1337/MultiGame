import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_accessibility.dart';

/// A game card wrapper that adds proper semantics for screen readers.
///
/// Builds a descriptive label from game metadata so that screen reader
/// users understand what the card represents and how to interact with it.
class AccessibleGameCard extends StatelessWidget {
  const AccessibleGameCard({
    super.key,
    required this.gameName,
    required this.child,
    this.playCount = 0,
    this.isLocked = false,
    this.onTap,
    this.onLongPress,
  });

  final String gameName;
  final Widget child;
  final int playCount;
  final bool isLocked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  String get _semanticLabel {
    if (isLocked) return '$gameName game, locked';
    return DSAccessibility.gameCardLabel(gameName, playCount);
  }

  String get _semanticHint {
    if (isLocked) return 'This game is not yet available';
    return 'Double tap to play';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      hint: _semanticHint,
      button: !isLocked,
      enabled: !isLocked,
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        onLongPress: isLocked ? null : onLongPress,
        child: child,
      ),
    );
  }
}
