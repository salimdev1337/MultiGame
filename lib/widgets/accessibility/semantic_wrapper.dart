import 'package:flutter/material.dart';

/// Wraps any widget with proper semantics for screen readers.
///
/// Use this when you need to add accessibility context to a widget
/// that doesn't have it built in.
class SemanticWrapper extends StatelessWidget {
  const SemanticWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.isImage = false,
    this.isLiveRegion = false,
    this.excludeSemantics = false,
    this.onTap,
  });

  final Widget child;
  final String label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final bool isImage;

  /// When true, announces changes to screen readers automatically
  final bool isLiveRegion;

  /// When true, hides child widget semantics (use for decorative elements)
  final bool excludeSemantics;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      image: isImage,
      liveRegion: isLiveRegion,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }
}

/// Marks a widget as purely decorative — screen readers will skip it.
class DecorativeWidget extends StatelessWidget {
  const DecorativeWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(child: child);
  }
}

/// Screen-reader-only live region that announces messages without showing UI.
///
/// Use for toast-style announcements that screen readers should read aloud.
class ScreenReaderAnnouncement extends StatelessWidget {
  const ScreenReaderAnnouncement({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: const SizedBox.shrink(),
    );
  }
}
