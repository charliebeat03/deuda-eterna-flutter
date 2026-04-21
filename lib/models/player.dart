import 'debt.dart';

enum PlayerType {
  human,
  cpu;

  String get value => switch (this) {
        PlayerType.human => 'human',
        PlayerType.cpu => 'cpu',
      };

  static PlayerType fromValue(String raw) {
    return PlayerType.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => PlayerType.human,
    );
  }
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.type,
    required this.cash,
    required this.goldReserves,
    required this.position,
    required this.debt,
    required this.ownedPropertyIds,
    required this.devaluationLevel,
    required this.isConnected,
    required this.isEliminated,
    required this.skipNextInterest,
    required this.hasBolivarSword,
    required this.worldBankUsed,
    required this.underEmbargo,
    this.isHost = false,
  });

  final String id;
  final String name;
  final PlayerType type;
  final int cash;
  final int goldReserves;
  final int position;
  final Debt debt;
  final List<String> ownedPropertyIds;
  final int devaluationLevel;
  final bool isConnected;
  final bool isEliminated;
  final bool skipNextInterest;
  final bool hasBolivarSword;
  final bool worldBankUsed;
  final bool underEmbargo;
  final bool isHost;

  Player copyWith({
    String? id,
    String? name,
    PlayerType? type,
    int? cash,
    int? goldReserves,
    int? position,
    Debt? debt,
    List<String>? ownedPropertyIds,
    int? devaluationLevel,
    bool? isConnected,
    bool? isEliminated,
    bool? skipNextInterest,
    bool? hasBolivarSword,
    bool? worldBankUsed,
    bool? underEmbargo,
    bool? isHost,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      cash: cash ?? this.cash,
      goldReserves: goldReserves ?? this.goldReserves,
      position: position ?? this.position,
      debt: debt ?? this.debt,
      ownedPropertyIds: ownedPropertyIds ?? this.ownedPropertyIds,
      devaluationLevel: devaluationLevel ?? this.devaluationLevel,
      isConnected: isConnected ?? this.isConnected,
      isEliminated: isEliminated ?? this.isEliminated,
      skipNextInterest: skipNextInterest ?? this.skipNextInterest,
      hasBolivarSword: hasBolivarSword ?? this.hasBolivarSword,
      worldBankUsed: worldBankUsed ?? this.worldBankUsed,
      underEmbargo: underEmbargo ?? this.underEmbargo,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'cash': cash,
      'goldReserves': goldReserves,
      'position': position,
      'debt': debt.toJson(),
      'ownedPropertyIds': ownedPropertyIds,
      'devaluationLevel': devaluationLevel,
      'isConnected': isConnected,
      'isEliminated': isEliminated,
      'skipNextInterest': skipNextInterest,
      'hasBolivarSword': hasBolivarSword,
      'worldBankUsed': worldBankUsed,
      'underEmbargo': underEmbargo,
      'isHost': isHost,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: PlayerType.fromValue(json['type'] as String? ?? 'human'),
      cash: json['cash'] as int? ?? 0,
      goldReserves: json['goldReserves'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      debt: Debt.fromJson(
        (json['debt'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      ownedPropertyIds:
          ((json['ownedPropertyIds'] as List<dynamic>?) ?? const [])
              .map((item) => item as String)
              .toList(),
      devaluationLevel: json['devaluationLevel'] as int? ?? 0,
      isConnected: json['isConnected'] as bool? ?? true,
      isEliminated: json['isEliminated'] as bool? ?? false,
      skipNextInterest: json['skipNextInterest'] as bool? ?? false,
      hasBolivarSword: json['hasBolivarSword'] as bool? ?? false,
      worldBankUsed: json['worldBankUsed'] as bool? ?? false,
      underEmbargo: json['underEmbargo'] as bool? ?? false,
      isHost: json['isHost'] as bool? ?? false,
    );
  }
}
