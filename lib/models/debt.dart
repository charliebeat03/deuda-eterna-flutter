class Debt {
  const Debt({
    required this.creditorId,
    required this.principal,
    required this.pendingInterest,
    required this.interestSettledThisLap,
  });

  final String creditorId;
  final int principal;
  final int pendingInterest;
  final bool interestSettledThisLap;

  static const Debt empty = Debt(
    creditorId: 'bank',
    principal: 0,
    pendingInterest: 0,
    interestSettledThisLap: true,
  );

  int get total => principal + pendingInterest;

  Debt copyWith({
    String? creditorId,
    int? principal,
    int? pendingInterest,
    bool? interestSettledThisLap,
  }) {
    return Debt(
      creditorId: creditorId ?? this.creditorId,
      principal: principal ?? this.principal,
      pendingInterest: pendingInterest ?? this.pendingInterest,
      interestSettledThisLap:
          interestSettledThisLap ?? this.interestSettledThisLap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creditorId': creditorId,
      'principal': principal,
      'pendingInterest': pendingInterest,
      'interestSettledThisLap': interestSettledThisLap,
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      creditorId: json['creditorId'] as String? ?? 'bank',
      principal: json['principal'] as int? ?? 0,
      pendingInterest: json['pendingInterest'] as int? ?? 0,
      interestSettledThisLap: json['interestSettledThisLap'] as bool? ?? true,
    );
  }
}
