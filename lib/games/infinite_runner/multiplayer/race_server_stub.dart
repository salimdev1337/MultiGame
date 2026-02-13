// Web platform stub — browsers cannot host a WebSocket server.
// This file has the same public API as race_server_io.dart so the lobby and
// game code compiles on web; all methods are no-ops that return null/empty.

import 'race_player_state.dart';

/// Port constant kept here so import sites don't need platform guards.
const int kRaceServerPort = 4567;

/// No-op server for the web platform.
/// Instantiated when the user somehow requests host mode on web, but never
/// actually starts — [start] always returns null and the lobby shows an error.
class RaceServer {
  RaceServer({required this.hostDisplayName});

  final String hostDisplayName;

  void Function(RaceServerEvent event)? onEvent;

  List<RacePlayerState> get players => const [];

  Future<String?> start() async => null; // Always fails on web

  Future<void> stop() async {}

  void setHostReady(bool isReady) {}

  void broadcastStart() {}

  void broadcastHostPos(double distance) {}

  void broadcastHostAbility(String abilityId) {}

  void recordHostFinish(int timeMs) {}
}

// ── Server events (mirrored from race_server_io.dart) ──────────────────────

enum RaceServerEventType {
  playerJoined,
  allReady,
  raceStarted,
  playerDisconnected,
  resultsReady,
}

class RaceServerEvent {
  const RaceServerEvent(
    this.type, {
    this.players,
    this.disconnectedId,
    this.rankings,
  });

  final RaceServerEventType type;
  final List<RacePlayerState>? players;
  final int? disconnectedId;
  final List<Map<String, dynamic>>? rankings;
}
