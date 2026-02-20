import 'dart:convert';
import 'dart:typed_data';

import 'package:multigame/games/bomberman/models/bomb.dart';
import 'package:multigame/games/bomberman/models/bomb_game_state.dart';
import 'package:multigame/games/bomberman/models/bomb_player.dart';
import 'package:multigame/games/bomberman/models/explosion_tile.dart';
import 'package:multigame/games/bomberman/models/game_phase.dart';
import 'package:multigame/games/bomberman/models/powerup_cell.dart';
import 'package:multigame/games/bomberman/models/powerup_type.dart';

/// Binary codec for Bomberman `frameSync` messages.
///
/// Wire format v1 — big-endian (network byte order).
/// Only `frameSync` uses binary; all other messages remain JSON strings.
///
/// ## Layout (typical frame ~190 bytes, 4 players / 2 bombs / 5 explosions)
///
/// HEADER
///   [0]     u8   version = 0x01
///   [1..4]  u32  frameId (big-endian)
///   [5]     u8   GamePhase.index
///   [6]     u8   countdown (0-3)
///   [7]     u8   roundTimeSeconds (max 255, clamped from 180)
///   [8]     u8   round (1-based)
///   [9]     u8   roundWinCount
///   [10..n] u8   roundWins × roundWinCount
///   [n+1]   u8   flags  bit0=hasWinnerId  bit1=hasRoundOverMessage
///   [?]     u8   winnerId  (only if bit0)
///   [?]     u8   msgLen    (only if bit1, max 255 bytes)
///   [?]     u8×n msgBytes  (utf-8, only if bit1)
///
/// PLAYERS
///   u8  playerCount
///   per player:
///     u8   id
///     u16  xFixed     = (x * 256).round()   — covers 0–65535 (grid max ~3840)
///     u16  yFixed
///     u16  targetXFixed
///     u16  targetYFixed
///     u8   lives
///     u8   maxBombs
///     u8   activeBombs
///     u8   range
///     u8   speedFixed = (speed * 16).round()  — covers 0–15.9 cells/sec
///     u8   boolFlags  bit0=isAlive bit1=isGhost bit2=hasShield bit3=isBot
///     u8   nameLen
///     u8×n nameBytes  (utf-8)
///     u8   powerupCount
///     u8×n powerupType  (PowerupType.index each)
///
/// BOMBS  (9 bytes × count)
///   u8  bombCount
///   per bomb:
///     u8   id (wraps at 256)
///     u8   x, y, ownerId, range
///     u16  fuseMs
///     u16  totalFuseMs
///
/// EXPLOSIONS  (6 bytes × count)
///   u8  explosionCount
///   per explosion:
///     u8   x, y
///     u16  remainingMs
///     u16  totalMs
///
/// POWERUP CELLS  (3 bytes × count)
///   u8  powerupCellCount
///   per cell:
///     u8  x, y, type
class BombFrameCodec {
  static const int version = 0x01;

  /// Encode [state] into a compact binary frame.
  static Uint8List encode(BombGameState state, int frameId) {
    final w = _Writer();

    // ── Header ──────────────────────────────────────────────────────────────
    w.u8(version);
    w.u32be(frameId);
    w.u8(state.phase.index);
    w.u8(state.countdown);
    w.u8(state.roundTimeSeconds.clamp(0, 255));
    w.u8(state.round);

    // Round wins
    w.u8(state.roundWins.length);
    for (final wins in state.roundWins) {
      w.u8(wins);
    }

    // Flags
    final hasWinnerId = state.winnerId != null;
    final hasMsg = state.roundOverMessage != null;
    w.u8((hasWinnerId ? 0x01 : 0) | (hasMsg ? 0x02 : 0));
    if (hasWinnerId) {
      w.u8(state.winnerId!);
    }
    if (hasMsg) {
      // Truncate at character boundaries
      final truncated = <int>[];
      var byteCount = 0;
      for (final rune in state.roundOverMessage!.runes) {
        final char = String.fromCharCode(rune);
        final charBytes = utf8.encode(char);
        if (byteCount + charBytes.length > 255) break;
        truncated.addAll(charBytes);
        byteCount += charBytes.length;
      }
      w.u8(truncated.length);
      w.bytes(truncated);
    }

    // ── Players ─────────────────────────────────────────────────────────────
    w.u8(state.players.length);
    for (final p in state.players) {
      w.u8(p.id);
      w.u16((p.x * 256).round().clamp(0, 65535));
      w.u16((p.y * 256).round().clamp(0, 65535));
      w.u16((p.targetX * 256).round().clamp(0, 65535));
      w.u16((p.targetY * 256).round().clamp(0, 65535));
      w.u8(p.lives);
      w.u8(p.maxBombs);
      w.u8(p.activeBombs);
      w.u8(p.range);
      w.u8((p.speed * 16).round().clamp(0, 255));
      w.u8(
        (p.isAlive ? 0x01 : 0) |
            (p.isGhost ? 0x02 : 0) |
            (p.hasShield ? 0x04 : 0) |
            (p.isBot ? 0x08 : 0),
      );
      // Truncate at character boundaries
      final nameTruncated = <int>[];
      var byteCount = 0;
      for (final rune in p.displayName.runes) {
        final char = String.fromCharCode(rune);
        final charBytes = utf8.encode(char);
        if (byteCount + charBytes.length > 255) break;
        nameTruncated.addAll(charBytes);
        byteCount += charBytes.length;
      }
      w.u8(nameTruncated.length);
      w.bytes(nameTruncated);
      w.u8(p.powerups.length.clamp(0, 255));
      for (final pu in p.powerups.take(255)) {
        w.u8(pu.index);
      }
    }

    // ── Bombs ───────────────────────────────────────────────────────────────
    w.u8(state.bombs.length.clamp(0, 255));
    for (final b in state.bombs.take(255)) {
      w.u8(b.id & 0xFF);
      w.u8(b.x);
      w.u8(b.y);
      w.u8(b.ownerId);
      w.u8(b.range);
      w.u16(b.fuseMs.clamp(0, 65535));
      w.u16(b.totalFuseMs.clamp(0, 65535));
    }

    // ── Explosions ──────────────────────────────────────────────────────────
    w.u8(state.explosions.length.clamp(0, 255));
    for (final e in state.explosions.take(255)) {
      w.u8(e.x);
      w.u8(e.y);
      w.u16(e.remainingMs.clamp(0, 65535));
      w.u16(e.totalMs.clamp(0, 65535));
    }

    // ── Powerup cells ───────────────────────────────────────────────────────
    w.u8(state.powerups.length.clamp(0, 255));
    for (final pu in state.powerups.take(255)) {
      w.u8(pu.x);
      w.u8(pu.y);
      w.u8(pu.type.index);
    }

    return w.toBytes();
  }

  /// Read only the frameId from [bytes] — O(1), no full decode.
  static int readFrameId(Uint8List bytes) =>
      ByteData.sublistView(bytes, 1, 5).getUint32(0, Endian.big);

  /// Decode [bytes] and apply onto [current], preserving the grid.
  ///
  /// Mirrors [BombGameState.applyFrameSync] but operates on binary data.
  static BombGameState applyTo(Uint8List bytes, BombGameState current) {
    final r = _Reader(bytes);

    // ── Header ──────────────────────────────────────────────────────────────
    r.skip(1); // version
    r.skip(4); // frameId (already consumed by readFrameId if needed)
    final phaseIdx = r.u8();
    final phase = (phaseIdx >= 0 && phaseIdx < GamePhase.values.length)
        ? GamePhase.values[phaseIdx]
        : GamePhase.lobby;
    final countdown = r.u8();
    final roundTimeSeconds = r.u8();
    final round = r.u8();

    final roundWinCount = r.u8();
    final roundWins = List.generate(roundWinCount, (_) => r.u8());

    final flags = r.u8();
    final hasWinnerId = (flags & 0x01) != 0;
    final hasMsg = (flags & 0x02) != 0;

    int? winnerId;
    String? roundOverMessage;
    if (hasWinnerId) {
      winnerId = r.u8();
    }
    if (hasMsg) {
      final msgLen = r.u8();
      roundOverMessage = utf8.decode(r.read(msgLen));
    }

    // ── Players ─────────────────────────────────────────────────────────────
    final playerCount = r.u8();
    final players = List.generate(playerCount, (_) {
      final id = r.u8();
      final x = r.u16() / 256.0;
      final y = r.u16() / 256.0;
      final targetX = r.u16() / 256.0;
      final targetY = r.u16() / 256.0;
      final lives = r.u8();
      final maxBombs = r.u8();
      final activeBombs = r.u8();
      final range = r.u8();
      final speed = r.u8() / 16.0;
      final boolFlags = r.u8();
      final isAlive = (boolFlags & 0x01) != 0;
      final isGhost = (boolFlags & 0x02) != 0;
      final hasShield = (boolFlags & 0x04) != 0;
      final isBot = (boolFlags & 0x08) != 0;
      final nameLen = r.u8();
      final displayName = utf8.decode(r.read(nameLen));
      final powerupCount = r.u8();
      final powerups = List.generate(
        powerupCount,
        (_) {
          final idx = r.u8();
          return (idx >= 0 && idx < PowerupType.values.length)
              ? PowerupType.values[idx]
              : PowerupType.extraBomb;
        },
      );
      return BombPlayer(
        id: id,
        x: x,
        y: y,
        targetX: targetX,
        targetY: targetY,
        lives: lives,
        maxBombs: maxBombs,
        activeBombs: activeBombs,
        range: range,
        speed: speed,
        isAlive: isAlive,
        isGhost: isGhost,
        hasShield: hasShield,
        isBot: isBot,
        displayName: displayName,
        powerups: powerups,
      );
    });

    // ── Bombs ───────────────────────────────────────────────────────────────
    final bombCount = r.u8();
    final bombs = List.generate(bombCount, (_) {
      final id = r.u8();
      final x = r.u8();
      final y = r.u8();
      final ownerId = r.u8();
      final range = r.u8();
      final fuseMs = r.u16();
      final totalFuseMs = r.u16();
      return Bomb(
        id: id,
        x: x,
        y: y,
        ownerId: ownerId,
        range: range,
        fuseMs: fuseMs,
        totalFuseMs: totalFuseMs,
      );
    });

    // ── Explosions ──────────────────────────────────────────────────────────
    final explosionCount = r.u8();
    final explosions = List.generate(explosionCount, (_) {
      final x = r.u8();
      final y = r.u8();
      final remainingMs = r.u16();
      final totalMs = r.u16();
      return ExplosionTile(
        x: x,
        y: y,
        remainingMs: remainingMs,
        totalMs: totalMs,
      );
    });

    // ── Powerup cells ───────────────────────────────────────────────────────
    final powerupCellCount = r.u8();
    final powerups = List.generate(powerupCellCount, (_) {
      final x = r.u8();
      final y = r.u8();
      final idx = r.u8();
      final type = (idx >= 0 && idx < PowerupType.values.length)
          ? PowerupType.values[idx]
          : PowerupType.extraBomb;
      return PowerupCell(x: x, y: y, type: type);
    });

    return current.copyWith(
      players: players,
      bombs: bombs,
      explosions: explosions,
      powerups: powerups,
      phase: phase,
      countdown: countdown,
      roundTimeSeconds: roundTimeSeconds,
      round: round,
      roundWins: roundWins,
      winnerId: winnerId,
      roundOverMessage: roundOverMessage,
      clearWinner: !hasWinnerId,
      clearRoundOverMessage: !hasMsg,
    );
  }
}

// ─── Writer ──────────────────────────────────────────────────────────────────

class _Writer {
  final _buf = BytesBuilder(copy: false);

  void u8(int v) => _buf.addByte(v & 0xFF);

  void u16(int v) {
    _buf.addByte((v >> 8) & 0xFF);
    _buf.addByte(v & 0xFF);
  }

  void u32be(int v) {
    _buf.addByte((v >> 24) & 0xFF);
    _buf.addByte((v >> 16) & 0xFF);
    _buf.addByte((v >> 8) & 0xFF);
    _buf.addByte(v & 0xFF);
  }

  void bytes(List<int> data) => _buf.add(data);

  Uint8List toBytes() => _buf.toBytes();
}

// ─── Reader ──────────────────────────────────────────────────────────────────

class _Reader {
  final Uint8List _buf;
  int _pos = 0;

  _Reader(this._buf);

  int u8() => _buf[_pos++];

  int u16() {
    final hi = _buf[_pos++];
    final lo = _buf[_pos++];
    return (hi << 8) | lo;
  }

  void skip(int n) => _pos += n;

  Uint8List read(int n) {
    final slice = _buf.sublist(_pos, _pos + n);
    _pos += n;
    return slice;
  }
}
