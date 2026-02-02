import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sudoku_settings_provider.dart';

// Color constants matching the Sudoku theme
const _backgroundDark = Color(0xFF0f1115);
const _surfaceDark = Color(0xFF1a1d24);
const _surfaceLighter = Color(0xFF2a2e36);
const _primaryCyan = Color(0xFF00d4ff);
const _textWhite = Color(0xFFffffff);
const _textGray = Color(0xFF94a3b8);

/// Settings screen for Sudoku game preferences.
///
/// Allows users to configure:
/// - Sound effects (on/off)
/// - Haptic feedback (on/off)
/// - Error highlighting (on/off)
///
/// All settings are persisted using SharedPreferences.
class SudokuSettingsScreen extends StatelessWidget {
  const SudokuSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundDark,
      appBar: AppBar(
        backgroundColor: _surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<SudokuSettingsProvider>(
        builder: (context, settings, child) {
          if (!settings.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryCyan),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Audio & Haptics'),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: Icons.volume_up,
                title: 'Sound Effects',
                subtitle: 'Play sounds for game actions',
                value: settings.soundEnabled,
                onChanged: (value) => settings.toggleSound(),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                icon: Icons.vibration,
                title: 'Haptic Feedback',
                subtitle: 'Vibration for touch interactions',
                value: settings.hapticsEnabled,
                onChanged: (value) => settings.toggleHaptics(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Gameplay'),
              const SizedBox(height: 8),
              _buildSettingCard(
                icon: Icons.error_outline,
                title: 'Error Highlighting',
                subtitle: 'Highlight conflicting numbers in red',
                value: settings.errorHighlightingEnabled,
                onChanged: (value) => settings.toggleErrorHighlighting(),
              ),
              const SizedBox(height: 32),
              _buildResetButton(context, settings),
            ],
          );
        },
      ),
    );
  }

  /// Builds a section header with styling
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _textGray,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Builds a setting card with toggle switch
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryCyan.withValues(alpha: 0.1 * 255),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryCyan.withValues(alpha: 0.1 * 255),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: _primaryCyan,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: _textGray,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _primaryCyan,
          activeTrackColor: _primaryCyan.withValues(alpha: 0.3 * 255),
          inactiveThumbColor: _textGray,
          inactiveTrackColor: _surfaceDark,
        ),
      ),
    );
  }

  /// Builds the reset to defaults button
  Widget _buildResetButton(
    BuildContext context,
    SudokuSettingsProvider settings,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryCyan.withValues(alpha: 0.2 * 255),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showResetConfirmation(context, settings),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restore,
                  color: _primaryCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Reset to Defaults',
                  style: TextStyle(
                    color: _primaryCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows confirmation dialog for resetting settings
  void _showResetConfirmation(
    BuildContext context,
    SudokuSettingsProvider settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _primaryCyan.withValues(alpha: 0.2 * 255),
            width: 1,
          ),
        ),
        title: const Text(
          'Reset Settings',
          style: TextStyle(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
          style: TextStyle(
            color: _textGray,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Settings reset to defaults'),
                  backgroundColor: _primaryCyan,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryCyan,
              foregroundColor: _backgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
