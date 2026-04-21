enum GameActionType {
  requestLoan,
  payDebt,
  rollDice,
  buyProperty,
  buyManufacture,
  buildIndustry,
  pirateProperty,
  drawSolidarity,
  resolveFmiCondition,
  endTurn;

  String get value => switch (this) {
        GameActionType.requestLoan => 'requestLoan',
        GameActionType.payDebt => 'payDebt',
        GameActionType.rollDice => 'rollDice',
        GameActionType.buyProperty => 'buyProperty',
        GameActionType.buyManufacture => 'buyManufacture',
        GameActionType.buildIndustry => 'buildIndustry',
        GameActionType.pirateProperty => 'pirateProperty',
        GameActionType.drawSolidarity => 'drawSolidarity',
        GameActionType.resolveFmiCondition => 'resolveFmiCondition',
        GameActionType.endTurn => 'endTurn',
      };

  static GameActionType fromValue(String raw) {
    return GameActionType.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => GameActionType.endTurn,
    );
  }
}

class GameAction {
  const GameAction({
    required this.actorId,
    required this.type,
    this.payload = const {},
    int? sentAtEpochMs,
  }) : sentAtEpochMs = sentAtEpochMs ?? 0;

  final String actorId;
  final GameActionType type;
  final Map<String, dynamic> payload;
  final int sentAtEpochMs;

  Map<String, dynamic> toJson() {
    return {
      'actorId': actorId,
      'type': type.value,
      'payload': payload,
      'sentAtEpochMs': sentAtEpochMs,
    };
  }

  factory GameAction.fromJson(Map<String, dynamic> json) {
    return GameAction(
      actorId: json['actorId'] as String? ?? '',
      type: GameActionType.fromValue(json['type'] as String? ?? 'endTurn'),
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      sentAtEpochMs: json['sentAtEpochMs'] as int? ?? 0,
    );
  }
}
