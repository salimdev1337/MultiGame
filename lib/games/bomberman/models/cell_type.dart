enum CellType {
  empty,
  wall,       // permanent (indestructible)
  block,      // destructible
  powerup,    // has a powerup hidden (revealed after block destroyed)
}
