import 'package:flutter/material.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _kRows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) => _KeyTile(
                  label: key,
                  state: key.length == 1
                      ? (letterStates[key.toLowerCase()] ?? TileState.empty)
                      : TileState.empty,
                  onTap: () {
                    if (key == 'ENTER') {
                      onEnter();
                    } else if (key == '⌫') {
                      onDelete();
                    } else {
                      onKey(key);
                    }
                  },
                )).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final TileState state;
  final VoidCallback onTap;

  bool get _isWide => label == 'ENTER' || label == '⌫';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _isWide ? 60 : 38,
        height: 54,
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
              fontSize: _isWide ? 12 : 15,
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
        return const Color(0xFF538D4E);
      case TileState.present:
        return const Color(0xFFB59F3B);
      case TileState.absent:
        return const Color(0xFF21262D);
      case TileState.empty:
        return const Color(0xFF3D444B);
    }
  }
}
