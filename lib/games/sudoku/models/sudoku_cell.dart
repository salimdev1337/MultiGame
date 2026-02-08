// Sudoku cell model - see docs/SUDOKU_ARCHITECTURE.md

class SudokuCell {
  int? value;

  final bool isFixed;

  final Set<int> notes;

  bool isError;

  SudokuCell({
    this.value,
    this.isFixed = false,
    Set<int>? notes,
    this.isError = false,
  }) : notes = notes ?? {};

  bool get isEmpty => value == null;

  bool get hasValue => value != null;

  bool get hasNotes => notes.isNotEmpty;

  bool get isValidValue => value == null || (value! >= 1 && value! <= 9);

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

  SudokuCell clear() {
    return SudokuCell(
      isFixed: isFixed,
      notes: Set<int>.from(notes),
      isError: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isFixed': isFixed,
      'notes': notes.toList(),
      'isError': isError,
    };
  }

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
