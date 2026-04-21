import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/game_action.dart';
import '../../models/game_state.dart';
import '../../models/lobby_player.dart';
import 'lan_protocol.dart';

typedef ClientLobbyCallback = void Function(List<LobbyPlayer> players);
typedef ClientStateCallback = void Function(GameSessionState state);
typedef ClientConnectionCallback = void Function(
    bool isConnected, String? status);
typedef ClientMessageCallback = void Function(String message);
typedef PlayerIdCallback = void Function(String playerId);

class ClientService {
  ClientService({
    required this.host,
    required this.port,
    required this.playerName,
    required this.onLobbySync,
    required this.onStateSync,
    required this.onConnectionChanged,
    required this.onMessage,
    required this.onPlayerIdAssigned,
  });

  final String host;
  final int port;
  final String playerName;
  final ClientLobbyCallback onLobbySync;
  final ClientStateCallback onStateSync;
  final ClientConnectionCallback onConnectionChanged;
  final ClientMessageCallback onMessage;
  final PlayerIdCallback onPlayerIdAssigned;

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime _lastPong = DateTime.now();
  bool _manualDisconnect = false;
  int _attempts = 0;
  String? _playerId;

  String? get playerId => _playerId;

  Future<void> connect() async {
    _manualDisconnect = false;
    try {
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      _subscription = _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleIncomingMessage,
            onDone: _handleDisconnect,
            onError: (_) => _handleDisconnect(),
          );
      _socket!.write(
        LanProtocol.encode({
          'type': _playerId == null ? LanProtocol.hello : LanProtocol.reconnect,
          'playerId': _playerId,
          'name': playerName,
        }),
      );
      _lastPong = DateTime.now();
      _attempts = 0;
      _startHeartbeat();
      onConnectionChanged(true, 'Conectado a $host:$port');
    } catch (_) {
      _handleDisconnect();
    }
  }

  Future<void> sendAction(GameAction action) async {
    _socket?.write(
      LanProtocol.encode({
        'type': LanProtocol.action,
        'action': action.toJson(),
      }),
    );
  }

  Future<void> reconnectNow() async {
    _reconnectTimer?.cancel();
    await connect();
  }

  Future<void> dispose() async {
    _manualDisconnect = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _socket?.destroy();
  }

  void _handleIncomingMessage(String rawMessage) {
    final message = LanProtocol.decode(rawMessage);
    final type = message['type'] as String? ?? '';
    switch (type) {
      case LanProtocol.joinAck:
        final assignedId = message['playerId'] as String? ?? '';
        if (assignedId.isNotEmpty) {
          _playerId = assignedId;
          onPlayerIdAssigned(assignedId);
        }
        return;
      case LanProtocol.lobbySync:
        final players = ((message['players'] as List<dynamic>?) ?? const [])
            .map((item) =>
                LobbyPlayer.fromJson((item as Map).cast<String, dynamic>()))
            .toList();
        onLobbySync(players);
        return;
      case LanProtocol.startGame:
      case LanProtocol.stateSync:
        final state = GameSessionState.fromJson(
          (message['state'] as Map).cast<String, dynamic>(),
        );
        onStateSync(state);
        return;
      case LanProtocol.serverMessage:
        onMessage(message['message'] as String? ?? '');
        return;
      case LanProtocol.ping:
        _socket?.write(LanProtocol.encode({'type': LanProtocol.pong}));
        return;
      case LanProtocol.pong:
        _lastPong = DateTime.now();
        return;
      default:
        return;
    }
  }

  void _handleDisconnect() {
    onConnectionChanged(false, 'Conexion perdida. Intentando reconectar...');
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _socket?.destroy();
    _socket = null;
    if (_manualDisconnect) {
      return;
    }
    if (_attempts >= 5) {
      onMessage('No fue posible reconectar al host.');
      return;
    }
    _attempts += 1;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _socket?.write(LanProtocol.encode({'type': LanProtocol.ping}));
      if (DateTime.now().difference(_lastPong).inSeconds > 15) {
        _handleDisconnect();
      }
    });
  }
}
