/// Represents a single cell in a Sudoku grid.
///
/// Each cell can either be empty (value = null) or contain a number (1-9).
/// Fixed cells are part of the initial puzzle and cannot be edited by the player.
/// Notes (pencil marks) help players track possible values for empty cells.
class SudokuCell {
  /// The current value of the cell (1-9), or null if empty
  int? value;

  /// Whether this cell is part of the initial puzzle (cannot be edited)
  final bool isFixed;

  /// Pencil marks/notes for this cell (numbers 1-9)
  /// Used by players to track possible values
  final Set<int> notes;

  /// Whether this cell has a validation error (conflict with row/column/box)
  /// Used for visual feedback to the player
  bool isError;

  SudokuCell({
    this.value,
    this.isFixed = false,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? {};

  /// Returns true if the cell is empty (no value)
  bool get isEmpty => value == null;

  /// Returns true if the cell has a value
  bool get hasValue => value != null;

  /// Returns true if the cell has any notes
  bool get hasNotes => notes.isNotEmpty;

  /// Returns true if the value is valid (null or 1-9)
  bool get isValidValue => value == null || (value! >= 1 && value! <= 9);

  /// Creates a copy of this cell with the specified properties changed
  SudokuCell copyWith({
    int? value,
    bool? isFixed,
    Set<int>? notes,
    bool? isError,
  }) {
    return SudokuCell(
      value: value ?? this.value,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? Set<int>.from(this.notes),
      isError: isError ?? this.isError,
    );
  }

  /// Clears the cell value (keeps notes and fixed status)
  SudokuCell clear() {
    return SudokuCell(
      isFixed: isFixed,
      notes: Set<int>.from(notes),
      isError: false,
    );
  }

  /// Converts the cell to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isFixed': isFixed,
      'notes': notes.toList(),
      'isError': isError,
    };
  }

  /// Creates a cell from JSON
  factory SudokuCell.fromJson(Map<String, dynamic> json) {
    return SudokuCell(
      value: json['value'] as int?,
      isFixed: json['isFixed'] as bool,
      notes: Set<int>.from(json['notes'] as List<dynamic>),
      isError: json['isError'] as bool,
    );
  }

  @override
  String toString() {
    return 'SudokuCell(value: $value, isFixed: $isFixed, notes: $notes, isError: $isError)';
  }
}
