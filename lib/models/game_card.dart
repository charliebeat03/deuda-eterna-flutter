enum GameCardType {
  solidarity,
  fmiCondition;

  String get value => switch (this) {
        GameCardType.solidarity => 'solidarity',
        GameCardType.fmiCondition => 'fmiCondition',
      };

  static GameCardType fromValue(String raw) {
    return GameCardType.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => GameCardType.solidarity,
    );
  }
}

class GameCard {
  const GameCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.cashEffect,
    required this.debtEffect,
    required this.goldEffect,
    required this.keepUntilUsed,
  });

  final String id;
  final GameCardType type;
  final String title;
  final String description;
  final int cashEffect;
  final int debtEffect;
  final int goldEffect;
  final bool keepUntilUsed;

  GameCard copyWith({
    String? id,
    GameCardType? type,
    String? title,
    String? description,
    int? cashEffect,
    int? debtEffect,
    int? goldEffect,
    bool? keepUntilUsed,
  }) {
    return GameCard(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      cashEffect: cashEffect ?? this.cashEffect,
      debtEffect: debtEffect ?? this.debtEffect,
      goldEffect: goldEffect ?? this.goldEffect,
      keepUntilUsed: keepUntilUsed ?? this.keepUntilUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'description': description,
      'cashEffect': cashEffect,
      'debtEffect': debtEffect,
      'goldEffect': goldEffect,
      'keepUntilUsed': keepUntilUsed,
    };
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String? ?? '',
      type: GameCardType.fromValue(json['type'] as String? ?? 'solidarity'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cashEffect: json['cashEffect'] as int? ?? 0,
      debtEffect: json['debtEffect'] as int? ?? 0,
      goldEffect: json['goldEffect'] as int? ?? 0,
      keepUntilUsed: json['keepUntilUsed'] as bool? ?? false,
    );
  }
}
