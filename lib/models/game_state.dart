import 'bank_state.dart';
import 'game_card.dart';
import 'player.dart';
import 'property_card.dart';

enum MatchMode {
  localCpu,
  lanHost,
  lanClient;

  String get value => switch (this) {
        MatchMode.localCpu => 'localCpu',
        MatchMode.lanHost => 'lanHost',
        MatchMode.lanClient => 'lanClient',
      };

  static MatchMode fromValue(String raw) {
    return MatchMode.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => MatchMode.localCpu,
    );
  }
}

enum TurnPhase {
  awaitingRoll,
  postRoll;

  String get value => switch (this) {
        TurnPhase.awaitingRoll => 'awaitingRoll',
        TurnPhase.postRoll => 'postRoll',
      };

  static TurnPhase fromValue(String raw) {
    return TurnPhase.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => TurnPhase.awaitingRoll,
    );
  }
}

class GameSessionState {
  const GameSessionState({
    required this.mode,
    required this.players,
    required this.properties,
    required this.bank,
    required this.turnPhase,
    required this.currentTurnIndex,
    required this.turnNumber,
    required this.lastRoll,
    required this.log,
    required this.solidarityDeck,
    required this.fmiDeck,
    required this.started,
    required this.finished,
    required this.winnerId,
  });

  final MatchMode mode;
  final List<Player> players;
  final List<PropertyCard> properties;
  final BankState bank;
  final TurnPhase turnPhase;
  final int currentTurnIndex;
  final int turnNumber;
  final int? lastRoll;
  final List<String> log;
  final List<GameCard> solidarityDeck;
  final List<GameCard> fmiDeck;
  final bool started;
  final bool finished;
  final String? winnerId;

  Player? get currentPlayer {
    if (players.isEmpty ||
        currentTurnIndex < 0 ||
        currentTurnIndex >= players.length) {
      return null;
    }
    return players[currentTurnIndex];
  }

  Player? playerById(String id) {
    for (final player in players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }

  PropertyCard? propertyAtPosition(int position) {
    for (final property in properties) {
      if (property.matchesPosition(position)) {
        return property;
      }
    }
    return null;
  }

  GameSessionState copyWith({
    MatchMode? mode,
    List<Player>? players,
    List<PropertyCard>? properties,
    BankState? bank,
    TurnPhase? turnPhase,
    int? currentTurnIndex,
    int? turnNumber,
    int? lastRoll,
    bool clearLastRoll = false,
    List<String>? log,
    List<GameCard>? solidarityDeck,
    List<GameCard>? fmiDeck,
    bool? started,
    bool? finished,
    String? winnerId,
    bool clearWinner = false,
  }) {
    return GameSessionState(
      mode: mode ?? this.mode,
      players: players ?? this.players,
      properties: properties ?? this.properties,
      bank: bank ?? this.bank,
      turnPhase: turnPhase ?? this.turnPhase,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      turnNumber: turnNumber ?? this.turnNumber,
      lastRoll: clearLastRoll ? null : lastRoll ?? this.lastRoll,
      log: log ?? this.log,
      solidarityDeck: solidarityDeck ?? this.solidarityDeck,
      fmiDeck: fmiDeck ?? this.fmiDeck,
      started: started ?? this.started,
      finished: finished ?? this.finished,
      winnerId: clearWinner ? null : winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.value,
      'players': players.map((item) => item.toJson()).toList(),
      'properties': properties.map((item) => item.toJson()).toList(),
      'bank': bank.toJson(),
      'turnPhase': turnPhase.value,
      'currentTurnIndex': currentTurnIndex,
      'turnNumber': turnNumber,
      'lastRoll': lastRoll,
      'log': log,
      'solidarityDeck': solidarityDeck.map((item) => item.toJson()).toList(),
      'fmiDeck': fmiDeck.map((item) => item.toJson()).toList(),
      'started': started,
      'finished': finished,
      'winnerId': winnerId,
    };
  }

  factory GameSessionState.fromJson(Map<String, dynamic> json) {
    return GameSessionState(
      mode: MatchMode.fromValue(json['mode'] as String? ?? 'localCpu'),
      players: ((json['players'] as List<dynamic>?) ?? const [])
          .map((item) => Player.fromJson(item as Map<String, dynamic>))
          .toList(),
      properties: ((json['properties'] as List<dynamic>?) ?? const [])
          .map((item) => PropertyCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      bank: BankState.fromJson(
        (json['bank'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      turnPhase: TurnPhase.fromValue(
        json['turnPhase'] as String? ?? 'awaitingRoll',
      ),
      currentTurnIndex: json['currentTurnIndex'] as int? ?? 0,
      turnNumber: json['turnNumber'] as int? ?? 1,
      lastRoll: json['lastRoll'] as int?,
      log: ((json['log'] as List<dynamic>?) ?? const [])
          .map((item) => item as String)
          .toList(),
      solidarityDeck: ((json['solidarityDeck'] as List<dynamic>?) ?? const [])
          .map((item) => GameCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      fmiDeck: ((json['fmiDeck'] as List<dynamic>?) ?? const [])
          .map((item) => GameCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      started: json['started'] as bool? ?? false,
      finished: json['finished'] as bool? ?? false,
      winnerId: json['winnerId'] as String?,
    );
  }
}
