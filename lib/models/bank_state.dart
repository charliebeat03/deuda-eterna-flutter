class BankState {
  const BankState({
    required this.cashReserve,
    required this.interestRate,
    required this.tradeBarrierActive,
    required this.completedRounds,
  });

  final int cashReserve;
  final double interestRate;
  final bool tradeBarrierActive;
  final int completedRounds;

  BankState copyWith({
    int? cashReserve,
    double? interestRate,
    bool? tradeBarrierActive,
    int? completedRounds,
  }) {
    return BankState(
      cashReserve: cashReserve ?? this.cashReserve,
      interestRate: interestRate ?? this.interestRate,
      tradeBarrierActive: tradeBarrierActive ?? this.tradeBarrierActive,
      completedRounds: completedRounds ?? this.completedRounds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashReserve': cashReserve,
      'interestRate': interestRate,
      'tradeBarrierActive': tradeBarrierActive,
      'completedRounds': completedRounds,
    };
  }

  factory BankState.fromJson(Map<String, dynamic> json) {
    return BankState(
      cashReserve: json['cashReserve'] as int? ?? 0,
      interestRate: (json['interestRate'] as num? ?? 0.1).toDouble(),
      tradeBarrierActive: json['tradeBarrierActive'] as bool? ?? false,
      completedRounds: json['completedRounds'] as int? ?? 0,
    );
  }
}
