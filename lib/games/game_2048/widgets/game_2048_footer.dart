import 'package:flutter/material.dart';

class Game2048Footer extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onMainMenu;

  const Game2048Footer({
    super.key,
    required this.onReset,
    required this.onMainMenu,
  });

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF19e6a2) : const Color(0xFF16181d),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: isPrimary ? const Color(0xFF0a8a61) : Colors.black,
                width: 4,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? const Color(0xFF101318) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF21242b).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildButton(
                label: 'RESET',
                onPressed: onReset,
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildButton(
                label: 'MAIN MENU',
                onPressed: onMainMenu,
                isPrimary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
