import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/design_system/ds_colors.dart';
import 'package:multigame/design_system/ds_typography.dart';
import 'package:multigame/utils/input_validator.dart';
import 'package:multigame/utils/navigation_utils.dart';
import 'package:multigame/utils/secure_logger.dart';

import '../multiplayer/rummy_client.dart';
import '../multiplayer/rummy_message.dart';
import '../multiplayer/rummy_room.dart';
import '../providers/rummy_notifier.dart';

// Platform conditional import — web stub or native io implementation.
import 'package:multigame/games/rummy/multiplayer/rummy_server_stub.dart'
    if (dart.library.io) 'package:multigame/games/rummy/multiplayer/rummy_server_io.dart';


enum _LobbyView { home, hosting, joining }

class RummyLobbyPage extends ConsumerStatefulWidget {
  const RummyLobbyPage({super.key});

  @override
  ConsumerState<RummyLobbyPage> createState() => _RummyLobbyPageState();
}

class _RummyLobbyPageState extends ConsumerState<RummyLobbyPage> {
  _LobbyView _view = _LobbyView.home;

  // Host state
  RummyServerIo? _server;
  String _hostCode = '';
  String _hostIp = '';
  final List<RummyRoomPlayer> _hostPlayers = [];

  // Guest state
  RummyClient? _client;
  int _myPlayerId = 1;
  bool _connecting = false;
  String? _connectError;
  bool _joined = false;

  // Shared
  final _nameController = TextEditingController(text: 'Player');
  final _codeController = TextEditingController();
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _server?.stop();
    _client?.disconnect();
    _nameController.dispose();
    _codeController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // ── Host ────────────────────────────────────────────────────────────────────

  Future<void> _startHosting() async {
    if (kIsWeb) {
      return;
    }

    final rawName = _nameController.text.trim();
    final name = rawName.isEmpty ? 'Host' : rawName;
    if (rawName.isNotEmpty) {
      final v = InputValidator.validateNickname(rawName);
      if (!v.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(v.error!)),
        );
        return;
      }
    }

    final server = RummyServerIo(hostDisplayName: name);
    final ip = await RummyServerIo.getLocalIp();
    if (ip == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get local IP. Are you on WiFi?')),
        );
      }
      return;
    }

    final code = RummyRoom.generateCode();
    final port = RummyRoom.portFromCode(code);

    try {
      await server.start(port);
    } catch (e, st) {
      SecureLogger.error('Failed to start Rummy server', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start server: $e')),
        );
      }
      return;
    }

    server.onMessage = (msg, fromId) {
      if (mounted) {
        setState(() {
          _hostPlayers
            ..clear()
            ..addAll(server.room.players);
        });
      }
    };

    setState(() {
      _server = server;
      _hostCode = code;
      _hostIp = ip;
      _view = _LobbyView.hosting;
      _hostPlayers
        ..clear()
        ..addAll(server.room.players);
    });
  }

  void _stopHosting() {
    _server?.stop();
    setState(() {
      _server = null;
      _hostCode = '';
      _hostIp = '';
      _hostPlayers.clear();
      _view = _LobbyView.home;
    });
  }

  Future<void> _startGame() async {
    final server = _server;
    if (server == null || !server.room.canStart) {
      return;
    }

    final name = _nameController.text.trim().isEmpty ? 'Host' : _nameController.text.trim();
    final port = RummyRoom.portFromCode(_hostCode);

    final client = RummyClient(hostIp: '127.0.0.1', displayName: name);
    client.onMessage = (_) {};
    try {
      await client.connect(port);
    } catch (_) {
      // Non-fatal if self-connection fails.
    }

    server.broadcast(RummyMessage.start.encode());

    final players = server.room.players
        .map((p) => (id: p.id, name: p.displayName))
        .toList();

    ref.read(rummyProvider.notifier).startMultiplayerHost(
      server: server,
      client: client,
      players: players,
    );

    _server = null;
    _client = null;

    if (mounted) {
      context.go(AppRoutes.game('rummy'));
    }
  }

  // ── Guest ────────────────────────────────────────────────────────────────────

  Future<void> _joinGame() async {
    final code = _codeController.text.trim();
    final hostIp = _ipController.text.trim();

    if (code.length != 6) {
      setState(() => _connectError = 'Enter a 6-digit code');
      return;
    }
    final ipValidation = InputValidator.validateIpAddress(hostIp);
    if (!ipValidation.isValid) {
      setState(() => _connectError = ipValidation.error);
      return;
    }

    setState(() {
      _connecting = true;
      _connectError = null;
    });

    final port = RummyRoom.portFromCode(code);
    final name = _nameController.text.trim().isEmpty ? 'Guest' : _nameController.text.trim();
    final client = RummyClient(hostIp: hostIp, displayName: name);

    client.onMessage = (msg) {
      switch (msg.type) {
        case RummyMessageType.joined:
          final id = msg.payload['id'] as int? ?? 1;
          if (mounted) {
            setState(() {
              _myPlayerId = id;
              _joined = true;
            });
          }
        case RummyMessageType.start:
          final c = _client;
          if (c == null) {
            return;
          }
          _client = null;
          ref.read(rummyProvider.notifier).connectAsGuest(
            client: c,
            localPlayerId: _myPlayerId,
          );
          if (mounted) {
            context.go(AppRoutes.game('rummy'));
          }
        default:
          break;
      }
    };

    client.onDisconnected = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Host disconnected')),
        );
        NavigationUtils.goHome(context);
      }
    };

    try {
      await client.connect(port);
    } catch (e) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _connectError = 'Could not connect: $e';
        });
      }
      return;
    }

    setState(() {
      _client = client;
      _connecting = false;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.backgroundSecondary,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    String title;
    VoidCallback onBack;

    switch (_view) {
      case _LobbyView.home:
        title = 'RUMMY — WIFI';
        onBack = () => NavigationUtils.goHome(context);
      case _LobbyView.hosting:
        title = 'MATCH LOBBY';
        onBack = _stopHosting;
      case _LobbyView.joining:
        title = 'JOIN GAME';
        onBack = () => setState(() {
          _view = _LobbyView.home;
          _joined = false;
          _connectError = null;
        });
    }

    return AppBar(
      backgroundColor: DSColors.backgroundSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: DSColors.surfaceHighlight),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _LobbyView.home:
        return _buildHomeView();
      case _LobbyView.hosting:
        return _buildHostingView();
      case _LobbyView.joining:
        return _buildJoiningView();
    }
  }

  // ── Home view ────────────────────────────────────────────────────────────────

  Widget _buildHomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_rounded, color: DSColors.rummyAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              'RUMMY\nWIFI MULTIPLAYER',
              textAlign: TextAlign.center,
              style: DSTypography.titleLarge.copyWith(
                color: DSColors.rummyAccent,
                letterSpacing: 3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '2–4 players on the same network',
              style: DSTypography.bodySmall.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 48),
            _LobbyButton(
              label: 'CREATE ROOM',
              subtitle: 'Host a new game',
              icon: Icons.add_circle_outline,
              color: DSColors.rummyPrimary,
              onTap: kIsWeb ? null : () {
                setState(() => _view = _LobbyView.hosting);
                _startHosting();
              },
            ),
            const SizedBox(height: 16),
            _LobbyButton(
              label: 'JOIN ROOM',
              subtitle: kIsWeb ? 'Not available on web' : 'Enter code to join',
              icon: Icons.login,
              color: DSColors.rummyPrimary,
              onTap: kIsWeb ? null : () => setState(() => _view = _LobbyView.joining),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: DSColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DSColors.surfaceHighlight),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white38, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Local WiFi multiplayer requires the Android app.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Hosting view ─────────────────────────────────────────────────────────────

  Widget _buildHostingView() {
    final canStart = _hostPlayers.length >= RummyRoom.minPlayers;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DSColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DSColors.surfaceHighlight),
            ),
            child: Column(
              children: [
                const Text(
                  'ROOM CODE',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _hostCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white38, size: 20),
                      onPressed: () => Clipboard.setData(ClipboardData(text: _hostCode)),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Host IP: $_hostIp',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PLAYERS (${_hostPlayers.length}/${RummyRoom.maxPlayers})',
            style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in _hostPlayers)
                _PlayerChip(name: p.displayName, isHost: p.isHost),
              for (var i = _hostPlayers.length; i < RummyRoom.maxPlayers; i++)
                const _PlayerChip(name: null, isHost: false),
            ],
          ),
          if (!canStart) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Waiting for players… (${_hostPlayers.length}/${RummyRoom.minPlayers} min)',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _LobbyButton(
              label: 'START GAME',
              icon: Icons.play_arrow_rounded,
              color: canStart ? DSColors.rummyPrimary : Colors.grey.shade700,
              onTap: canStart ? _startGame : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Join view ────────────────────────────────────────────────────────────────

  Widget _buildJoiningView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('Your name'),
          const SizedBox(height: 8),
          _LobbyTextField(controller: _nameController, hint: 'Enter your name'),
          const SizedBox(height: 20),
          const _FieldLabel('Host IP address'),
          const SizedBox(height: 8),
          _LobbyTextField(
            controller: _ipController,
            hint: '192.168.x.x',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Room code'),
          const SizedBox(height: 8),
          _LobbyTextField(
            controller: _codeController,
            hint: '6-digit code',
            maxLength: 6,
            keyboardType: TextInputType.number,
          ),
          if (_connectError != null) ...[
            const SizedBox(height: 8),
            Text(
              _connectError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          if (!_joined) ...[
            SizedBox(
              width: double.infinity,
              child: _LobbyButton(
                label: _connecting ? 'Connecting...' : 'JOIN ROOM',
                icon: _connecting ? null : Icons.login,
                color: _connecting ? Colors.grey.shade700 : DSColors.rummyPrimary,
                onTap: _connecting ? null : _joinGame,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DSColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DSColors.rummyPrimary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.rummyPrimary),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Waiting for host to start...',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _PlayerChip ────────────────────────────────────────────────────────────────

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name, required this.isHost});

  final String? name;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final empty = name == null;
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: empty ? DSColors.surfaceHighlight : DSColors.rummyPrimary.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: empty ? Colors.transparent : DSColors.rummyPrimary.withValues(alpha: 0.15),
              border: Border.all(
                color: empty ? DSColors.surfaceHighlight : DSColors.rummyPrimary,
                width: empty ? 1 : 2,
              ),
            ),
            child: empty
                ? const Icon(Icons.person_outline, color: Colors.white24, size: 20)
                : Center(
                    child: Text(
                      (name!.isNotEmpty ? name![0] : '?').toUpperCase(),
                      style: const TextStyle(
                        color: DSColors.rummyPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            empty ? 'Waiting...' : name!,
            style: TextStyle(
              color: empty ? Colors.white24 : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isHost ? DSColors.rummyAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHost ? DSColors.rummyAccent.withValues(alpha: 0.6) : Colors.white12,
              ),
            ),
            child: Text(
              isHost ? 'HOST' : (empty ? 'OPEN' : 'READY'),
              style: TextStyle(
                color: isHost ? DSColors.rummyAccent : (empty ? Colors.white24 : DSColors.rummyPrimary),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _LobbyButton ──────────────────────────────────────────────────────────────

class _LobbyButton extends StatelessWidget {
  const _LobbyButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade800 : color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LobbyTextField extends StatelessWidget {
  const _LobbyTextField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        counterText: '',
        filled: true,
        fillColor: DSColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DSColors.surfaceHighlight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DSColors.surfaceHighlight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DSColors.rummyPrimary, width: 1.5),
        ),
      ),
    );
  }
}
