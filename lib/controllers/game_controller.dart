import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../engine/game_engine.dart';
import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/lobby_player.dart';
import '../models/rule_set.dart';
import '../services/network/client_service.dart';
import '../services/network/host_service.dart';

enum AppScreen {
  menu,
  lobby,
  game,
}

class GameController extends ChangeNotifier {
  RuleSet? _rules;
  GameEngine? _engine;
  GameSessionState? _state;
  HostService? _hostService;
  ClientService? _clientService;
  List<LobbyPlayer> _lobbyPlayers = const [];
  AppScreen _screen = AppScreen.menu;
  bool _loading = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _localPlayerId;
  String? _hostIp;
  int _port = 4040;
  bool _disposed = false;

  RuleSet? get rules => _rules;
  GameSessionState? get state => _state;
  List<LobbyPlayer> get lobbyPlayers => _lobbyPlayers;
  AppScreen get screen => _screen;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String? get localPlayerId => _localPlayerId;
  String? get hostIp => _hostIp;
  int get port => _port;

  bool get isHosting => _hostService != null;
  bool get isClient => _clientService != null;

  Future<void> initialize() async {
    await _ensureRulesLoaded();
  }

  Future<void> startLocalGame({
    required String playerName,
    required int cpuPlayers,
  }) async {
    await _ensureRulesLoaded();
    final engine = _engine;
    if (engine == null) {
      return;
    }
    await _clearNetworking(keepScreen: true);
    _localPlayerId = null;
    _state = engine.createLocalMatch(
      humanName: playerName,
      cpuCount: cpuPlayers,
    );
    _localPlayerId = _state?.players.first.id;
    _screen = AppScreen.game;
    _statusMessage = 'Partida local iniciada.';
    _emit();
  }

  Future<void> createLanRoom({
    required String playerName,
    required int port,
  }) async {
    await _ensureRulesLoaded();
    await _clearNetworking();
    _loading = true;
    _errorMessage = null;
    _statusMessage = null;
    _emit();

    _port = port;
    _hostIp = await _resolveLanIp();
    _localPlayerId = 'host-${DateTime.now().millisecondsSinceEpoch}';
    final hostPlayer = LobbyPlayer(
      id: _localPlayerId!,
      name: playerName,
      isHost: true,
      isConnected: true,
      address: _hostIp,
    );
    _lobbyPlayers = [hostPlayer];

    _hostService = HostService(
      port: port,
      onLobbySync: (players) {
        _lobbyPlayers = [
          hostPlayer.copyWith(address: _hostIp),
          ...players.where((item) => item.id != hostPlayer.id),
        ];
        if (_state != null && _engine != null) {
          var syncedState = _state!;
          for (final player in _lobbyPlayers) {
            syncedState = _engine!.updatePlayerConnection(
              syncedState,
              player.id,
              player.isConnected,
            );
          }
          _state = syncedState;
          _hostService?.broadcastState(syncedState);
        }
        _emit();
      },
      onClientAction: (action) {
        _applyActionFromHost(action);
      },
      onMessage: (message) {
        _statusMessage = message;
        _emit();
      },
    );

    try {
      await _hostService!.start(hostPlayer);
      _screen = AppScreen.lobby;
      _statusMessage = 'Sala creada en ${_hostIp ?? '0.0.0.0'}:$port';
    } catch (error) {
      _errorMessage = 'No fue posible crear la sala: $error';
    } finally {
      _loading = false;
      _emit();
    }
  }

  Future<void> joinLanRoom({
    required String playerName,
    required String hostIp,
    required int port,
  }) async {
    await _ensureRulesLoaded();
    await _clearNetworking();
    _loading = true;
    _errorMessage = null;
    _screen = AppScreen.lobby;
    _hostIp = hostIp;
    _port = port;
    _statusMessage = 'Conectando a $hostIp:$port';
    _emit();

    _clientService = ClientService(
      host: hostIp,
      port: port,
      playerName: playerName,
      onLobbySync: (players) {
        _lobbyPlayers = players;
        _emit();
      },
      onStateSync: (state) {
        _state = state.copyWith(mode: MatchMode.lanClient);
        _screen = AppScreen.game;
        _emit();
      },
      onConnectionChanged: (connected, status) {
        _statusMessage = status;
        _emit();
      },
      onMessage: (message) {
        _statusMessage = message;
        _emit();
      },
      onPlayerIdAssigned: (playerId) {
        _localPlayerId = playerId;
        _emit();
      },
    );

    await _clientService!.connect();
    _loading = false;
    _emit();
  }

  Future<void> startHostedLanMatch() async {
    final engine = _engine;
    if (engine == null || _lobbyPlayers.isEmpty || _hostService == null) {
      return;
    }
    _state = engine.createLanMatch(participants: _lobbyPlayers, isHost: true);
    _screen = AppScreen.game;
    _statusMessage = 'Partida LAN iniciada.';
    await _hostService!.broadcastStartGame(_state!);
    _emit();
  }

  Future<void> sendAction(GameAction action) async {
    if (_state == null) {
      return;
    }
    if (isHosting) {
      _applyActionFromHost(action);
      return;
    }
    if (isClient) {
      await _clientService?.sendAction(action);
      return;
    }
    _applyActionFromHost(action);
  }

  Future<void> reconnectToHost() async {
    await _clientService?.reconnectNow();
  }

  void returnToMenu() {
    _screen = AppScreen.menu;
    _state = null;
    _lobbyPlayers = const [];
    _statusMessage = null;
    _errorMessage = null;
    _localPlayerId = null;
    _clearNetworking(keepScreen: true);
    _emit();
  }

  Future<void> _ensureRulesLoaded() async {
    if (_rules != null) {
      return;
    }
    _loading = true;
    _emit();
    try {
      _rules = await RuleSetLoader.loadDefault();
      _engine = GameEngine(rules: _rules!);
    } catch (error) {
      _errorMessage = 'No fue posible cargar las reglas: $error';
    } finally {
      _loading = false;
      _emit();
    }
  }

  Future<String?> _resolveLanIp() async {
    if (!kIsWeb && Platform.isAndroid) {
      await [
        Permission.locationWhenInUse,
        Permission.nearbyWifiDevices,
      ].request();
    }

    final networkInfo = NetworkInfo();
    final ip = await networkInfo.getWifiIP();
    if (ip != null && ip.isNotEmpty) {
      return ip;
    }

    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          return address.address;
        }
      }
    }
    return null;
  }

  void _applyActionFromHost(GameAction action) {
    final engine = _engine;
    final currentState = _state;
    if (engine == null || currentState == null) {
      return;
    }
    var nextState = engine.applyAction(currentState, action);
    if (nextState.mode == MatchMode.localCpu) {
      nextState = engine.runAutomatedTurns(nextState);
    }
    _state = nextState;
    _hostService?.broadcastState(nextState);
    _emit();
  }

  Future<void> _clearNetworking({bool keepScreen = false}) async {
    await _clientService?.dispose();
    await _hostService?.dispose();
    _clientService = null;
    _hostService = null;
    if (!keepScreen) {
      _screen = AppScreen.menu;
    }
  }

  void _emit() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_clearNetworking());
    super.dispose();
  }
}
