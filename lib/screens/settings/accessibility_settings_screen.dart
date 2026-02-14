import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/providers/accessibility_provider.dart';
import 'package:multigame/providers/services_providers.dart';

/// Accessibility Settings Screen
///
/// Allows users to configure:
/// - Vision: High Contrast, Font Size, Screen Reader
/// - Motion: Reduce Motion
/// - Interaction: Haptic Feedback
class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(accessibilityProvider);

    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: DSColors.surface,
        elevation: 0,
        title: Text(
          'Accessibility',
          style: DSTypography.titleLarge.copyWith(color: DSColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: DSColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          TextButton(
            onPressed: () => _resetToDefaults(context, ref),
            child: Text(
              'Reset',
              style: DSTypography.labelMedium.copyWith(color: DSColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(DSSpacing.md),
        children: [
          // ── Vision ────────────────────────────────────────────────────
          _SectionHeader(title: 'Vision', icon: Icons.visibility_rounded),
          DSSpacing.gapVerticalSM,

          _SettingsTile(
            icon: Icons.contrast_rounded,
            title: 'High Contrast Mode',
            subtitle: 'Increases contrast for better visibility',
            value: provider.highContrastEnabled,
            onChanged: (v) => provider.setHighContrast(v),
          ),

          DSSpacing.gapVerticalSM,

          _FontScaleTile(
            scale: provider.fontScale,
            onChanged: (v) => provider.setFontScale(v),
          ),

          DSSpacing.gapVerticalSM,

          _SettingsTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Screen Reader Support',
            subtitle: 'Optimise layout for TalkBack / VoiceOver',
            value: provider.screenReaderEnabled,
            onChanged: (v) => provider.setScreenReaderEnabled(v),
          ),

          DSSpacing.gapVerticalXL,

          // ── Motion ────────────────────────────────────────────────────
          _SectionHeader(title: 'Motion', icon: Icons.animation_rounded),
          DSSpacing.gapVerticalSM,

          _SettingsTile(
            icon: Icons.slow_motion_video_rounded,
            title: 'Reduce Motion',
            subtitle: 'Shorten animations to 30 % of normal duration',
            value: provider.reducedMotionEnabled,
            onChanged: (v) => provider.setReducedMotion(v),
          ),

          DSSpacing.gapVerticalXL,

          // ── System ────────────────────────────────────────────────────
          _SectionHeader(title: 'System', icon: Icons.phone_android_rounded),
          DSSpacing.gapVerticalSM,

          _ActionTile(
            icon: Icons.sync_rounded,
            title: 'Sync with System Settings',
            subtitle: 'Import reduced motion and contrast from the OS',
            onTap: () => _syncWithSystem(context, ref),
          ),

          DSSpacing.gapVerticalXL,

          // ── Preview ───────────────────────────────────────────────────
          _PreviewSection(provider: provider),

          DSSpacing.gapVerticalXL,
        ],
      ),
    );
  }

  void _resetToDefaults(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.surface,
        title: Text(
          'Reset to Defaults',
          style: DSTypography.titleMedium.copyWith(color: DSColors.textPrimary),
        ),
        content: Text(
          'All accessibility settings will be restored to their defaults.',
          style: DSTypography.bodyMedium.copyWith(
            color: DSColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: DSColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(accessibilityProvider).resetToDefaults();
            },
            child: Text('Reset', style: TextStyle(color: DSColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _syncWithSystem(BuildContext context, WidgetRef ref) async {
    final provider = ref.read(accessibilityProvider);
    await provider.syncWithSystem(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System preferences imported')),
      );
    }
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 18, color: DSColors.primary),
          DSSpacing.gapHorizontalSM,
          Text(
            title,
            style: DSTypography.labelLarge.copyWith(
              color: DSColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title, ${value ? "enabled" : "disabled"}',
      hint: 'Double tap to toggle',
      toggled: value,
      child: Container(
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSSpacing.borderRadiusLG,
          border: Border.all(
            color: value
                ? DSColors.primary.withValues(alpha: 0.4)
                : DSColors.surfaceElevated,
          ),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          secondary: Container(
            padding: EdgeInsets.all(DSSpacing.xs),
            decoration: BoxDecoration(
              color: (value ? DSColors.primary : DSColors.textTertiary)
                  .withValues(alpha: 0.15),
              borderRadius: DSSpacing.borderRadiusSM,
            ),
            child: Icon(
              icon,
              size: 22,
              color: value ? DSColors.primary : DSColors.textTertiary,
            ),
          ),
          title: Text(
            title,
            style: DSTypography.bodyLarge.copyWith(
              color: DSColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: DSTypography.bodySmall.copyWith(
              color: DSColors.textSecondary,
            ),
          ),
          activeThumbColor: DSColors.primary,
          activeTrackColor: DSColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ── Font Scale Tile ───────────────────────────────────────────────────────────

class _FontScaleTile extends StatelessWidget {
  const _FontScaleTile({required this.scale, required this.onChanged});

  final double scale;
  final ValueChanged<double> onChanged;

  String get _label {
    if (scale <= 0.85) return 'Small';
    if (scale <= 1.05) return 'Normal';
    if (scale <= 1.35) return 'Large';
    if (scale <= 1.65) return 'Extra Large';
    return 'Huge';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Font size: $_label (${(scale * 100).round()}%)',
      child: Container(
        padding: EdgeInsets.all(DSSpacing.md),
        decoration: BoxDecoration(
          color: DSColors.surface,
          borderRadius: DSSpacing.borderRadiusLG,
          border: Border.all(color: DSColors.surfaceElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DSSpacing.xs),
                  decoration: BoxDecoration(
                    color: DSColors.info.withValues(alpha: 0.15),
                    borderRadius: DSSpacing.borderRadiusSM,
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    size: 22,
                    color: DSColors.info,
                  ),
                ),
                DSSpacing.gapHorizontalSM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Font Size',
                        style: DSTypography.bodyLarge.copyWith(
                          color: DSColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _label,
                        style: DSTypography.bodySmall.copyWith(
                          color: DSColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(scale * 100).round()}%',
                  style: DSTypography.labelMedium.copyWith(
                    color: DSColors.textSecondary,
                  ),
                ),
              ],
            ),
            DSSpacing.gapVerticalSM,
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DSColors.primary,
                inactiveTrackColor: DSColors.surfaceElevated,
                thumbColor: DSColors.primary,
                overlayColor: DSColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: scale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                semanticFormatterCallback: (v) =>
                    '${(v * 100).round()}% font size',
                onChanged: onChanged,
              ),
            ),
            // Preview text at current scale
            Center(
              child: Text(
                'Preview text',
                style: DSTypography.bodyMedium.copyWith(
                  color: DSColors.textSecondary,
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      child: Material(
        color: DSColors.surface,
        borderRadius: DSSpacing.borderRadiusLG,
        child: InkWell(
          onTap: onTap,
          borderRadius: DSSpacing.borderRadiusLG,
          child: Container(
            padding: EdgeInsets.all(DSSpacing.md),
            decoration: BoxDecoration(
              borderRadius: DSSpacing.borderRadiusLG,
              border: Border.all(color: DSColors.surfaceElevated),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DSSpacing.xs),
                  decoration: BoxDecoration(
                    color: DSColors.secondary.withValues(alpha: 0.15),
                    borderRadius: DSSpacing.borderRadiusSM,
                  ),
                  child: Icon(icon, size: 22, color: DSColors.secondary),
                ),
                DSSpacing.gapHorizontalSM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DSTypography.bodyLarge.copyWith(
                          color: DSColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: DSTypography.bodySmall.copyWith(
                          color: DSColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: DSColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Preview Section ───────────────────────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.provider});

  final AccessibilityProvider provider;

  @override
  Widget build(BuildContext context) {
    final bg = provider.highContrastEnabled
        ? DSColors.highContrastBackground
        : DSColors.surface;
    final textColor = provider.highContrastEnabled
        ? DSColors.highContrastText
        : DSColors.textPrimary;
    final accent = provider.highContrastEnabled
        ? DSColors.highContrastPrimary
        : DSColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Preview', icon: Icons.preview_rounded),
        DSSpacing.gapVerticalSM,
        Container(
          padding: EdgeInsets.all(DSSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: DSSpacing.borderRadiusLG,
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Score',
                style: DSTypography.labelMedium.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 12 * provider.fontScale,
                ),
              ),
              Text(
                '12,480',
                style: DSTypography.headlineMedium.copyWith(
                  color: accent,
                  fontSize: 28 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DSSpacing.gapVerticalXS,
              Text(
                'This preview shows how your settings\naffect text and colour.',
                style: DSTypography.bodySmall.copyWith(
                  color: textColor,
                  fontSize: 13 * provider.fontScale,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
