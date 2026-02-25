import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_colors.dart';

import '../models/wordle_enums.dart';

const _kRows = [
  ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
  ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
];

class WordleKeyboard extends StatelessWidget {
  const WordleKeyboard({
    super.key,
    required this.letterStates,
    required this.onKey,
    required this.onEnter,
    required this.onDelete,
  });

  /// Best TileState seen per letter (from computeKeyboardState).
  final Map<String, TileState> letterStates;

  final void Function(String letter) onKey;
  final VoidCallback onEnter;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Row 1 has 10 keys, each with 6px total horizontal margin.
        // Derive keyW so row 1 fits exactly in the available width.
        final keyW = ((constraints.maxWidth - 10 * 6) / 10).clamp(26.0, 38.0);
        final keyH = (keyW * 1.42).clamp(38.0, 54.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: _kRows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row
                    .map(
                      (key) => _KeyTile(
                        label: key,
                        state: key.length == 1
                            ? (letterStates[key.toLowerCase()] ??
                                TileState.empty)
                            : TileState.empty,
                        keyWidth: (key == 'ENTER' || key == '⌫')
                            ? keyW * 1.5
                            : keyW,
                        keyHeight: keyH,
                        onTap: () {
                          if (key == 'ENTER') {
                            onEnter();
                          } else if (key == '⌫') {
                            onDelete();
                          } else {
                            onKey(key);
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({
    required this.label,
    required this.state,
    required this.onTap,
    required this.keyWidth,
    required this.keyHeight,
  });

  final String label;
  final TileState state;
  final VoidCallback onTap;
  final double keyWidth;
  final double keyHeight;

  bool get _isWide => label == 'ENTER' || label == '⌫';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: keyWidth,
        height: keyHeight,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: _isWide
                  ? (keyHeight * 0.24).clamp(10.0, 13.0)
                  : (keyHeight * 0.30).clamp(12.0, 16.0),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color get _bgColor {
    switch (state) {
      case TileState.correct:
        return DSColors.wordlePrimary;
      case TileState.present:
        return DSColors.wordleAccent;
      case TileState.absent:
        return const Color(0xFF3A3A3C);
      case TileState.empty:
        return DSColors.surface;
    }
  }
}
