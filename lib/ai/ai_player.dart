import '../models/game_action.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/rule_set.dart';

class AIPlayer {
  const AIPlayer();

  List<GameAction> decideTurn(
    GameSessionState state,
    RuleSet rules,
    Player player,
  ) {
    final actions = <GameAction>[];
    if (state.turnPhase == TurnPhase.awaitingRoll) {
      final buildCandidate = state.properties
          .where((item) => item.ownerId == player.id)
          .where((item) {
        final canBuildNational =
            item.nationalIndustries < rules.maxNationalIndustries &&
                player.cash >= item.industryBuildCost;
        final canBuildExport = item.hasManufacture &&
            item.exportIndustries < rules.maxExportIndustries &&
            player.cash >= item.exportBuildCost;
        return canBuildNational || canBuildExport;
      }).toList()
        ..sort((a, b) => a.purchaseCost.compareTo(b.purchaseCost));

      if (player.debt.principal >= rules.minLoanStep &&
          player.cash > rules.minLoanStep * 3) {
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.payDebt,
            payload: {'amount': rules.minLoanStep},
          ),
        );
      } else if (player.cash < 1500 &&
          player.debt.principal <= rules.maxDebt - rules.minLoanStep &&
          !player.underEmbargo) {
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.requestLoan,
            payload: {'amount': rules.minLoanStep},
          ),
        );
      } else if (buildCandidate.isNotEmpty) {
        final property = buildCandidate.first;
        final buildExport = property.hasManufacture &&
            property.nationalIndustries >= rules.maxNationalIndustries &&
            property.exportIndustries < rules.maxExportIndustries;
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.buildIndustry,
            payload: {
              'propertyId': property.id,
              'target': buildExport ? 'export' : 'national',
            },
          ),
        );
      }

      actions
          .add(GameAction(actorId: player.id, type: GameActionType.rollDice));
      return actions;
    }

    final landedProperty = state.propertyAtPosition(player.position);
    if (landedProperty != null) {
      if (landedProperty.southBoardIndex == player.position &&
          landedProperty.ownerId == null &&
          player.cash >= landedProperty.purchaseCost) {
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.buyProperty,
            payload: {'propertyId': landedProperty.id},
          ),
        );
      } else if (landedProperty.northBoardIndex == player.position &&
          landedProperty.ownerId == player.id &&
          landedProperty.nationalIndustries > 0 &&
          !landedProperty.hasManufacture &&
          player.cash >= landedProperty.manufacturePurchaseCost) {
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.buyManufacture,
            payload: {'propertyId': landedProperty.id},
          ),
        );
      } else if (landedProperty.southBoardIndex == player.position &&
          landedProperty.ownerId != null &&
          landedProperty.ownerId != player.id &&
          player.cash >= 5000 &&
          player.debt.principal < rules.maxDebt * 0.75) {
        actions.add(
          GameAction(
            actorId: player.id,
            type: GameActionType.pirateProperty,
            payload: {'propertyId': landedProperty.id},
          ),
        );
      }
    } else if (rules.isSpecialSpace('solidarity', player.position)) {
      actions.add(
        GameAction(actorId: player.id, type: GameActionType.drawSolidarity),
      );
    } else if (rules.isSpecialSpace('fmiCondition', player.position) &&
        player.debt.principal > 0) {
      actions.add(
        GameAction(
            actorId: player.id, type: GameActionType.resolveFmiCondition),
      );
    }

    actions.add(GameAction(actorId: player.id, type: GameActionType.endTurn));
    return actions;
  }
}
