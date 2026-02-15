enum CellType {
  empty,
  wall, // permanent (indestructible)
  block, // destructible
  powerup, // has a powerup hidden (revealed after block destroyed)
}

extension CellTypeJson on CellType {
  int toJson() => index;
  static CellType fromJson(int i) => CellType.values[i];
}
