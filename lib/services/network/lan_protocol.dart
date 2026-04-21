import 'dart:convert';

class LanProtocol {
  static const String hello = 'hello';
  static const String reconnect = 'reconnect';
  static const String joinAck = 'join_ack';
  static const String lobbySync = 'lobby_sync';
  static const String startGame = 'start_game';
  static const String action = 'action';
  static const String stateSync = 'state_sync';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String serverMessage = 'server_message';

  static String encode(Map<String, dynamic> message) {
    return '${jsonEncode(message)}\n';
  }

  static Map<String, dynamic> decode(String raw) {
    final decoded = jsonDecode(raw);
    return (decoded as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}
