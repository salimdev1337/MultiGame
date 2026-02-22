/// Game phases for the Ludo state machine.
enum LudoPhase {
  idle,
  rolling,
  selectingToken,
  selectingWildcard, // magic mode: player picks dice value 1-6
  won,
}

/// Gameplay modes.
enum LudoMode {
  soloVsBots,
  freeForAll3,
  freeForAll4,
  twoVsTwo,
}

/// Bot difficulty levels.
enum LudoDifficulty { easy, medium, hard }

/// The four player colours — also used to identify players/tokens.
enum LudoPlayerColor { red, blue, green, yellow }

/// Dice mode — classic (one die) or magic (two dice: normal + magic).
enum LudoDiceMode { classic, magic }

/// The five faces of the magic die.
enum MagicDiceFace { turbo, skip, ghost, bomb, wildcard }
