import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_client.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_message.dart';
import 'package:multigame/games/bomberman/multiplayer/bomb_room.dart';
import 'package:multigame/games/bomberman/providers/bomberman_notifier.dart';

// Platform conditional import — web stub or native io version
import 'package:multigame/games/bomberman/multiplayer/bomb_server_stub.dart'
    if (dart.library.io) 'package:multigame/games/bomberman/multiplayer/bomb_server_io.dart';

const _kPlayerColors = [
  Color(0xFF00d4ff),
  Color(0xFFffd700),
  Color(0xFF7c4dff),
  Color(0xFFff6b35),
];

class BombermanLobbyPage extends ConsumerStatefulWidget {
  const BombermanLobbyPage({super.key});

  @override
  ConsumerState<BombermanLobbyPage> createState() => _BombermanLobbyPageState();
}

class _BombermanLobbyPageState extends ConsumerState<BombermanLobbyPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Host state
  BombServerIo? _server;
  String _hostCode = '';
  String _hostIp = '';
  bool _hosting = false;

  // Guest state
  BombClient? _client;
  int _myPlayerId = 0;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController(text: 'Player');
  bool _connecting = false;
  String? _connectError;

  // Shared player list for host display
  final List<BombRoomPlayer> _hostPlayers = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: kIsWeb ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _server?.stop();
    _client?.disconnect();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─── Host ──────────────────────────────────────────────────────────────────

  Future<void> _startHosting() async {
    if (kIsWeb) return;

    final name = _nameController.text.trim().isEmpty
        ? 'Host'
        : _nameController.text.trim();

    final server = BombServerIo(hostDisplayName: name);
    final ip = await BombServerIo.getLocalIp();
    if (ip == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get local IP. Are you on WiFi?'),
          ),
        );
      }
      return;
    }

    final code = BombRoom.generateCode();
    final port = BombRoom.portFromCode(code);

    try {
      await server.start(port);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start server: $e')));
      }
      return;
    }

    server.onMessage = (msg, fromId) {
      if (mounted) {
        setState(() {
          _hostPlayers.clear();
          _hostPlayers.addAll(server.room.players);
        });
      }
    };

    setState(() {
      _server = server;
      _hostCode = code;
      _hostIp = ip;
      _hosting = true;
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
      _hosting = false;
      _hostPlayers.clear();
    });
  }

  Future<void> _startMultiplayerGame() async {
    final server = _server;
    if (server == null) return;

    // Host also connects to its own server so it receives broadcasts
    final room = BombRoom();
    final hostName = _nameController.text.trim().isEmpty
        ? 'Host'
        : _nameController.text.trim();
    final client = BombClient(
      hostIp: '127.0.0.1',
      displayName: hostName,
      room: room,
    );
    final port = BombRoom.portFromCode(_hostCode);

    try {
      await client.connect(port);
    } catch (_) {
      // If self-connection fails it's non-fatal — proceed without it
    }

    // Broadcast start to all guests before transferring ownership
    server.broadcast(BombMessage.start().encode());

    final players = server.room.players
        .map((p) => (id: p.id, name: p.displayName))
        .toList();

    ref
        .read(bombermanProvider.notifier)
        .startMultiplayerHost(server: server, client: client, players: players);

    // Notifier now owns server and client — clear local references
    _server = null;
    _client = null;

    if (mounted) context.go(AppRoutes.game('bomberman'));
  }

  // ─── Guest ─────────────────────────────────────────────────────────────────

  Future<void> _joinGame() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _connectError = 'Enter a 6-digit code');
      return;
    }

    setState(() {
      _connecting = true;
      _connectError = null;
    });

    final port = BombRoom.portFromCode(code);
    // We need the host IP — for now the guest types it in the name field
    // as a temporary fallback. In production, you'd resolve via discovery.
    final hostIp = _nameController.text.trim();
    final name = 'Guest';

    final room = BombRoom();
    final client = BombClient(hostIp: hostIp, displayName: name, room: room);

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

    client.onMessage = (msg) {
      switch (msg.type) {
        case BombMessageType.joined:
          final id = msg.payload['id'] as int? ?? 0;
          if (mounted) setState(() => _myPlayerId = id);
        case BombMessageType.start:
          final c = _client;
          if (c == null) return;
          // Transfer ownership to notifier
          _client = null;
          ref
              .read(bombermanProvider.notifier)
              .connectAsGuest(client: c, localPlayerId: _myPlayerId);
          if (mounted) context.go(AppRoutes.game('bomberman'));
        default:
          break;
      }
    };
    client.onDisconnected = () {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Host disconnected')));
        context.go(AppRoutes.home);
      }
    };

    setState(() {
      _client = client;
      _connecting = false;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111520),
        title: const Text(
          'BOMBERMAN',
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go(AppRoutes.home),
        ),
        bottom: kIsWeb
            ? null
            : TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'HOST'),
                  Tab(text: 'JOIN'),
                ],
                labelColor: const Color(0xFF00d4ff),
                unselectedLabelColor: Colors.white54,
                indicatorColor: const Color(0xFF00d4ff),
              ),
      ),
      body: kIsWeb
          ? _buildJoinTab()
          : TabBarView(
              controller: _tabs,
              children: [_buildHostTab(), _buildJoinTab()],
            ),
    );
  }

  // ─── Host tab ─────────────────────────────────────────────────────────────

  Widget _buildHostTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Your name'),
          const SizedBox(height: 8),
          _TextField(controller: _nameController, hint: 'Enter name'),
          const SizedBox(height: 24),
          if (!_hosting) ...[
            _PrimaryButton(
              label: 'Create Room',
              onTap: _startHosting,
              color: const Color(0xFF00d4ff),
            ),
          ] else ...[
            // Room code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1e2e),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00d4ff).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Code',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _hostCode,
                        style: const TextStyle(
                          color: Color(0xFF00d4ff),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white54),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: _hostCode)),
                        tooltip: 'Copy code',
                      ),
                    ],
                  ),
                  Text(
                    'Host IP: $_hostIp',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Player list
            Text(
              'Players (${_hostPlayers.length}/${BombRoom.maxPlayers})',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ..._hostPlayers.mapIndexed(
              (i, p) => _PlayerRow(player: p, color: _kPlayerColors[i % 4]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    label: 'Start Game',
                    onTap: _hostPlayers.length >= 2
                        ? _startMultiplayerGame
                        : null,
                    color: const Color(0xFF00d4ff),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _stopHosting,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Join tab ─────────────────────────────────────────────────────────────

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1e2e),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Web: join only. To host, use the desktop or mobile app.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          _SectionTitle('Host IP address'),
          const SizedBox(height: 8),
          _TextField(controller: _nameController, hint: 'e.g. 192.168.1.100'),
          const SizedBox(height: 16),
          _SectionTitle('Room code'),
          const SizedBox(height: 8),
          _TextField(
            controller: _codeController,
            hint: '6-digit code',
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          if (_connectError != null) ...[
            const SizedBox(height: 8),
            Text(
              _connectError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          _connecting
              ? const Center(child: CircularProgressIndicator())
              : _PrimaryButton(
                  label: 'Join Room',
                  onTap: _joinGame,
                  color: const Color(0xFFffd700),
                ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLength;

  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: const Color(0xFF1a1e2e),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        counterStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF111520),
          disabledBackgroundColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final BombRoomPlayer player;
  final Color color;

  const _PlayerRow({required this.player, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            player.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (player.isHost) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'HOST',
                style: TextStyle(color: color, fontSize: 9, letterSpacing: 1),
              ),
            ),
          ],
          const Spacer(),
          Icon(
            player.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
            color: player.isReady ? Colors.greenAccent : Colors.white24,
            size: 18,
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int, T) f) =>
      List.generate(length, (i) => f(i, this[i]));
}
