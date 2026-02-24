enum RpgGamePhase { idle, playing, victory, gameOver }

enum BossId { warden, shaman, hollowKing, shadowlord }

enum BossAiState {
  idle,
  pursue,
  orbit,
  windupAttack,
  attacking,
  dashWindup,
  dashing,
  cooldown,
  enrage,
  phaseTransition,
  dead,
}

enum AttackType {
  // Player attacks
  meleeSlash1,
  meleeSlash2,
  heavySlash,
  ultimateAoe,
  // Boss attacks — Warden
  chargeAttack,
  overheadSlam,
  // Boss attacks — Shaman
  poisonPool,
  poisonProjectile,
  // Boss attacks — Hollow King
  dashSlash,
  bladeTrail,
  // Boss attacks — Shadowlord
  voidBlast,
  shadowSurge,
}

enum PlayerFacing { up, down, left, right }

enum PlayerAnimState { idle, walk, attack, dodge, hurt, ultimate, die }

enum BossAnimState { idle, attack, hurt, enrage, phaseChange, die }
