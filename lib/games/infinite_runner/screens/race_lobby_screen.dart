import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../multiplayer/race_client.dart';
import '../multiplayer/race_player_state.dart';
import '../multiplayer/race_room.dart';
import '../multiplayer/race_server.dart';
import '../state/game_mode.dart';
import 'infinite_runner_screen.dart';

/// Entry screen for Race Mode.
/// - If [isHost] = true: starts a local server, shows room code, waits for players
/// - If [isHost] = false: shows a code-entry field and connects as guest
class RaceLobbyScreen extends StatefulWidget {
  const RaceLobbyScreen({super.key, required this.isHost});

  final bool isHost;

  @override
  State<RaceLobbyScreen> createState() => _RaceLobbyScreenState();
}

class _RaceLobbyScreenState extends State<RaceLobbyScreen> {
  static const _accentCyan = Color(0xFF00d4ff);
  static const _accentGold = Color(0xFFffd700);
  static const _bg = Color(0xFF16181d);
  static const _surface = Color(0xFF21242b);

  RaceServer? _server;
  RaceClient? _client;
  RaceRoom? _room;

  String _displayName = 'Player';
  String _hostIp = '';
  String _roomCode = '';
  String _codeInput = '';
  String _networkPrefix = '192.168.1.'; // fallback
  String _manualIp = ''; // manual IP fallback for guests
  // On web, always show manual IP (room-code discovery doesn't work cross-subnet)
  bool _showManualIp = kIsWeb;
  bool _isReady = false;
  bool _isConnecting = false;
  bool _isStarting = false;
  String? _errorMsg;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _manualIpController = TextEditingController();

  static const _kDisplayNameKey = 'runner_race_display_name';

  /// True only on native platforms where a WebSocket server can actually run.
  /// Web browsers cannot host — they connect as guests only.
  bool get _isEffectivelyHost => widget.isHost && !kIsWeb;

  @override
  void initState() {
    super.initState();
    _nameController.text = _displayName;
    _loadName();
    if (_isEffectivelyHost) {
      _initHost();
    }
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kDisplayNameKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _displayName = saved;
        _nameController.text = saved;
      });
    }
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayNameKey, name);
  }

  @override
  void dispose() {
    _client?.disconnect();
    _server?.stop();
    _codeController.dispose();
    _nameController.dispose();
    _manualIpController.dispose();
    super.dispose();
  }

  // ── Host flow ───────────────────────────────────────────────────────────────

  Future<void> _initHost() async {
    setState(() => _isConnecting = true);
    try {
      final info = NetworkInfo();
      final wifiIp = await info.getWifiIP();
      _hostIp = wifiIp ?? '192.168.1.1';

      // Derive network prefix (first three octets)
      final parts = _hostIp.split('.');
      if (parts.length == 4) {
        _networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
      }

      _server = RaceServer(hostDisplayName: _displayName);
      final ip = await _server!.start();
      if (ip == null) throw Exception('Failed to start server');

      _hostIp = ip;
      _roomCode = RaceRoom.ipToRoomCode(ip);

      _room = RaceRoom(hostIp: ip, localPlayerId: 0);

      // Host also connects as a client to receive relayed messages
      _client = RaceClient(
        hostIp: ip,
        displayName: _displayName,
        room: _room!,
        raceServer: _server,
      );
      await _client!.connect();
      _client!.onEvent = _handleClientEvent;
      _server!.onEvent = _handleServerEvent;

      setState(() => _isConnecting = false);
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMsg = 'Could not start server: $e';
      });
    }
  }

  // ── Guest flow ──────────────────────────────────────────────────────────────

  Future<void> _connectAsGuest() async {
    if (_codeInput.length != 6 && _manualIp.isEmpty) {
      setState(() => _errorMsg = kIsWeb
          ? 'Enter the host\'s IP address (e.g. 192.168.1.42)'
          : 'Enter the 6-digit room code');
      return;
    }
    setState(() {
      _isConnecting = true;
      _errorMsg = null;
    });
    try {
      final ip = _manualIp.isNotEmpty
          ? _manualIp.trim()
          : RaceRoom.roomCodeToIp(_codeInput, _networkPrefix);
      if (ip.isEmpty) throw Exception('Invalid code');

      _room = RaceRoom(hostIp: ip, localPlayerId: -1); // ID assigned on join
      _client = RaceClient(
        hostIp: ip,
        displayName: _displayName,
        room: _room!,
      );
      await _client!.connect();
      _client!.onEvent = _handleClientEvent;
      _client!.onHostLeft = _handleHostLeft;

      setState(() => _isConnecting = false);
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMsg = 'Could not connect: check the code and try again';
      });
    }
  }

  // ── Event handlers ──────────────────────────────────────────────────────────

  void _handleClientEvent(RaceClientEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case RaceClientEventType.playerListUpdated:
          if (event.assignedId != null && !_isEffectivelyHost) {
            // Guest just got their ID assigned
            _room = RaceRoom(
              hostIp: _room!.hostIp,
              localPlayerId: event.assignedId!,
              players: event.players,
            );
            _client = RaceClient(
              hostIp: _room!.hostIp,
              displayName: _displayName,
              room: _room!,
            );
          }
          if (event.players != null) {
            for (final p in event.players!) {
              _room?.upsertPlayer(p);
            }
          }
        case RaceClientEventType.raceStarting:
          _launchRace();
        case RaceClientEventType.errorReceived:
          _errorMsg = event.errorMessage ?? 'Unknown error';
        default:
          break;
      }
    });
  }

  void _handleServerEvent(RaceServerEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case RaceServerEventType.playerJoined:
          if (event.players != null) {
            for (final p in event.players!) {
              _room?.upsertPlayer(p);
            }
          }
        case RaceServerEventType.allReady:
          // Enable the Start button automatically when all ready
          break;
        default:
          break;
      }
    });
  }

  void _handleHostLeft() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Host left the room')),
    );
    context.go(AppRoutes.home);
  }

  // ── Ready / Start ───────────────────────────────────────────────────────────

  void _toggleReady() {
    _isReady = !_isReady;
    _client?.sendReady(_isReady);
    // Host updates its own state on the server side as well
    if (_isEffectivelyHost) _server?.setHostReady(_isReady);
    setState(() {});
  }

  void _startRace() {
    if (!_isEffectivelyHost) return;
    setState(() => _isStarting = true);
    _server?.broadcastStart();
    _launchRace();
  }

  void _launchRace() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InfiniteRunnerPage(
          mode: GameMode.race,
          raceClient: _client,
          raceRoom: _room,
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: Text(
          _isEffectivelyHost ? 'Host a Race' : 'Join a Race',
          style: const TextStyle(
            color: _accentCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: _isConnecting && !_isEffectivelyHost
          ? const Center(
              child: CircularProgressIndicator(color: _accentCyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name field
                  _NameField(
                    controller: _nameController,
                    onChanged: (v) {
                      _displayName = v.trim().isEmpty ? 'Player' : v.trim();
                      _saveName(_displayName);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Web-only: "hosting not available" notice
                  if (kIsWeb && widget.isHost) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hosting requires the native app.\n'
                              'Enter the host\'s IP address below to join.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Host-only: room code display (native only)
                  if (_isEffectivelyHost) ...[
                    _RoomCodeCard(
                      code: _isConnecting ? '...' : _roomCode,
                      ip: _hostIp,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Guest UI: code entry + manual IP
                  if (!_isEffectivelyHost) ...[
                    _CodeEntryField(
                      controller: _codeController,
                      onChanged: (v) => _codeInput = v,
                      onSubmit: _connectAsGuest,
                    ),
                    const SizedBox(height: 8),
                    // Manual IP fallback: always shown on web, toggle on native
                    if (!kIsWeb)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showManualIp = !_showManualIp),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showManualIp
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showManualIp
                                  ? 'Hide manual IP'
                                  : 'Different subnet? Enter IP manually',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_showManualIp) ...[
                      const SizedBox(height: 8),
                      _ManualIpField(
                        controller: _manualIpController,
                        onChanged: (v) => _manualIp = v.trim(),
                        onSubmit: _connectAsGuest,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isConnecting ? null : _connectAsGuest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentCyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CONNECT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Player list
                  if (_room != null) ...[
                    _PlayerList(players: _room!.players),
                    const SizedBox(height: 20),
                  ],

                  // Error message
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Text(
                        _errorMsg!,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Ready button (everyone)
                  if (_room != null)
                    ElevatedButton(
                      onPressed: _toggleReady,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isReady
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isReady ? 'READY ✓' : 'READY UP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                  // Host-only: Start button (native only, enabled when all ready)
                  if (_isEffectivelyHost && _room != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: (_isStarting || (_room!.players.length < 2) || !_room!.allReady)
                          ? null
                          : _startRace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGold,
                        disabledBackgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'START RACE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR NAME',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter display name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2a2d36),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00d4ff)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  const _RoomCodeCard({required this.code, required this.ip});
  final String code;
  final String ip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21242b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00d4ff).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'ROOM CODE',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00d4ff),
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white54),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!')),
                  );
                },
              ),
            ],
          ),
          Text(
            ip,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CodeEntryField extends StatelessWidget {
  const _CodeEntryField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROOM CODE',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
          maxLength: 6,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF00d4ff),
            fontSize: 28,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 28,
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: const Color(0xFF2a2d36),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00d4ff)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualIpField extends StatelessWidget {
  const _ManualIpField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOST IP ADDRESS',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmit(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '192.168.x.x',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2a2d36),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF00d4ff)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.players});
  final List<RacePlayerState> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAYERS (${players.length}/4)',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        ...players.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2d36),
              borderRadius: BorderRadius.circular(10),
              border: p.isReady
                  ? Border.all(color: Colors.green.shade600)
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _playerColor(p.playerId),
                  child: Text(
                    p.displayName.isNotEmpty
                        ? p.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        p.playerId == 0 ? 'Host' : 'Guest ${p.playerId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                if (p.isReady)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else
                  const Icon(
                    Icons.circle_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _playerColor(int id) {
    const colors = [
      Color(0xFF00d4ff),
      Color(0xFFffd700),
      Color(0xFF7c4dff),
      Color(0xFFff6b35),
    ];
    return colors[id.clamp(0, colors.length - 1)];
  }
}
