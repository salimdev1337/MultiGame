// Match status enum - see docs/SUDOKU_ARCHITECTURE.md

enum MatchStatus { waiting, playing, completed, cancelled }

extension MatchStatusExtension on MatchStatus {
  String toJson() => name;

  static MatchStatus fromJson(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchStatus.cancelled,
    );
  }
}
