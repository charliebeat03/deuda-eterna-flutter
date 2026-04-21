import 'dart:math';

import '../ai/ai_player.dart';
import '../ai/bank_ai.dart';
import '../models/bank_state.dart';
import '../models/debt.dart';
import '../models/game_action.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/lobby_player.dart';
import '../models/player.dart';
import '../models/property_card.dart';
import '../models/rule_set.dart';

class GameEngine {
  GameEngine({
    required this.rules,
    AIPlayer? aiPlayer,
    BankAI? bankAI,
    Random? random,
  })  : _aiPlayer = aiPlayer ?? const AIPlayer(),
        _bankAI = bankAI ?? const BankAI(),
        _random = random ?? Random();

  final RuleSet rules;
  final AIPlayer _aiPlayer;
  final BankAI _bankAI;
  final Random _random;

  GameSessionState createLocalMatch({
    required String humanName,
    int cpuCount = 2,
  }) {
    final players = <Player>[
      _createPlayer(
        id: 'human-${DateTime.now().millisecondsSinceEpoch}',
        name: humanName,
        type: PlayerType.human,
        isHost: true,
      ),
      for (var index = 0; index < cpuCount; index++)
        _createPlayer(
          id: 'cpu-$index',
          name: 'CPU ${index + 1}',
          type: PlayerType.cpu,
        ),
    ];
    return _createInitialState(players: players, mode: MatchMode.localCpu);
  }

  GameSessionState createLanMatch({
    required List<LobbyPlayer> participants,
    required bool isHost,
  }) {
    final players = participants.map((participant) {
      return _createPlayer(
        id: participant.id,
        name: participant.name,
        type: PlayerType.human,
        isHost: participant.isHost,
        isConnected: participant.isConnected,
      );
    }).toList();
    return _createInitialState(
      players: players,
      mode: isHost ? MatchMode.lanHost : MatchMode.lanClient,
    );
  }

  GameSessionState runAutomatedTurns(GameSessionState state) {
    var next = state;
    while (!next.finished &&
        next.currentPlayer != null &&
        next.currentPlayer!.type == PlayerType.cpu) {
      final cpu = next.currentPlayer!;
      final actions = _aiPlayer.decideTurn(next, rules, cpu);
      for (final action in actions) {
        next = applyAction(next, action);
        if (next.finished || next.currentPlayer?.id != cpu.id) {
          break;
        }
      }
    }
    return next;
  }

  GameSessionState applyAction(GameSessionState state, GameAction action) {
    if (state.finished) {
      return state;
    }

    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null || currentPlayer.id != action.actorId) {
      return state;
    }

    return switch (action.type) {
      GameActionType.requestLoan => _handleLoan(state, currentPlayer, action),
      GameActionType.payDebt => _handlePayDebt(state, currentPlayer, action),
      GameActionType.rollDice => _handleRoll(state, currentPlayer),
      GameActionType.buyProperty =>
        _handleBuyProperty(state, currentPlayer, action),
      GameActionType.buyManufacture =>
        _handleBuyManufacture(state, currentPlayer, action),
      GameActionType.buildIndustry =>
        _handleBuildIndustry(state, currentPlayer, action),
      GameActionType.pirateProperty =>
        _handlePirateProperty(state, currentPlayer, action),
      GameActionType.drawSolidarity =>
        _handleDrawSolidarity(state, currentPlayer),
      GameActionType.resolveFmiCondition =>
        _handleResolveFmiCard(state, currentPlayer),
      GameActionType.endTurn => _handleEndTurn(state, currentPlayer),
    };
  }

  GameSessionState updatePlayerConnection(
    GameSessionState state,
    String playerId,
    bool isConnected,
  ) {
    final players = state.players
        .map(
          (player) => player.id == playerId
              ? player.copyWith(isConnected: isConnected)
              : player,
        )
        .toList();
    return state.copyWith(players: players);
  }

  GameSessionState _createInitialState({
    required List<Player> players,
    required MatchMode mode,
  }) {
    return GameSessionState(
      mode: mode,
      players: players,
      properties:
          rules.properties.map((item) => item.toPropertyCard()).toList(),
      bank: BankState(
        cashReserve: 155000,
        interestRate: rules.baseInterestRate,
        tradeBarrierActive: false,
        completedRounds: 0,
      ),
      turnPhase: TurnPhase.awaitingRoll,
      currentTurnIndex: 0,
      turnNumber: 1,
      lastRoll: null,
      log: <String>[
        'Partida iniciada con reglas base de Deuda Eterna.',
        'Turno inicial para ${players.first.name}.',
      ],
      solidarityDeck: List<GameCard>.from(rules.solidarityCards),
      fmiDeck: List<GameCard>.from(rules.fmiCards),
      started: true,
      finished: false,
      winnerId: null,
    );
  }

  Player _createPlayer({
    required String id,
    required String name,
    required PlayerType type,
    bool isHost = false,
    bool isConnected = true,
  }) {
    final extra = (1 + _random.nextInt(6)) * rules.startCashPerDiePoint;
    return Player(
      id: id,
      name: name,
      type: type,
      cash: rules.startingCash + extra,
      goldReserves: rules.startingGold,
      position: 0,
      debt: Debt.empty,
      ownedPropertyIds: const [],
      devaluationLevel: 0,
      isConnected: isConnected,
      isEliminated: false,
      skipNextInterest: false,
      hasBolivarSword: false,
      worldBankUsed: false,
      underEmbargo: false,
      isHost: isHost,
    );
  }

  GameSessionState _handleLoan(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    if (state.turnPhase != TurnPhase.awaitingRoll || player.underEmbargo) {
      return state;
    }
    final rawAmount = action.payload['amount'] as int? ?? rules.minLoanStep;
    final amount = _normalizeToStep(max(rawAmount, rules.minLoanStep));
    final newPrincipal = player.debt.principal + amount;
    if (newPrincipal > rules.maxDebt) {
      return _appendLog(
        state,
        '${player.name} no puede pedir mas deuda: alcanzaria el limite.',
      );
    }

    final updatedPlayer = _normalizePlayerState(
      player.copyWith(
        cash: player.cash + amount,
        debt: player.debt.copyWith(principal: newPrincipal),
      ),
    );
    return _replacePlayer(
      state.copyWith(
        bank: state.bank.copyWith(cashReserve: state.bank.cashReserve - amount),
      ),
      updatedPlayer,
      '${player.name} recibe un prestamo de \$$amount.',
    );
  }

  GameSessionState _handlePayDebt(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    var amount = action.payload['amount'] as int? ?? rules.minLoanStep;
    amount = _normalizeToStep(max(amount, rules.minLoanStep));
    if (amount <= 0 || player.debt.total <= 0) {
      return state;
    }
    amount = min(amount, _normalizeToStep(player.cash));
    if (amount <= 0) {
      return state;
    }

    var remaining = amount;
    var nextDebt = player.debt;
    if (nextDebt.pendingInterest > 0) {
      final interestPaid = min(remaining, nextDebt.pendingInterest);
      remaining -= interestPaid;
      nextDebt = nextDebt.copyWith(
        pendingInterest: nextDebt.pendingInterest - interestPaid,
      );
    }
    if (remaining > 0) {
      nextDebt = nextDebt.copyWith(
        principal: max(0, nextDebt.principal - remaining),
      );
    }
    if (nextDebt.total == 0) {
      nextDebt = nextDebt.copyWith(interestSettledThisLap: true);
    }

    final updatedPlayer = _normalizePlayerState(
      player.copyWith(
        cash: player.cash - amount,
        debt: nextDebt,
      ),
    );
    return _replacePlayer(
      state.copyWith(
        bank: state.bank.copyWith(cashReserve: state.bank.cashReserve + amount),
      ),
      updatedPlayer,
      '${player.name} paga \$$amount de deuda.',
    );
  }

  GameSessionState _handleRoll(GameSessionState state, Player player) {
    if (state.turnPhase != TurnPhase.awaitingRoll) {
      return state;
    }

    final roll = _rollForPlayer(player);
    final previousPosition = player.position;
    final newPosition = (player.position + roll) % rules.boardLength;
    var nextState = state.copyWith(
      turnPhase: TurnPhase.postRoll,
      lastRoll: roll,
    );
    final movedPlayer = player.copyWith(position: newPosition);
    nextState = _replacePlayer(
      nextState,
      movedPlayer,
      '${player.name} avanza $roll casillas hasta la $newPosition.',
    );

    if (_crossedFmi(previousPosition, roll)) {
      nextState = nextState.copyWith(
        bank: nextState.bank.copyWith(
          completedRounds: nextState.bank.completedRounds + 1,
        ),
      );
      nextState = _settleInterest(nextState, player.id);
    }

    nextState = _resolveBoardSpace(nextState, player.id);
    nextState = _refreshBankDecision(nextState);
    return _checkVictory(nextState);
  }

  GameSessionState _handleBuyProperty(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    if (state.turnPhase != TurnPhase.postRoll) {
      return state;
    }
    final propertyId = action.payload['propertyId'] as String?;
    if (propertyId == null) {
      return state;
    }
    final property = _propertyById(state, propertyId);
    if (property == null ||
        property.ownerId != null ||
        property.southBoardIndex != player.position) {
      return state;
    }

    final nextState = _payBank(
      state,
      playerId: player.id,
      amount: property.purchaseCost,
      allowGold: false,
      allowLoan: true,
      reason: '${player.name} compra ${property.name}.',
    );
    final buyer = nextState.playerById(player.id);
    if (buyer == null || buyer.isEliminated || buyer.cash < 0) {
      return nextState;
    }

    final updatedPlayer = buyer.copyWith(
      ownedPropertyIds: [...buyer.ownedPropertyIds, property.id],
    );
    final updatedProperty = property.copyWith(ownerId: player.id);
    return _replaceProperty(
      _replacePlayer(nextState, updatedPlayer),
      updatedProperty,
    );
  }

  GameSessionState _handleBuyManufacture(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    if (state.turnPhase != TurnPhase.postRoll) {
      return state;
    }
    final propertyId = action.payload['propertyId'] as String?;
    if (propertyId == null) {
      return state;
    }
    final property = _propertyById(state, propertyId);
    if (property == null ||
        property.ownerId != player.id ||
        property.northBoardIndex != player.position ||
        property.nationalIndustries <= 0 ||
        property.hasManufacture) {
      return state;
    }

    final nextState = _payBank(
      state,
      playerId: player.id,
      amount: property.manufacturePurchaseCost,
      allowGold: false,
      allowLoan: true,
      reason:
          '${player.name} compra la manufactura ${property.manufactureName}.',
    );
    final updatedProperty = property.copyWith(hasManufacture: true);
    return _replaceProperty(nextState, updatedProperty);
  }

  GameSessionState _handleBuildIndustry(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    if (state.turnPhase != TurnPhase.awaitingRoll) {
      return state;
    }
    final propertyId = action.payload['propertyId'] as String? ??
        player.ownedPropertyIds.firstOrNull;
    if (propertyId == null) {
      return state;
    }
    final property = _propertyById(state, propertyId);
    if (property == null || property.ownerId != player.id) {
      return state;
    }

    final wantsExport = action.payload['target'] == 'export';
    final canBuildNational =
        property.nationalIndustries < rules.maxNationalIndustries;
    final canBuildExport = property.hasManufacture &&
        property.exportIndustries < rules.maxExportIndustries &&
        property.nationalIndustries > 0;

    final buildExport =
        wantsExport ? canBuildExport : (!canBuildNational && canBuildExport);
    if (!canBuildNational && !canBuildExport) {
      return state;
    }

    final amount =
        buildExport ? property.exportBuildCost : property.industryBuildCost;
    final nextState = _payBank(
      state,
      playerId: player.id,
      amount: amount,
      allowGold: false,
      allowLoan: true,
      reason: '${player.name} invierte en ${property.name}.',
    );
    final updatedProperty = property.copyWith(
      nationalIndustries: buildExport
          ? property.nationalIndustries
          : property.nationalIndustries + 1,
      exportIndustries: buildExport
          ? property.exportIndustries + 1
          : property.exportIndustries,
    );
    return _replaceProperty(nextState, updatedProperty);
  }

  GameSessionState _handlePirateProperty(
    GameSessionState state,
    Player player,
    GameAction action,
  ) {
    if (state.turnPhase != TurnPhase.postRoll) {
      return state;
    }
    final propertyId = action.payload['propertyId'] as String?;
    if (propertyId == null) {
      return state;
    }
    final property = _propertyById(state, propertyId);
    if (property == null ||
        property.southBoardIndex != player.position ||
        property.ownerId == null ||
        property.ownerId == player.id) {
      return state;
    }

    final chainComplete =
        _isChainComplete(state, property.ownerId!, property.group);
    final piracyFee = chainComplete
        ? 6000
        : property.totalIndustries > 0 || property.hasManufacture
            ? 3000
            : 2000;
    final compensation = property.purchaseCost +
        (property.hasManufacture ? property.manufacturePurchaseCost : 0) +
        (property.nationalIndustries * property.industryBuildCost) +
        (property.exportIndustries * property.exportBuildCost);

    var nextState = _payBank(
      state,
      playerId: player.id,
      amount: piracyFee,
      allowGold: false,
      allowLoan: true,
      reason: '${player.name} paga autorización de pirateo.',
    );
    nextState = _payPlayer(
      nextState,
      fromPlayerId: player.id,
      toPlayerId: property.ownerId!,
      amount: compensation,
      allowGold: false,
      allowLoan: true,
      reason: '${player.name} piratea ${property.name}.',
    );

    final pirate = nextState.playerById(player.id);
    final previousOwner = nextState.playerById(property.ownerId!);
    if (pirate == null || previousOwner == null || pirate.isEliminated) {
      return nextState;
    }

    final updatedPirate = pirate.copyWith(
      ownedPropertyIds: [...pirate.ownedPropertyIds, property.id],
    );
    final updatedOwner = previousOwner.copyWith(
      ownedPropertyIds: previousOwner.ownedPropertyIds
          .where((item) => item != property.id)
          .toList(),
    );
    final updatedProperty = property.copyWith(ownerId: pirate.id);
    return _replaceProperty(
      _replacePlayer(
        _replacePlayer(nextState, updatedOwner),
        updatedPirate,
      ),
      updatedProperty,
    );
  }

  GameSessionState _handleDrawSolidarity(
      GameSessionState state, Player player) {
    if (state.turnPhase != TurnPhase.postRoll || state.solidarityDeck.isEmpty) {
      return state;
    }
    if (!rules.isSpecialSpace('solidarity', player.position)) {
      return state;
    }

    final card = state.solidarityDeck.first;
    final rotatedDeck = [...state.solidarityDeck.skip(1), card];
    var updatedPlayer = player.copyWith(
      goldReserves: max(0, player.goldReserves + card.goldEffect),
      debt: player.debt.copyWith(
        principal: max(0, player.debt.principal + card.debtEffect),
      ),
    );
    var nextState = state.copyWith(solidarityDeck: rotatedDeck);
    if (card.cashEffect > 0) {
      updatedPlayer =
          updatedPlayer.copyWith(cash: updatedPlayer.cash + card.cashEffect);
      nextState = nextState.copyWith(
        bank: nextState.bank.copyWith(
          cashReserve: nextState.bank.cashReserve - card.cashEffect,
        ),
      );
    }
    nextState = _replacePlayer(
      nextState,
      _normalizePlayerState(updatedPlayer),
      '${player.name} roba Solidaridad: ${card.title}.',
    );
    return _checkVictory(nextState);
  }

  GameSessionState _handleResolveFmiCard(
      GameSessionState state, Player player) {
    if (state.turnPhase != TurnPhase.postRoll || state.fmiDeck.isEmpty) {
      return state;
    }
    if (!rules.isSpecialSpace('fmiCondition', player.position) ||
        player.debt.principal <= 0) {
      return state;
    }

    final card = state.fmiDeck.first;
    final rotatedDeck = [...state.fmiDeck.skip(1), card];
    var nextState = state.copyWith(fmiDeck: rotatedDeck);
    var updatedPlayer = player.copyWith(
      goldReserves: max(0, player.goldReserves + card.goldEffect),
      debt: player.debt.copyWith(
        principal: max(0, player.debt.principal + card.debtEffect),
      ),
    );
    if (card.cashEffect >= 0) {
      updatedPlayer =
          updatedPlayer.copyWith(cash: updatedPlayer.cash + card.cashEffect);
      nextState = nextState.copyWith(
        bank: nextState.bank.copyWith(
          cashReserve: nextState.bank.cashReserve - card.cashEffect,
        ),
      );
    } else {
      nextState = _payBank(
        nextState,
        playerId: player.id,
        amount: -card.cashEffect,
        allowGold: true,
        allowLoan: true,
        reason: '${player.name} resuelve carta FMI: ${card.title}.',
      );
      updatedPlayer = nextState.playerById(player.id) ?? updatedPlayer;
    }
    return _replacePlayer(
      nextState,
      _normalizePlayerState(updatedPlayer),
      '${player.name} resuelve carta FMI: ${card.title}.',
    );
  }

  GameSessionState _handleEndTurn(GameSessionState state, Player player) {
    if (state.turnPhase != TurnPhase.postRoll) {
      return state;
    }
    final nextIndex = _findNextTurnIndex(state.players, state.currentTurnIndex);
    final nextTurnNumber = nextIndex <= state.currentTurnIndex
        ? state.turnNumber + 1
        : state.turnNumber;
    final nextState = state.copyWith(
      currentTurnIndex: nextIndex,
      turnNumber: nextTurnNumber,
      turnPhase: TurnPhase.awaitingRoll,
      clearLastRoll: true,
    );
    return _appendLog(
      _checkVictory(nextState),
      'Comienza el turno de ${nextState.currentPlayer?.name ?? 'nadie'}.',
    );
  }

  GameSessionState _resolveBoardSpace(GameSessionState state, String playerId) {
    final player = state.playerById(playerId);
    if (player == null) {
      return state;
    }

    final property = state.propertyAtPosition(player.position);
    if (property != null) {
      return _resolvePropertySpace(state, player, property);
    }

    if (rules.isSpecialSpace('solidarity', player.position)) {
      return _appendLog(
          state, '${player.name} puede robar una carta de Solidaridad.');
    }
    if (rules.isSpecialSpace('fmiCondition', player.position) &&
        player.debt.principal > 0) {
      return _appendLog(
          state, '${player.name} puede resolver una Condición FMI.');
    }
    if (rules.isSpecialSpace('cooperation', player.position)) {
      return _grantCooperation(state, player);
    }
    if (rules.isSpecialSpace('capitalFlight', player.position)) {
      final penalty = (_random.nextInt(6) + 1) * 1000;
      return _payBank(
        state,
        playerId: player.id,
        amount: penalty,
        allowGold: true,
        allowLoan: true,
        reason: '${player.name} sufre fuga de capitales.',
      );
    }
    if (rules.isSpecialSpace('militaryCoup', player.position)) {
      return _payBank(
        state,
        playerId: player.id,
        amount: player.cash,
        allowGold: false,
        allowLoan: false,
        reason: '${player.name} sufre golpe militar.',
      );
    }
    if (rules.isSpecialSpace('tradeBarrier', player.position)) {
      return _appendLog(
        state.copyWith(
          bank: state.bank.copyWith(
            tradeBarrierActive: !state.bank.tradeBarrierActive,
          ),
        ),
        state.bank.tradeBarrierActive
            ? 'Se retira la barrera proteccionista.'
            : 'El FMI activa la barrera proteccionista.',
      );
    }
    if (rules.isSpecialSpace('nationalization', player.position)) {
      return _grantNationalization(state, player);
    }
    if (rules.isSpecialSpace('october1492', player.position)) {
      if (player.goldReserves <= 0) {
        return _appendLog(state,
            '${player.name} cae en 12 de Octubre, pero ya no tiene oro.');
      }
      return _replacePlayer(
        state,
        player.copyWith(goldReserves: player.goldReserves - 1),
        '${player.name} pierde una reserva de oro en 12 de Octubre de 1492.',
      );
    }
    if (rules.isSpecialSpace('worldBank', player.position)) {
      if (player.worldBankUsed) {
        return _appendLog(
            state, '${player.name} ya aprovechó la ayuda del Banco Mundial.');
      }
      return _replacePlayer(
        state.copyWith(
          bank:
              state.bank.copyWith(cashReserve: state.bank.cashReserve - 10000),
        ),
        player.copyWith(
          cash: player.cash + 10000,
          worldBankUsed: true,
        ),
        '${player.name} recibe \$10000 del Banco Mundial.',
      );
    }
    if (rules.isSpecialSpace('noPay', player.position)) {
      var nextState = state;
      if (!state.players.any((item) => item.hasBolivarSword)) {
        nextState = _transferBolivarSword(nextState, player.id);
        nextState = _appendLog(
            nextState, '${player.name} obtiene la espada de Simón Bolívar.');
      }
      return _replacePlayer(
        nextState,
        player.copyWith(skipNextInterest: true),
        '${player.name} no pagará intereses en la próxima vuelta.',
      );
    }

    return state;
  }

  GameSessionState _resolvePropertySpace(
    GameSessionState state,
    Player player,
    PropertyCard property,
  ) {
    final isSouth = property.southBoardIndex == player.position;
    if (isSouth) {
      if (property.ownerId == null) {
        return _appendLog(
          state,
          '${player.name} puede comprar ${property.name} en el Sur.',
        );
      }
      if (property.ownerId == player.id) {
        return _appendLog(
          state,
          '${player.name} cae en su propia materia prima ${property.name}.',
        );
      }
      final ownerId = property.ownerId!;
      final rent = _isChainComplete(state, ownerId, property.group)
          ? property.southBaseIncome *
              _chainIndustryCount(state, ownerId, property.group)
          : property.southBaseIncome * property.nationalIndustries;
      if (rent <= 0) {
        return _appendLog(
          state,
          '${player.name} cae en ${property.name}, pero no hay industrias que cobrar.',
        );
      }
      return _payPlayer(
        state,
        fromPlayerId: player.id,
        toPlayerId: ownerId,
        amount: rent,
        allowGold: true,
        allowLoan: true,
        reason: '${player.name} paga renta por ${property.name}.',
      );
    }

    if (property.ownerId == null) {
      return _payBank(
        state,
        playerId: player.id,
        amount: property.northBaseIncome,
        allowGold: true,
        allowLoan: true,
        reason:
            '${player.name} importa ${property.manufactureName} desde el Norte.',
      );
    }

    if (property.ownerId == player.id) {
      if (!property.hasManufacture && property.nationalIndustries > 0) {
        return _appendLog(
          state,
          '${player.name} puede comprar ${property.manufactureName} en el Norte.',
        );
      }
      if (property.hasManufacture && property.exportIndustries > 0) {
        if (state.bank.tradeBarrierActive) {
          return _appendLog(
            state,
            '${player.name} cae en su manufactura, pero la barrera proteccionista bloquea el cobro.',
          );
        }
        final income = _isChainComplete(state, player.id, property.group)
            ? property.northBaseIncome *
                _chainIndustryCount(state, player.id, property.group)
            : property.northBaseIncome * property.exportIndustries;
        final updatedPlayer = player.copyWith(cash: player.cash + income);
        return _replacePlayer(
          state.copyWith(
            bank: state.bank
                .copyWith(cashReserve: state.bank.cashReserve - income),
          ),
          updatedPlayer,
          '${player.name} exporta ${property.manufactureName} y cobra \$$income.',
        );
      }
      return _appendLog(
        state,
        '${player.name} cae en su manufactura ${property.manufactureName}.',
      );
    }

    if (property.hasManufacture && property.exportIndustries > 0) {
      if (state.bank.tradeBarrierActive) {
        return _payBank(
          state,
          playerId: player.id,
          amount: property.northBaseIncome,
          allowGold: true,
          allowLoan: true,
          reason: '${player.name} paga al FMI por la barrera proteccionista.',
        );
      }
      final ownerId = property.ownerId!;
      final rent = _isChainComplete(state, ownerId, property.group)
          ? property.northBaseIncome *
              _chainIndustryCount(state, ownerId, property.group)
          : property.northBaseIncome * property.exportIndustries;
      return _payPlayer(
        state,
        fromPlayerId: player.id,
        toPlayerId: ownerId,
        amount: rent,
        allowGold: true,
        allowLoan: true,
        reason: '${player.name} paga manufactura ${property.manufactureName}.',
      );
    }

    return _payBank(
      state,
      playerId: player.id,
      amount: property.northBaseIncome,
      allowGold: true,
      allowLoan: true,
      reason:
          '${player.name} paga importación de ${property.manufactureName} al FMI.',
    );
  }

  GameSessionState _grantCooperation(GameSessionState state, Player player) {
    final freeProperty =
        state.properties.where((item) => item.ownerId == null).firstOrNull;
    if (freeProperty != null) {
      final updatedPlayer = player.copyWith(
        ownedPropertyIds: [...player.ownedPropertyIds, freeProperty.id],
      );
      final updatedProperty = freeProperty.copyWith(ownerId: player.id);
      return _replaceProperty(
        _replacePlayer(
          state,
          updatedPlayer,
          '${player.name} recibe ${freeProperty.name} por cooperación internacional.',
        ),
        updatedProperty,
      );
    }

    final buildCandidate = state.properties
        .where((item) => item.ownerId == player.id)
        .where((item) =>
            item.nationalIndustries < rules.maxNationalIndustries ||
            (item.hasManufacture &&
                item.exportIndustries < rules.maxExportIndustries))
        .firstOrNull;
    if (buildCandidate == null) {
      return _appendLog(state,
          '${player.name} no tiene objetivo para cooperación internacional.');
    }
    final updatedProperty =
        buildCandidate.nationalIndustries < rules.maxNationalIndustries
            ? buildCandidate.copyWith(
                nationalIndustries: buildCandidate.nationalIndustries + 1)
            : buildCandidate.copyWith(
                exportIndustries: buildCandidate.exportIndustries + 1);
    return _replaceProperty(
      state,
      updatedProperty,
    );
  }

  GameSessionState _grantNationalization(
      GameSessionState state, Player player) {
    final freeProperty =
        state.properties.where((item) => item.ownerId == null).firstOrNull;
    if (freeProperty != null) {
      final updatedPlayer = player.copyWith(
        ownedPropertyIds: [...player.ownedPropertyIds, freeProperty.id],
      );
      final updatedProperty = freeProperty.copyWith(
        ownerId: player.id,
        nationalIndustries: 1,
      );
      return _replaceProperty(
        _replacePlayer(
          state,
          updatedPlayer,
          '${player.name} nacionaliza ${freeProperty.name} con una industria inicial.',
        ),
        updatedProperty,
      );
    }

    final ownProperty = state.properties
        .where((item) => item.ownerId == player.id)
        .where((item) =>
            item.nationalIndustries < rules.maxNationalIndustries ||
            (item.hasManufacture &&
                item.exportIndustries < rules.maxExportIndustries))
        .firstOrNull;
    if (ownProperty == null) {
      return _appendLog(
          state, '${player.name} no tiene espacio para nacionalizar.');
    }
    final updatedProperty =
        ownProperty.nationalIndustries < rules.maxNationalIndustries
            ? ownProperty.copyWith(
                nationalIndustries: ownProperty.nationalIndustries + 1)
            : ownProperty.copyWith(
                exportIndustries: ownProperty.exportIndustries + 1);
    return _replaceProperty(
      state,
      updatedProperty,
    );
  }

  GameSessionState _settleInterest(GameSessionState state, String playerId) {
    final player = state.playerById(playerId);
    if (player == null || player.debt.principal <= 0) {
      return state;
    }
    if (player.skipNextInterest) {
      return _replacePlayer(
        state,
        player.copyWith(skipNextInterest: false),
        '${player.name} pasa por el FMI sin pagar intereses gracias a No Pagar.',
      );
    }

    final amount = max(
      50,
      ((player.debt.principal * rules.baseInterestRate).round() ~/ 50) * 50,
    );
    return _payBank(
      state,
      playerId: player.id,
      amount: amount,
      allowGold: true,
      allowLoan: true,
      reason: '${player.name} paga intereses al FMI.',
    );
  }

  GameSessionState _payBank(
    GameSessionState state, {
    required String playerId,
    required int amount,
    required bool allowGold,
    required bool allowLoan,
    required String reason,
  }) {
    return _applyPayment(
      state,
      fromPlayerId: playerId,
      toPlayerId: null,
      amount: amount,
      allowGold: allowGold,
      allowLoan: allowLoan,
      reason: reason,
    );
  }

  GameSessionState _payPlayer(
    GameSessionState state, {
    required String fromPlayerId,
    required String toPlayerId,
    required int amount,
    required bool allowGold,
    required bool allowLoan,
    required String reason,
  }) {
    return _applyPayment(
      state,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      amount: amount,
      allowGold: allowGold,
      allowLoan: allowLoan,
      reason: reason,
    );
  }

  GameSessionState _applyPayment(
    GameSessionState state, {
    required String fromPlayerId,
    required String? toPlayerId,
    required int amount,
    required bool allowGold,
    required bool allowLoan,
    required String reason,
  }) {
    if (amount <= 0) {
      return state;
    }

    var nextState = state;
    while (true) {
      final payer = nextState.playerById(fromPlayerId);
      if (payer == null || payer.isEliminated) {
        return nextState;
      }
      if (payer.cash >= amount) {
        final updatedPayer = _normalizePlayerState(
          payer.copyWith(cash: payer.cash - amount),
        );
        nextState = _replacePlayer(nextState, updatedPayer);
        if (toPlayerId == null) {
          nextState = nextState.copyWith(
            bank: nextState.bank.copyWith(
              cashReserve: nextState.bank.cashReserve + amount,
            ),
          );
        } else {
          final payee = nextState.playerById(toPlayerId);
          if (payee != null) {
            nextState = _replacePlayer(
              nextState,
              payee.copyWith(cash: payee.cash + amount),
            );
          }
        }
        return _appendLog(nextState, '$reason Pago: \$$amount.');
      }

      if (allowGold && payer.goldReserves > 0) {
        final updatedPayer = _normalizePlayerState(
          payer.copyWith(goldReserves: payer.goldReserves - 1),
        );
        return _replacePlayer(
          nextState,
          updatedPayer,
          '$reason ${payer.name} usa una reserva de oro.',
        );
      }

      if (allowLoan && !payer.underEmbargo) {
        final needed = _normalizeToStep(amount - payer.cash);
        if (needed > 0 && payer.debt.principal + needed <= rules.maxDebt) {
          final refinanced = _normalizePlayerState(
            payer.copyWith(
              cash: payer.cash + needed,
              debt:
                  payer.debt.copyWith(principal: payer.debt.principal + needed),
            ),
          );
          nextState = _replacePlayer(
            nextState.copyWith(
              bank: nextState.bank.copyWith(
                cashReserve: nextState.bank.cashReserve - needed,
              ),
            ),
            refinanced,
            '${payer.name} toma \$$needed para cubrir una obligación.',
          );
          continue;
        }
      }

      if (payer.ownedPropertyIds.isNotEmpty) {
        nextState = _embargoMostValuableProperty(nextState, payer.id);
        final afterEmbargo = nextState.playerById(payer.id);
        if (afterEmbargo == null ||
            afterEmbargo.ownedPropertyIds.length ==
                payer.ownedPropertyIds.length) {
          break;
        }
        continue;
      }

      final eliminated = _normalizePlayerState(
        payer.copyWith(
          cash: 0,
          isEliminated: true,
          underEmbargo: true,
        ),
      );
      nextState = _replacePlayer(
        nextState,
        eliminated,
        '${payer.name} quiebra al no poder cubrir un pago.',
      );
      return _checkVictory(nextState);
    }

    return nextState;
  }

  GameSessionState _embargoMostValuableProperty(
    GameSessionState state,
    String playerId,
  ) {
    final player = state.playerById(playerId);
    if (player == null || player.ownedPropertyIds.isEmpty) {
      return state;
    }
    final property = state.properties
        .where((item) => item.ownerId == player.id)
        .toList()
      ..sort((a, b) => _assetValue(b).compareTo(_assetValue(a)));
    if (property.isEmpty) {
      return state;
    }
    final seized = property.first;
    final recovered = max(500, _assetValue(seized) ~/ 2);
    final updatedPlayer = _normalizePlayerState(
      player.copyWith(
        cash: player.cash + recovered,
        ownedPropertyIds:
            player.ownedPropertyIds.where((item) => item != seized.id).toList(),
        underEmbargo: true,
      ),
    );
    final resetProperty = seized.copyWith(
      clearOwner: true,
      hasManufacture: false,
      nationalIndustries: 0,
      exportIndustries: 0,
    );
    return _replaceProperty(
      _replacePlayer(
        state,
        updatedPlayer,
        'El FMI embarga ${seized.name} a ${player.name} y recupera \$$recovered.',
      ),
      resetProperty,
    );
  }

  int _assetValue(PropertyCard property) {
    return property.purchaseCost +
        (property.hasManufacture ? property.manufacturePurchaseCost : 0) +
        (property.nationalIndustries * property.industryBuildCost) +
        (property.exportIndustries * property.exportBuildCost);
  }

  GameSessionState _refreshBankDecision(GameSessionState state) {
    return state.copyWith(bank: _bankAI.evaluate(state, rules));
  }

  GameSessionState _replacePlayer(
    GameSessionState state,
    Player updatedPlayer, [
    String? logEntry,
  ]) {
    final players = state.players
        .map((player) => player.id == updatedPlayer.id ? updatedPlayer : player)
        .toList();
    var nextState = state.copyWith(players: players);
    if (logEntry != null) {
      nextState = _appendLog(nextState, logEntry);
    }
    return nextState;
  }

  GameSessionState _replaceProperty(
    GameSessionState state,
    PropertyCard updatedProperty,
  ) {
    final properties = state.properties
        .map((property) =>
            property.id == updatedProperty.id ? updatedProperty : property)
        .toList();
    return state.copyWith(properties: properties);
  }

  GameSessionState _appendLog(GameSessionState state, String entry) {
    final nextLog = [...state.log, entry];
    if (nextLog.length > 50) {
      nextLog.removeRange(0, nextLog.length - 50);
    }
    return state.copyWith(log: nextLog);
  }

  GameSessionState _transferBolivarSword(
      GameSessionState state, String playerId) {
    var nextState = state;
    for (final player in state.players.where((item) => item.hasBolivarSword)) {
      nextState =
          _replacePlayer(nextState, player.copyWith(hasBolivarSword: false));
    }
    final nextOwner = nextState.playerById(playerId);
    if (nextOwner == null) {
      return nextState;
    }
    return _replacePlayer(nextState, nextOwner.copyWith(hasBolivarSword: true));
  }

  GameSessionState _checkVictory(GameSessionState state) {
    final activePlayers =
        state.players.where((item) => !item.isEliminated).toList();
    if (activePlayers.length <= 1 && state.started) {
      return state.copyWith(
        finished: true,
        winnerId: activePlayers.isEmpty ? null : activePlayers.first.id,
      );
    }

    for (final player in activePlayers) {
      final ownsAll =
          state.properties.every((item) => item.ownerId == player.id);
      final industrialized = state.properties.every(
        (item) =>
            item.ownerId == player.id &&
            item.nationalIndustries >= rules.maxNationalIndustries &&
            item.hasManufacture &&
            item.exportIndustries >= rules.maxExportIndustries,
      );
      if (ownsAll && industrialized) {
        return state.copyWith(finished: true, winnerId: player.id);
      }
    }
    return state;
  }

  bool _crossedFmi(int previousPosition, int roll) {
    return previousPosition + roll >= (rules.specialSpaces['fmi']?.first ?? 39);
  }

  bool _isChainComplete(GameSessionState state, String ownerId, String group) {
    if (group == 'petroleo') {
      return false;
    }
    final groupProperties =
        state.properties.where((item) => item.group == group).toList();
    if (groupProperties.length < 2) {
      return false;
    }
    return groupProperties.every(
      (item) =>
          item.ownerId == ownerId &&
          item.nationalIndustries > 0 &&
          item.hasManufacture &&
          item.exportIndustries > 0,
    );
  }

  int _chainIndustryCount(
      GameSessionState state, String ownerId, String group) {
    return state.properties
        .where((item) => item.group == group && item.ownerId == ownerId)
        .fold<int>(0, (sum, item) => sum + item.totalIndustries);
  }

  PropertyCard? _propertyById(GameSessionState state, String propertyId) {
    for (final property in state.properties) {
      if (property.id == propertyId) {
        return property;
      }
    }
    return null;
  }

  Player _normalizePlayerState(Player player) {
    var level = 0;
    if (rules.devaluationThresholds.isNotEmpty &&
        player.debt.principal >= rules.devaluationThresholds.first) {
      level = 1;
    }
    if (rules.devaluationThresholds.length > 1 &&
        player.debt.principal >= rules.devaluationThresholds[1]) {
      level = 2;
    }
    return player.copyWith(
      devaluationLevel: level,
      underEmbargo:
          player.underEmbargo || player.debt.principal >= rules.maxDebt,
    );
  }

  int _rollForPlayer(Player player) {
    final rolls = switch (player.devaluationLevel) {
      0 => [_random.nextInt(6) + 1, _random.nextInt(6) + 1],
      1 => [
          _random.nextInt(6) + 1,
          _random.nextInt(6) + 1,
          _random.nextInt(6) + 1,
        ],
      _ => [
          _random.nextInt(6) + 1,
          _random.nextInt(6) + 1,
          _random.nextInt(6) + 1,
          _random.nextInt(6) + 1,
        ],
    };
    return rolls.fold<int>(0, (sum, die) => sum + die);
  }

  int _normalizeToStep(int amount) {
    if (amount <= 0) {
      return 0;
    }
    return ((amount + rules.minLoanStep - 1) ~/ rules.minLoanStep) *
        rules.minLoanStep;
  }

  int _findNextTurnIndex(List<Player> players, int currentTurnIndex) {
    if (players.isEmpty) {
      return 0;
    }
    var index = currentTurnIndex;
    for (var tries = 0; tries < players.length; tries++) {
      index = (index + 1) % players.length;
      if (!players[index].isEliminated) {
        return index;
      }
    }
    return currentTurnIndex;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
