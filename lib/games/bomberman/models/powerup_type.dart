enum PowerupType {
  extraBomb, // +1 max bomb capacity
  blastRange, // +1 explosion range
  speed, // movement speed boost
  shield, // absorbs one explosion hit
}

extension PowerupTypeJson on PowerupType {
  int toJson() => index;
  static PowerupType fromJson(int i) => PowerupType.values[i];
}
