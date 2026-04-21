import '../models/bank_state.dart';
import '../models/game_state.dart';
import '../models/rule_set.dart';

class BankAI {
  const BankAI();

  BankState evaluate(GameSessionState state, RuleSet rules) {
    if (state.players.isEmpty) {
      return state.bank;
    }

    final totalDebt = state.players.fold<int>(
      0,
      (sum, player) => sum + player.debt.principal,
    );
    final debtRatio = totalDebt / (state.players.length * rules.maxDebt);
    final adjustedRate = (rules.baseInterestRate + (debtRatio * 0.08))
        .clamp(0.08, 0.18)
        .toDouble();
    final barrierActive =
        adjustedRate >= 0.16 && state.bank.completedRounds.isOdd;

    return state.bank.copyWith(
      interestRate: adjustedRate,
      tradeBarrierActive: barrierActive,
    );
  }
}
