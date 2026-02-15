enum GamePhase { lobby, countdown, playing, roundOver, gameOver }

extension GamePhaseJson on GamePhase {
  int toJson() => index;
  static GamePhase fromJson(int i) => GamePhase.values[i];
}
