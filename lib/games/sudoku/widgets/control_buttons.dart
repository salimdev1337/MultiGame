// Control buttons widget - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/material.dart';

const _primaryCyan = Color(0xFF00d4ff);
const _surfaceDark = Color(0xFF2a2e36);
const _textWhite = Color(0xFFffffff);
const _textGray = Color(0xFF64748b);

class ControlButtons extends StatelessWidget {
  final bool notesMode;

  final bool canUndo;

  final bool canErase;

  final int hintsRemaining;

  final VoidCallback onUndo;

  final VoidCallback onErase;

  final VoidCallback onToggleNotes;

  final VoidCallback onHint;

  const ControlButtons({
    super.key,
    required this.notesMode,
    required this.canUndo,
    required this.canErase,
    required this.hintsRemaining,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.undo,
            label: 'Undo',
            isEnabled: canUndo,
            onTap: canUndo ? onUndo : null,
          ),
          _ControlButton(
            icon: Icons.backspace_outlined,
            label: 'Erase',
            isEnabled: canErase,
            onTap: canErase ? onErase : null,
          ),
          _ControlButton(
            icon: Icons.edit_outlined,
            label: 'Notes',
            isEnabled: true,
            isActive: notesMode,
            onTap: onToggleNotes,
          ),
          _ControlButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            isEnabled: hintsRemaining > 0,
            badge: hintsRemaining > 0 ? hintsRemaining.toString() : null,
            onTap: hintsRemaining > 0 ? onHint : null,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isActive;
  final String? badge;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isEnabled = true,
    this.isActive = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isActive
        ? _primaryCyan
        : isEnabled
        ? _surfaceDark
        : _surfaceDark.withValues(alpha: 0.5 * 255);

    final iconColor = isActive
        ? _surfaceDark
        : isEnabled
        ? _textWhite
        : _textGray.withValues(alpha: 0.3 * 255);

    final labelColor = isEnabled
        ? _textGray
        : _textGray.withValues(alpha: 0.5 * 255);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05 * 255),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: iconColor, size: 24)),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _primaryCyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: _surfaceDark, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _surfaceDark,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
