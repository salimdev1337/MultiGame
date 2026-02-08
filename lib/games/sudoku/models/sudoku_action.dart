// Sudoku action model for undo - see docs/SUDOKU_ARCHITECTURE.md

enum SudokuActionType {
  setValue,
  clearValue,
  addNote,
  removeNote,
}

class SudokuAction {
  final SudokuActionType type;
  final int row;
  final int col;
  final int? value;
  final int? previousValue;
  final Set<int>? previousNotes;

  SudokuAction({
    required this.type,
    required this.row,
    required this.col,
    this.value,
    this.previousValue,
    this.previousNotes,
  });

  factory SudokuAction.setValue({
    required int row,
    required int col,
    required int value,
    int? previousValue,
    Set<int>? previousNotes,
  }) {
    return SudokuAction(
      type: SudokuActionType.setValue,
      row: row,
      col: col,
      value: value,
      previousValue: previousValue,
      previousNotes: previousNotes,
    );
  }

  factory SudokuAction.clearValue({
    required int row,
    required int col,
    int? previousValue,
    Set<int>? previousNotes,
  }) {
    return SudokuAction(
      type: SudokuActionType.clearValue,
      row: row,
      col: col,
      previousValue: previousValue,
      previousNotes: previousNotes,
    );
  }

  factory SudokuAction.addNote({
    required int row,
    required int col,
    required int value,
    Set<int>? previousNotes,
  }) {
    return SudokuAction(
      type: SudokuActionType.addNote,
      row: row,
      col: col,
      value: value,
      previousNotes: previousNotes,
    );
  }

  factory SudokuAction.removeNote({
    required int row,
    required int col,
    required int value,
    Set<int>? previousNotes,
  }) {
    return SudokuAction(
      type: SudokuActionType.removeNote,
      row: row,
      col: col,
      value: value,
      previousNotes: previousNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'row': row,
      'col': col,
      'value': value,
      'previousValue': previousValue,
      'previousNotes': previousNotes?.toList(),
    };
  }

  factory SudokuAction.fromJson(Map<String, dynamic> json) {
    return SudokuAction(
      type: SudokuActionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SudokuActionType.setValue,
      ),
      row: json['row'] as int,
      col: json['col'] as int,
      value: json['value'] as int?,
      previousValue: json['previousValue'] as int?,
      previousNotes: json['previousNotes'] != null
          ? Set<int>.from(json['previousNotes'] as List<dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'SudokuAction(type: $type, row: $row, col: $col, value: $value, '
        'previousValue: $previousValue, previousNotes: $previousNotes)';
  }
}
