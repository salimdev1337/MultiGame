enum RpgGamePhase { idle, bossSelect, playing, paused, victory, gameOver }

enum AbilityType { basicAttack, fireball, timeSlow }

enum BossId { golem, wraith }

enum BossAiState {
  idle,
  move,
  stomp,
  rockThrow,
  spin,
  enrage,
  cooldown,
  float,
  shadowBolt,
  dash,
  shadowClone,
  teleport,
  desperation,
  dead,
}

enum AttackType { meleeSlash, rockProjectile, groundStomp, shadowBolt, dashAttack, fireOrb, aoe }

enum PlayerAnimState { idle, walk, attack, hurt, die }

enum BossAnimState { idle, attack, hurt, die, enrage }
