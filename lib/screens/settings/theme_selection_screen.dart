import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/design_system/design_system.dart';
import 'package:multigame/models/app_theme_preset.dart';
import 'package:multigame/models/avatar_preset.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/providers/theme_provider.dart';

/// Theme & Avatar selection screen.
///
/// Lets users pick from 5 colour themes and 12 avatars.
/// Changes apply immediately via [ThemeProvider].
class ThemeSelectionScreen extends ConsumerWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: DSColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: DSColors.surface,
        elevation: 0,
        title: Text(
          'Theme & Style',
          style: DSTypography.titleLarge.copyWith(color: DSColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: DSColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(DSSpacing.md),
        children: [
          // ── Colour Theme ─────────────────────────────────────────────────
          _SectionLabel(title: 'Colour Theme', icon: Icons.palette_rounded),
          DSSpacing.gapVerticalSM,
          _ThemeGrid(provider: provider),

          DSSpacing.gapVerticalXL,

          // ── Avatar ────────────────────────────────────────────────────────
          _SectionLabel(title: 'Avatar', icon: Icons.face_rounded),
          DSSpacing.gapVerticalSM,
          _AvatarGrid(provider: provider),

          DSSpacing.gapVerticalXL,
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});

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

// ── Theme Grid ─────────────────────────────────────────────────────────────────

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.provider});

  final ThemeProvider provider;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: AppThemePreset.allThemes.length,
      itemBuilder: (_, i) {
        final preset = AppThemePreset.allThemes[i];
        final isSelected = provider.currentTheme == preset.preset;
        return Semantics(
          label: '${preset.name} theme${isSelected ? ", selected" : ""}',
          hint: preset.description,
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => provider.setTheme(preset.preset),
            child: AnimatedContainer(
              duration: DSAnimations.normal,
              decoration: BoxDecoration(
                gradient: preset.gradient,
                borderRadius: DSSpacing.borderRadiusLG,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: preset.primary.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(DSSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          preset.name,
                          style: DSTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(
                                  color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: DSSpacing.xs,
                      right: DSSpacing.xs,
                      child: Container(
                        padding: EdgeInsets.all(DSSpacing.xxs),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 14, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Avatar Grid ────────────────────────────────────────────────────────────────

class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({required this.provider});

  final ThemeProvider provider;

  @override
  Widget build(BuildContext context) {
    final avatars = AvatarPreset.defaults;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: avatars.length,
      itemBuilder: (_, i) {
        final avatar = avatars[i];
        final isSelected = provider.currentAvatarId == avatar.id;
        return Semantics(
          label:
              '${avatar.name} avatar${isSelected ? ", selected" : ""}${avatar.isUnlocked ? "" : ", locked"}',
          button: avatar.isUnlocked,
          selected: isSelected,
          child: GestureDetector(
            onTap: avatar.isUnlocked
                ? () => provider.setAvatar(avatar.id)
                : null,
            child: AnimatedContainer(
              duration: DSAnimations.normal,
              decoration: BoxDecoration(
                color: avatar.isUnlocked
                    ? avatar.backgroundColor
                    : DSColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              avatar.backgroundColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: avatar.isUnlocked
                  ? Icon(avatar.icon,
                      color: avatar.iconColor, size: DSSpacing.iconLarge)
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(avatar.icon,
                            color: DSColors.textTertiary,
                            size: DSSpacing.iconLarge),
                        Icon(Icons.lock_rounded,
                            color: DSColors.textTertiary, size: 16),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
