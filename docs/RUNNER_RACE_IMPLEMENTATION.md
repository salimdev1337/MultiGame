# Infinite Runner — Race Mode Implementation

> Branch: `feature/new-runner-game-mode`
> Commits: Phase 1 → Phase 4 (4 commits)
> Status: **Complete**

---

## Overview

Race Mode adds a **1v2–4 multiplayer race** to the Infinite Runner.
Friends on the same WiFi network compete to reach a fixed finish line (~10,000 scroll units, ~90 s at normal speed).

Key design decisions:
- **Network**: Local WiFi only — host phone runs a WebSocket server, guests connect by entering a 6-digit room code
- **Obstacle hit**: Speed penalty (−40 % for 2 s) instead of game-over
- **Abilities**: 4 collectible power-ups spawned on track
- **Track**: Fixed finish line at 10,000 scroll units; 3-minute hard cap (furthest player wins on timeout)
- **Players**: 2–4 per room

---

## Architecture

### Network topology

```
Host phone  ────── WebSocket server (shelf, port 4567)
                         │
          ┌──────────────┼──────────────┐
       Guest 1       Guest 2        Guest 3
      (WS client)   (WS client)    (WS client)
```

The **host** runs both a `RaceServer` and a `RaceClient`.
This means the host receives its own position broadcasts via the server's relay — no special-casing needed for host-only messages.

### Room code system

Host IP `192.168.1.42` → room code `001042`
(last two octets, zero-padded to 3 digits each)

Guest enters the 6-digit code → client reconstructs `192.168.1.42` using the guest's own network prefix.

> ⚠️ **Known limitation**: room code only encodes the last two octets. All players must share the same network prefix (same router subnet). Different subnets or mobile hotspots will fail. Sprint 1 improvement adds a manual IP fallback. See [UX Audit](#ux-audit--improvement-backlog).

---

## File Map

```
lib/games/infinite_runner/
├── multiplayer/
│   ├── race_message.dart         JSON message protocol (all types + serialisation)
│   ├── race_player_state.dart    Immutable per-player snapshot (copyWith, toMap, fromMap)
│   ├── race_room.dart            Client-side room model; room code helpers; leaderboard sort
│   ├── race_server.dart          shelf WebSocket server (host only); timeout timer
│   └── race_client.dart          WebSocket client (all players including host)
├── abilities/
│   ├── ability_type.dart         Enum: speedBoost, shield, slowField, obstacleRain
│   ├── ability_pickup.dart       Flame component (on-track collectible, glowing icon)
│   └── ability_effects.dart      applySpeedEffect / activateShield on Player
├── components/
│   └── ghost_player.dart         Flame PositionComponent — semi-transparent opponent sprite
├── screens/
│   └── race_lobby_screen.dart    Host/join lobby; room code display; player ready list
├── widgets/
│   └── race_hud.dart             Progress bar + speed status + ability slot button
└── ui/
    └── race_overlays.dart        CountdownOverlay, RaceFinishOverlay (solo + podium),
                                  HostLeftOverlay
```

**Modified files:**

| File | Change |
|------|--------|
| `components/player.dart` | `speedMultiplier`, `heldAbility`, `applySpeedEffect()`, `activateShield()` |
| `systems/spawn_system.dart` | Ability pickup spawning every ~1,500 scroll units |
| `systems/collision_system.dart` | Pickup collection detection |
| `infinite_runner_game.dart` | `gameMode`, race fields, ghosts, network wiring, timeout |
| `screens/infinite_runner_screen.dart` | `raceClient` + `raceRoom` params; overlay map |
| `ui/overlays.dart` | "SOLO RUN" rename; HOST RACE / JOIN RACE buttons |
| `pubspec.yaml` | Added `shelf`, `shelf_web_socket`, `web_socket_channel`, `network_info_plus` |

---

## Phase 1 — Solo Race Mechanics

**Goal:** Make the game work as a solo race (finish line, slowdown on hit, no multiplayer).

### Changes

**`components/player.dart`**
- Added `speedMultiplier` (default `1.0`)
- Added `applySpeedEffect(factor, duration)` — applies timed speed change; resets to `1.0` after duration
- Added `activateShield()` / `hasShield` — absorbs one obstacle hit
- `update(dt)` decrements speed effect timer and resets multiplier when expired

**`infinite_runner_game.dart`**
- `gameMode` constructor param (`GameMode.solo` or `GameMode.race`)
- `trackLength = 10000.0`, `_distanceTraveled` tracked every frame
- `_checkFinishLine()` — triggers finish overlay when distance ≥ track length
- `_handleCollision()` — in race mode calls `applySpeedEffect(0.6, 2.0)` instead of `die()`
- `startRace()` — entry point: reset state → `GameState.countdown` → show `countdown` overlay
- `beginRacing()` — called by `CountdownOverlay` after GO! → set `GameState.playing`, show `raceHud`

**`ui/race_overlays.dart`** (new file)
- `CountdownOverlay` — animated 3-2-1-GO! (scale animation, 1 s ticks, calls `beginRacing()`)
- `RaceFinishOverlay` — time card with "RACE AGAIN" / "MAIN MENU" buttons

**`widgets/race_hud.dart`** (new file)
- Progress bar (cyan → purple, turns red when slowed, amber when boosted)
- Speed status banner ("SLOWED" / "BOOSTED")
- Pause button + shield badge

---

## Phase 2 — Abilities

**Goal:** 4 collectible power-ups spawned on track; picked up by running over them; activated by tapping the HUD button.

### Ability types

| Ability | ID | Effect |
|---------|----|--------|
| ⚡ Speed Boost | `speedBoost` | Self: ×1.5 speed for 5 s |
| 🛡 Shield | `shield` | Absorb next obstacle hit |
| 🐢 Slow Field | `slowField` | All players ahead: ×0.7 speed for 4 s |
| 🧱 Obstacle Rain | `obstacleRain` | Force-spawn 3 obstacles ahead |

### Changes

**`abilities/ability_type.dart`**
- `AbilityType` enum with `emoji`, `colorValue`, `displayName` per type

**`abilities/ability_pickup.dart`**
- `AbilityPickup` extends `PositionComponent` (Flame)
- Glowing icon rendered via `Canvas`; pulsing scale animation
- `isCollected` flag; `isOffScreen` for pool cleanup

**`systems/spawn_system.dart`**
- `updatePickups(dt, speed)` — spawns 1 pickup every ~1,500 scroll units (random type)
- Returns newly spawned pickup or `null`

**`systems/collision_system.dart`**
- `checkPickups(player, pickups)` — AABB overlap; marks pickup collected; returns type

**`infinite_runner_game.dart`**
- `activateAbility()` — reads `_player.heldAbility`, applies effect, broadcasts in multiplayer
- `_spawnObstacleRain()` — force-spawns 3 obstacles from the pool
- Pickup list managed in `_updatePlaying()`

**`widgets/race_hud.dart`**
- `_AbilityButton` — circular button bottom-right; glows in ability's colour; tap to activate

---

## Phase 3 — Local WiFi Multiplayer

**Goal:** 2–4 players race on the same WiFi; positions sync every 100 ms; ghost opponents rendered.

### Message protocol

All messages: `{ "type": string, "playerId": int, "payload": object }`

| Type | Direction | Payload |
|------|-----------|---------|
| `join` | client → server | `{ displayName }` |
| `joined` | server → client | `{ assignedId, players[] }` |
| `ready` | client → server | `{ isReady }` |
| `start` | server → all | — |
| `pos` | client → server (relay to others) | `{ distance }` |
| `ability_used` | client → server (relay) | `{ abilityId }` |
| `finish` | client → server | `{ timeMs }` |
| `results` | server → all | `{ rankings[] }` |
| `disconnect` | server → all | — |
| `error` | server → client | `{ message }` |

### `race_server.dart`

- `start()` — binds to `InternetAddress.anyIPv4:4567`; registers host as player 0; returns local IP
- `_handleConnection(channel)` — assigns guest ID; relays `pos`, `ability_used`, `finish` to others
- `_handleFinish(id, timeMs)` — records finish; calls `_broadcastResults()` when all connected players finish
- `stop()` — cancels timeout timer; closes all connections

### `race_client.dart`

- Connects to `ws://hostIp:4567`
- Sends `join` on connect
- `startPositionBroadcast(getDistance)` — `Timer.periodic(100ms)` sends `pos`; also calls `raceServer?.broadcastHostPos()` directly to avoid echo
- `_handleMessage()` — updates `RaceRoom` model from all incoming message types; fires `onEvent`

### Ghost rendering

`GhostPlayer` (`components/ghost_player.dart`) is a Flame `PositionComponent`:
- Size 36 × 54, `Anchor.bottomCenter`
- `distanceDelta` updated each frame: `opponent.distance − localDistance`
- Screen X = `100 + distanceDelta × 0.8 px` (local player always at x=100)
- Renders semi-transparent humanoid (rect body + circle head) in player's colour + initial letter above

### SlowField in multiplayer

In solo mode: `slowField` applies to self (demo behaviour).
In multiplayer: `activateAbility()` only broadcasts `ability_used`. Each opponent's client receives the event, checks if they are **ahead** of the activator (`_distanceTraveled > opponent.distance`), and self-applies the slow only if true.

### Finish flow

```
Local player crosses 10,000 ──► sendFinish(timeMs) ──► RaceServer
                                                              │
                                                    All players finished?
                                                              │ yes
                                                    broadcastResults(rankings)
                                                              │
                                                   All clients ──► raceFinish overlay
```

---

## Phase 4 — Polish & Edge Cases

**Goal:** Race timeout, full results podium, host-disconnection handling.

### Race timeout (3 minutes)

**Server-side (`race_server.dart`):**
- `broadcastStart()` starts a `Timer(3 minutes, _handleTimeout)`
- `_handleTimeout()`: players who haven't finished get a synthetic time of `180,000 ms + (10,000 − distance) × 10` so the furthest unfinished player ranks first
- `_resultsPublished` flag prevents double-broadcast if everyone finishes before the timer fires
- `_broadcastResults()` cancels the timer on natural finish

**Client-side (`infinite_runner_game.dart`):**
- `_raceElapsedMs` tracked in `_updatePlaying()`
- Solo race only (server handles multiplayer): when `_raceElapsedMs ≥ 180,000`, sets `finishTimeSeconds = 180` and shows `raceFinish`
- `startRace()` resets `_raceElapsedMs = 0`

### Results podium

`RaceFinishOverlay` dispatches based on context:

| Condition | Widget |
|-----------|--------|
| `raceRoom == null` or single player | `_SoloFinish` — time card (unchanged from Phase 1) |
| Multiplayer | `_MultiplayerFinish` — full podium |

**`_MultiplayerFinish`:**
- Header: "🏆 WINNER!" (gold) if you placed 1st, "RACE OVER" otherwise
- Each row: medal emoji (🥇🥈🥉4️⃣), coloured avatar, display name + "(you)" tag, finish time or "DNF" badge
- Sorted by: finished players ascending by `finishTimeMs`, then unfinished descending by `distance` (via `game.raceLeaderboard` getter)
- "RACE AGAIN" restarts the race; "MAIN MENU" navigates home

### Host disconnection

`RaceClient.onHostLeft` fires when the WebSocket closes while `room.phase == racing`.

`InfiniteRunnerGame._handleHostLeft()`:
1. Stops position broadcast
2. Sets state to `finished`
3. Shows `raceHostLeft` overlay

`HostLeftOverlay`: wifi_off icon, "Host Disconnected" message, "BACK TO HOME" button.

### Guest disconnection

When a guest's socket closes, `RaceServer._handleDisconnect(id)`:
- Marks player as `isConnected = false` in server state
- Broadcasts `disconnect` message to all others
- Race continues normally for remaining players
- The disconnected player's ghost fades out (ghost component stays at last known position)

---

## Overlay Map

| Key | Class | Shown when |
|-----|-------|-----------|
| `loading` | `LoadingOverlay` | Flame assets loading |
| `idle` | `IdleOverlay` | Before game starts (shows SOLO RUN / HOST RACE / JOIN RACE) |
| `hud` | `GameHud` | Solo mode playing |
| `paused` | `PausedOverlay` | Game paused |
| `gameOver` | `GameOverOverlay` | Solo mode death |
| `countdown` | `CountdownOverlay` | 3-2-1-GO! before race |
| `raceHud` | `RaceHud` | Race mode playing |
| `raceFinish` | `RaceFinishOverlay` | Player finished or timeout |
| `raceHostLeft` | `HostLeftOverlay` | Host disconnected mid-race |

---

## Verification Checklist

### Solo race
- [ ] Player runs to 10,000 units → `raceFinish` shown with correct time
- [ ] Hit 3 obstacles → each causes 2 s slowdown visible on progress bar
- [ ] All 4 ability types collected, activated, effects visible
- [ ] 3-minute timeout → `raceFinish` shown with `03:00`

### 2-player local WiFi
- [ ] Host creates room, room code displayed
- [ ] Guest enters code, both appear in player list
- [ ] Both ready up, host taps START RACE → countdown on both devices
- [ ] Ghost of opponent visible and moves relative to local player
- [ ] Obstacle Rain spawns on both devices
- [ ] SlowField only affects player who is ahead of activator
- [ ] First player to finish → both devices show podium
- [ ] Correct finish order in podium

### Disconnection
- [ ] Guest drops WiFi mid-race → race continues for others; ghost stays at last position
- [ ] Host drops WiFi mid-race → guests see `HostLeftOverlay`
- [ ] 3-minute timeout in 2-player → furthest player ranked 1st, unfinished shows DNF

---

## Dependencies Added

```yaml
# pubspec.yaml
shelf: ^1.4.0              # HTTP/WebSocket server framework
shelf_web_socket: ^2.0.0   # WebSocket handler for shelf
web_socket_channel: ^3.0.0 # Client-side WebSocket
network_info_plus: ^6.0.0  # Get device's local WiFi IP
```

---

## UX Audit & Improvement Backlog

Full audit conducted post-implementation. Issues ranked by user impact.

### 🔴 Critical (kills retention week 1)

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 1 | FPS counter visible to users in production | `ui/overlays.dart` `GameHud` | Remove or gate behind debug flag |
| 2 | Race HUD has no elapsed timer or countdown | `widgets/race_hud.dart` | Add MM:SS elapsed + remaining time display |
| 3 | Progress bar shows only local player | `widgets/race_hud.dart` | Add opponent position dots (colored per player) |
| 4 | Pause menu has no "Quit to Menu" option | `ui/overlays.dart` `PausedOverlay` | Add quit button to pause overlay |
| 5 | HUD uses polling `Future.delayed` loop | `ui/overlays.dart`, `widgets/race_hud.dart` | Replace with game event stream/callbacks |
| 6 | Idle instructions use `'^'` and `'!'` as icons | `ui/overlays.dart` `IdleOverlay` | Replace with animated gesture indicator widgets |
| 7 | Slide mechanic not mentioned in instructions | `ui/overlays.dart` `IdleOverlay` | Add swipe-down instruction |

### 🟠 Serious (plateaus engagement week 2–4)

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 8 | Room code fails across different subnets | `screens/race_lobby_screen.dart` | Add manual IP entry fallback field |
| 9 | Display name resets to "Player" every session | `screens/race_lobby_screen.dart` | Persist name via `SharedPreferences` |
| 10 | Host name defaults to "Player" (server starts before name is typed) | `screens/race_lobby_screen.dart` | Require name before `_initHost()` or update server after name change |
| 11 | "RACE AGAIN" in multiplayer only resets local game | `ui/race_overlays.dart` | Add coordinated rematch request/accept flow via WebSocket |
| 12 | High score is in-memory only (lost on app close) | `infinite_runner_game.dart` | Persist via `SecureStorageRepository` |
| 13 | No feedback when ability is collected | `infinite_runner_game.dart` | Show brief toast: "⚡ Speed Boost collected!" |
| 14 | SlowField hit shows no attacker attribution | `infinite_runner_game.dart` | Show "Slowed by [Name]! 🐢" banner |

### 🟡 Polish (improves depth and feel)

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| 15 | No haptic feedback on jump, hit, collect, finish | All game events | Wire `HapticFeedbackService` into key moments |
| 16 | Ability button gives no hint when empty | `widgets/race_hud.dart` | Add "collect orbs" hint text below empty slot |
| 17 | Game over shows no run stats beyond score | `ui/overlays.dart` `GameOverOverlay` | Add run time, obstacles dodged |
| 18 | Lobby shows no "waiting for host" state for guests | `screens/race_lobby_screen.dart` | Add status text when connected but not started |
| 19 | Ghost sprites blend into background | `components/ghost_player.dart` | Increase contrast; add player colour outline |
| 20 | `_raceStartMs` declared but never used | `infinite_runner_game.dart` | Remove dead field |

### Sprint Plan

**Sprint 1 — Stop the Bleeding (1–2 days)**
1. Remove FPS counter from `GameHud`
2. Add elapsed + remaining timer to `RaceHud`
3. Add opponent dots to progress bar
4. Add "Quit to Menu" to pause overlay
5. Persist display name
6. Add manual IP fallback to lobby

**Sprint 2 — Make It Feel Like a Game (2–3 days)**
7. Replace polling HUDs with event-driven updates
8. Replace `'^'`/`'!'` with animated gesture indicators
9. Add slide instruction to idle screen
10. Toast on ability pickup
11. "Slowed by [Name]!" attribution banner
12. Haptic feedback: jump, collect, hit, finish

**Sprint 3 — Keep Players Coming Back (3–4 days)**
13. Persist high score
14. Run stats on game over screen
15. Coordinated rematch flow (multiplayer)
16. Ghost visual contrast improvements
17. Remove `_raceStartMs` dead code
