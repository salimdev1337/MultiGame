/// State of a single tile on the Wordle board.
enum TileState {
  /// Not yet submitted — empty or currently typed.
  empty,

  /// Letter is not in the word at all.
  absent,

  /// Letter is in the word but in the wrong position.
  present,

  /// Letter is in the correct position.
  correct,
}

/// Phases of the Wordle match state machine.
enum WordlePhase {
  idle,
  countdown,
  roundActive,
  roundEnd,
  matchEnd,
  error,
}

/// Role of this device in a multiplayer match.
enum WordleRole {
  solo,
  host,
  guest,
}
