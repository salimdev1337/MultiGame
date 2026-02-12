/// Design System - Loading Overlay
/// Full-screen loading overlay with shimmer effect
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:shimmer/shimmer.dart';

/// Loading overlay widget
///
/// Shows a full-screen overlay with:
/// - Glassmorphic blur background
/// - Shimmer loading animation
/// - Optional message
/// - Prevents user interaction while loading
class DSLoadingOverlay extends StatelessWidget {
  final String? message;
  final bool show;
  final Widget child;

  const DSLoadingOverlay({
    super.key,
    required this.child,
    this.message,
    this.show = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay
        if (show)
          Positioned.fill(
            child: _LoadingOverlayContent(message: message),
          ),
      ],
    );
  }
}

class _LoadingOverlayContent extends StatelessWidget {
  final String? message;

  const _LoadingOverlayContent({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DSColors.backgroundPrimary.withValues(alpha: (0.8 * 255)),
      child: Center(
        child: Container(
          padding: DSSpacing.paddingXL,
          margin: DSSpacing.paddingXL,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DSColors.surface.withValues(alpha: (0.9 * 255)),
                DSColors.surface.withValues(alpha: (0.7 * 255)),
              ],
            ),
            borderRadius: DSSpacing.borderRadiusXL,
            boxShadow: DSShadows.shadowXl,
            border: Border.all(
              color: DSColors.textTertiary.withValues(alpha: (0.2 * 255)),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shimmer loading animation
              Shimmer.fromColors(
                baseColor: DSColors.primary.withValues(alpha: (0.3 * 255)),
                highlightColor: DSColors.primary,
                period: const Duration(milliseconds: 1500),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        DSColors.primary,
                        DSColors.primary.withValues(alpha: (0.3 * 255)),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              if (message != null) ...[
                DSSpacing.gapVerticalLG,
                Text(
                  message!,
                  style: DSTypography.titleMedium.copyWith(
                    color: DSColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading overlay controller
///
/// Use this to show/hide loading overlay programmatically:
///
/// ```dart
/// final loadingController = DSLoadingController();
///
/// // Show loading
/// loadingController.show(context, message: 'Loading...');
///
/// // Hide loading
/// loadingController.hide();
/// ```
class DSLoadingController {
  OverlayEntry? _overlayEntry;

  /// Show loading overlay
  void show(
    BuildContext context, {
    String? message,
  }) {
    // Remove existing overlay if any
    hide();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayContent(message: message),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Hide loading overlay
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Check if overlay is showing
  bool get isShowing => _overlayEntry != null;
}

/// Extension for easy loading overlay display
extension LoadingOverlayExtension on BuildContext {
  /// Show loading overlay
  void showLoading({String? message}) {
    final overlay = Overlay.of(this);
    final overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayContent(message: message),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 30 seconds (safety timeout)
    Future.delayed(const Duration(seconds: 30), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
