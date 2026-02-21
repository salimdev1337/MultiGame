/// Game phases for the Ludo state machine.
enum LudoPhase {
  idle,
  rolling,
  selectingToken,
  selectingPowerupTarget,
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

/// Powerup types that can be collected during play.
enum LudoPowerupType {
  shield,
  doubleStep,
  freeze,
  recall,
  luckyRoll,
}

/// Dice mode — classic (one die) or magic (two dice: normal + magic).
enum LudoDiceMode { classic, magic }

/// The six faces of the magic die.
enum MagicDiceFace { turbo, skip, swap, shield, blast, wildcard }
