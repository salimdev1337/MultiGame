/// Enum representing the type of action performed on a Sudoku cell
enum SudokuActionType {
  /// Set a value in a cell
  setValue,

  /// Clear a value from a cell
  clearValue,

  /// Add a note to a cell
  addNote,

  /// Remove a note from a cell
  removeNote,
}

/// Represents a single action performed by the player in a Sudoku game.
///
/// This class is used to track user actions for undo/redo functionality.
/// Each action stores the position affected, the type of action, and
/// the previous state to enable reverting changes.
class SudokuAction {
  /// The type of action performed
  final SudokuActionType type;

  /// Row index (0-8) of the affected cell
  final int row;

  /// Column index (0-8) of the affected cell
  final int col;

  /// The new value set (for setValue actions)
  final int? value;

  /// The previous value before the action (for undo)
  final int? previousValue;

  /// The previous notes before the action (for undo)
  final Set<int>? previousNotes;

  SudokuAction({
    required this.type,
    required this.row,
    required this.col,
    this.value,
    this.previousValue,
    this.previousNotes,
  });

  /// Creates a setValue action
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

  /// Creates a clearValue action
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

  /// Creates an addNote action
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

  /// Creates a removeNote action
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

  /// Converts the action to JSON for storage
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

  /// Creates an action from JSON
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
