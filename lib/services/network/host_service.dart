import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/game_action.dart';
import '../../models/game_state.dart';
import '../../models/lobby_player.dart';
import 'lan_protocol.dart';

typedef LobbySyncCallback = void Function(List<LobbyPlayer> players);
typedef ClientActionCallback = void Function(GameAction action);
typedef HostMessageCallback = void Function(String message);

class HostService {
  HostService({
    required this.port,
    required this.onLobbySync,
    required this.onClientAction,
    required this.onMessage,
  });

  final int port;
  final LobbySyncCallback onLobbySync;
  final ClientActionCallback onClientAction;
  final HostMessageCallback onMessage;

  ServerSocket? _server;
  final Map<String, Socket> _clientSockets = {};
  final Map<int, String> _socketOwners = {};
  final Map<String, LobbyPlayer> _players = {};
  final Map<String, DateTime> _lastSeen = {};
  Timer? _heartbeatTimer;

  Future<void> start(LobbyPlayer hostPlayer) async {
    _players[hostPlayer.id] = hostPlayer;
    _server =
        await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen(_handleIncomingSocket);
    _startHeartbeat();
    _emitLobby();
    onMessage('Sala LAN abierta en el puerto $port.');
  }

  Future<void> broadcastState(GameSessionState state) async {
    _broadcast({
      'type': LanProtocol.stateSync,
      'state': state.toJson(),
    });
  }

  Future<void> broadcastStartGame(GameSessionState state) async {
    _broadcast({
      'type': LanProtocol.startGame,
      'state': state.toJson(),
    });
  }

  Future<void> broadcastMessage(String message) async {
    _broadcast({
      'type': LanProtocol.serverMessage,
      'message': message,
    });
  }

  List<LobbyPlayer> get players =>
      _players.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    for (final socket in _clientSockets.values) {
      socket.destroy();
    }
    await _server?.close();
    _clientSockets.clear();
    _socketOwners.clear();
    _players.clear();
    _lastSeen.clear();
  }

  void _handleIncomingSocket(Socket socket) {
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _handleIncomingMessage(socket, line),
          onDone: () => _markDisconnected(socket),
          onError: (_) => _markDisconnected(socket),
        );
  }

  void _handleIncomingMessage(Socket socket, String rawMessage) {
    final message = LanProtocol.decode(rawMessage);
    final type = message['type'] as String? ?? '';
    switch (type) {
      case LanProtocol.hello:
      case LanProtocol.reconnect:
        _registerOrReconnect(socket, message);
        return;
      case LanProtocol.action:
        final ownerId = _socketOwners[socket.hashCode];
        if (ownerId == null) {
          return;
        }
        _lastSeen[ownerId] = DateTime.now();
        final action = GameAction.fromJson(
          (message['action'] as Map).cast<String, dynamic>(),
        );
        if (action.actorId != ownerId) {
          onMessage('Se ignoro una accion con actor invalido.');
          return;
        }
        onClientAction(action);
        return;
      case LanProtocol.ping:
        final ownerId = _socketOwners[socket.hashCode];
        if (ownerId != null) {
          _lastSeen[ownerId] = DateTime.now();
        }
        socket.write(LanProtocol.encode({'type': LanProtocol.pong}));
        return;
      default:
        return;
    }
  }

  void _registerOrReconnect(Socket socket, Map<String, dynamic> message) {
    final requestedId = message['playerId'] as String?;
    final name = message['name'] as String? ?? 'Invitado';
    final address = socket.remoteAddress.address;

    String playerId;
    if (requestedId != null && _players.containsKey(requestedId)) {
      playerId = requestedId;
    } else {
      playerId = 'lan-${DateTime.now().microsecondsSinceEpoch}';
    }

    _clientSockets[playerId] = socket;
    _socketOwners[socket.hashCode] = playerId;
    _lastSeen[playerId] = DateTime.now();
    _players[playerId] = LobbyPlayer(
      id: playerId,
      name: name,
      isHost: false,
      isConnected: true,
      address: address,
    );

    socket.write(
      LanProtocol.encode({
        'type': LanProtocol.joinAck,
        'playerId': playerId,
        'port': port,
      }),
    );
    _emitLobby();
    onMessage('$name conectado desde $address.');
  }

  void _markDisconnected(Socket socket) {
    final playerId = _socketOwners.remove(socket.hashCode);
    if (playerId == null) {
      return;
    }
    _clientSockets.remove(playerId);
    final player = _players[playerId];
    if (player != null) {
      _players[playerId] = player.copyWith(isConnected: false);
      _emitLobby();
      onMessage('${player.name} se desconecto.');
    }
  }

  void _emitLobby() {
    final snapshot = players;
    onLobbySync(snapshot);
    _broadcast({
      'type': LanProtocol.lobbySync,
      'players': snapshot.map((item) => item.toJson()).toList(),
    });
  }

  void _broadcast(Map<String, dynamic> payload) {
    final encoded = LanProtocol.encode(payload);
    for (final socket in _clientSockets.values) {
      socket.write(encoded);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      final staleIds = <String>[];
      for (final entry in _lastSeen.entries) {
        if (now.difference(entry.value).inSeconds > 15) {
          staleIds.add(entry.key);
        }
      }
      for (final playerId in staleIds) {
        _clientSockets[playerId]?.destroy();
        final player = _players[playerId];
        if (player != null) {
          _players[playerId] = player.copyWith(isConnected: false);
        }
      }
      if (staleIds.isNotEmpty) {
        _emitLobby();
      }
      _broadcast({'type': LanProtocol.ping});
    });
  }
}
