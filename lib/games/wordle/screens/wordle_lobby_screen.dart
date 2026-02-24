import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multigame/config/app_router.dart';
import 'package:multigame/utils/input_validator.dart';
import 'package:multigame/utils/secure_logger.dart';

import '../multiplayer/wordle_client.dart';
import '../multiplayer/wordle_message.dart';
import '../multiplayer/wordle_room.dart';
import '../providers/wordle_notifier.dart';

// Platform conditional import — web stub or native io version
import 'package:multigame/games/wordle/multiplayer/wordle_server_stub.dart'
    if (dart.library.io) 'package:multigame/games/wordle/multiplayer/wordle_server_io.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0D1117);
const _kCard = Color(0xFF161B22);
const _kBorder = Color(0xFF30363D);
const _kCyan = Color(0xFF58A6FF);
const _kPurple = Color(0xFF8B5CF6);
const _kGreen = Color(0xFF3FB950);

enum _LobbyView { home, hosting, joining }

class WordleLobbyPage extends ConsumerStatefulWidget {
  const WordleLobbyPage({super.key});

  @override
  ConsumerState<WordleLobbyPage> createState() => _WordleLobbyPageState();
}

class _WordleLobbyPageState extends ConsumerState<WordleLobbyPage> {
  _LobbyView _view = _LobbyView.home;

  // Host state
  WordleServerIo? _server;
  String _hostCode = '';
  String _hostIp = '';
  final List<WordleRoomPlayer> _hostPlayers = [];

  // Guest state
  WordleClient? _client;
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

  // ── Host ───────────────────────────────────────────────────────────────────

  Future<void> _startHosting() async {
    if (kIsWeb) {
      return;
    }

    final rawName = _nameController.text.trim();
    if (rawName.isNotEmpty) {
      final v = InputValidator.validateNickname(rawName);
      if (!v.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(v.error!)),
        );
        return;
      }
    }
    final name = rawName.isEmpty ? 'Host' : rawName;

    final server = WordleServerIo(hostDisplayName: name);
    final ip = await WordleServerIo.getLocalIp();
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

    final code = WordleRoom.generateCode();
    final port = WordleRoom.portFromCode(code);

    try {
      await server.start(port);
    } catch (e, st) {
      SecureLogger.error('Failed to start server', error: e, stackTrace: st);
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
    if (server == null) {
      return;
    }

    final hostName = _nameController.text.trim().isEmpty
        ? 'Host'
        : _nameController.text.trim();

    final client = WordleClient(hostIp: '127.0.0.1', displayName: hostName);
    final port = WordleRoom.portFromCode(_hostCode);

    try {
      await client.connect(port);
    } catch (_) {
      // Non-fatal if self-connection fails
    }

    server.broadcast(WordleMessage.start.encode());

    final players = server.room.players
        .map((p) => (id: p.id, name: p.displayName))
        .toList();

    await ref
        .read(wordleProvider.notifier)
        .startMultiplayerHost(server: server, client: client, players: players);

    _server = null;
    _client = null;

    if (mounted) {
      context.go(AppRoutes.game('wordle'));
    }
  }

  // ── Guest ──────────────────────────────────────────────────────────────────

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

    final port = WordleRoom.portFromCode(code);
    final name = _nameController.text.trim().isEmpty
        ? 'Guest'
        : _nameController.text.trim();

    final client = WordleClient(hostIp: hostIp, displayName: name);

    client.onMessage = (msg) {
      switch (msg.type) {
        case WordleMessageType.joined:
          final id = msg.payload['playerId'] as int? ?? 1;
          if (mounted) {
            setState(() {
              _myPlayerId = id;
              _joined = true;
            });
          }
        case WordleMessageType.start:
          final c = _client;
          if (c == null) {
            return;
          }
          _client = null;
          ref
              .read(wordleProvider.notifier)
              .connectAsGuest(client: c, localPlayerId: _myPlayerId);
          if (mounted) {
            context.go(AppRoutes.game('wordle'));
          }
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    String title;
    VoidCallback onBack;

    switch (_view) {
      case _LobbyView.home:
        title = 'WORD CLASH';
        onBack = () => context.go(AppRoutes.home);
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
      backgroundColor: _kBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white70,
          size: 20,
        ),
        onPressed: onBack,
      ),
      title: _view == _LobbyView.home
          ? _GradientText(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            )
          : Text(
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
        child: Container(height: 1, color: _kBorder),
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

  // ── Home view ──────────────────────────────────────────────────────────────

  Widget _buildHomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GradientText(
              'WORD\nCLASH',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'COMPETITIVE WORDLE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 56),
            _GradientButton(
              label: 'HOST MATCH',
              subtitle: 'Create a new lobby',
              icon: Icons.add_circle_outline,
              gradientColors: const [Color(0xFF0099CC), _kCyan],
              onTap: kIsWeb
                  ? null
                  : () {
                      setState(() => _view = _LobbyView.hosting);
                      _startHosting();
                    },
            ),
            const SizedBox(height: 16),
            _GradientButton(
              label: 'JOIN MATCH',
              subtitle: kIsWeb ? 'Not available on web' : 'Enter code to join',
              icon: Icons.login,
              gradientColors: const [_kPurple, Color(0xFFA855F7)],
              onTap: kIsWeb
                  ? null
                  : () => setState(() => _view = _LobbyView.joining),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white38, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Local WiFi multiplayer requires the Android or Windows app.',
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

  // ── Hosting view ───────────────────────────────────────────────────────────

  Widget _buildHostingView() {
    final canStart = _hostPlayers.length >= 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join code card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                const Text(
                  'JOIN CODE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
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
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: _hostCode)),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Host IP: $_hostIp',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Share this code with your opponent',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Player slots
          Text(
            'PLAYERS (${_hostPlayers.length}/2)',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _hostPlayers.isNotEmpty
                    ? _PlayerSlotCard(
                        name: _hostPlayers[0].displayName,
                        isHost: true,
                        isReady: true,
                      )
                    : const _PlayerSlotCard(
                        name: null,
                        isHost: false,
                        isReady: false,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hostPlayers.length >= 2
                    ? _PlayerSlotCard(
                        name: _hostPlayers[1].displayName,
                        isHost: false,
                        isReady: true,
                      )
                    : const _PlayerSlotCard(
                        name: null,
                        isHost: false,
                        isReady: false,
                      ),
              ),
            ],
          ),

          if (!canStart) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Waiting for opponent to join…',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: _GradientButton(
              label: 'START MATCH',
              icon: Icons.play_arrow_rounded,
              gradientColors: canStart
                  ? const [Color(0xFF0099CC), _kCyan]
                  : const [Color(0xFF2D2D2D), Color(0xFF3D3D3D)],
              onTap: canStart ? _startGame : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Join view ──────────────────────────────────────────────────────────────

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
              child: _GradientButton(
                label: _connecting ? 'Connecting…' : 'JOIN ROOM',
                icon: _connecting ? null : Icons.login,
                gradientColors: _connecting
                    ? const [Color(0xFF2D2D2D), Color(0xFF3D3D3D)]
                    : const [_kPurple, Color(0xFFA855F7)],
                onTap: _connecting ? null : _joinGame,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Waiting for host to start…',
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

// ── _PlayerSlotCard ───────────────────────────────────────────────────────────

class _PlayerSlotCard extends StatelessWidget {
  const _PlayerSlotCard({
    required this.name,
    required this.isHost,
    required this.isReady,
  });

  final String? name;
  final bool isHost;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    final isEmpty = name == null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? _kGreen.withValues(alpha: 0.5) : _kBorder,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEmpty
                  ? Colors.transparent
                  : _kGreen.withValues(alpha: 0.15),
              border: Border.all(
                color: isEmpty ? _kBorder : _kGreen,
                width: isEmpty ? 1 : 2,
                style: isEmpty ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: isEmpty
                ? const Icon(
                    Icons.person_outline,
                    color: Colors.white24,
                    size: 24,
                  )
                : Center(
                    child: Text(
                      (name!.isNotEmpty ? name![0] : '?').toUpperCase(),
                      style: const TextStyle(
                        color: _kGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            isEmpty ? 'Waiting...' : name!,
            style: TextStyle(
              color: isEmpty ? Colors.white24 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isReady
                  ? _kGreen.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isReady
                    ? _kGreen.withValues(alpha: 0.6)
                    : Colors.white12,
              ),
            ),
            child: Text(
              isHost
                  ? 'HOST'
                  : isEmpty
                  ? 'NOT READY'
                  : 'READY',
              style: TextStyle(
                color: isReady ? _kGreen : Colors.white24,
                fontSize: 10,
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

// ── _GradientButton ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.gradientColors,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: onTap == null
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: gradientColors.last.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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

// ── _GradientText ─────────────────────────────────────────────────────────────

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_kCyan, _kGreen],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

// ── Local form widgets ────────────────────────────────────────────────────────

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
        fillColor: _kCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kCyan, width: 1.5),
        ),
      ),
    );
  }
}
