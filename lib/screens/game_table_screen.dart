import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../models/game_action.dart';
import '../models/player.dart';
import '../widgets/action_bar.dart';
import '../widgets/player_panel.dart';

class GameTableScreen extends StatefulWidget {
  const GameTableScreen({super.key});

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  String? _selectedPropertyId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final state = controller.state;
    if (state == null) {
      return const Scaffold(body: Center(child: Text('Sin partida activa')));
    }

    final currentPlayer = state.currentPlayer;
    final localPlayer = state.players
        .where((item) => item.id == controller.localPlayerId)
        .firstOrNull;
    final canAct = currentPlayer != null &&
        controller.localPlayerId == currentPlayer.id &&
        !state.finished &&
        currentPlayer.type == PlayerType.human;
    final landedProperty = currentPlayer == null
        ? null
        : state.propertyAtPosition(currentPlayer.position);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa - Turno ${state.turnNumber}'),
        actions: [
          TextButton(
            onPressed: controller.returnToMenu,
            child: const Text('Salir'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    Text(
                        'Interés FMI: ${(state.bank.interestRate * 100).toStringAsFixed(1)}%'),
                    Text(
                      state.bank.tradeBarrierActive
                          ? 'Barrera: activa'
                          : 'Barrera: inactiva',
                    ),
                    Text('Último roll: ${state.lastRoll ?? '-'}'),
                    if (controller.rules != null)
                      Text('Casillas: ${controller.rules!.boardLength}'),
                    if (currentPlayer != null)
                      Text('Jugador actual: ${currentPlayer.name}'),
                    if (controller.statusMessage != null)
                      Text(controller.statusMessage!),
                    if (state.finished)
                      Text(
                        'Ganador: ${state.playerById(state.winnerId ?? '')?.name ?? 'Sin ganador'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ListView(
                      children: [
                        ActionBar(
                          canAct: canAct,
                          onRequestLoan: () => _requestAmountAction(
                            context,
                            'Monto del préstamo',
                            GameActionType.requestLoan,
                          ),
                          onPayDebt: () => _requestAmountAction(
                            context,
                            'Monto a pagar',
                            GameActionType.payDebt,
                          ),
                          onRollDice: () => _sendSimpleAction(
                            context,
                            GameActionType.rollDice,
                          ),
                          onBuyProperty: () {
                            if (landedProperty == null) {
                              return;
                            }
                            _sendAction(
                              context,
                              GameAction(
                                actorId: controller.localPlayerId ?? '',
                                type: GameActionType.buyProperty,
                                payload: {'propertyId': landedProperty.id},
                              ),
                            );
                          },
                          onBuyManufacture: () {
                            if (landedProperty == null) {
                              return;
                            }
                            _sendAction(
                              context,
                              GameAction(
                                actorId: controller.localPlayerId ?? '',
                                type: GameActionType.buyManufacture,
                                payload: {'propertyId': landedProperty.id},
                              ),
                            );
                          },
                          onBuildIndustry: () {
                            final selected = _selectedPropertyId ??
                                localPlayer?.ownedPropertyIds.firstOrNull;
                            if (selected == null) {
                              return;
                            }
                            _sendAction(
                              context,
                              GameAction(
                                actorId: controller.localPlayerId ?? '',
                                type: GameActionType.buildIndustry,
                                payload: {
                                  'propertyId': selected,
                                  'target': 'national',
                                },
                              ),
                            );
                          },
                          onPirateProperty: () {
                            if (landedProperty == null) {
                              return;
                            }
                            _sendAction(
                              context,
                              GameAction(
                                actorId: controller.localPlayerId ?? '',
                                type: GameActionType.pirateProperty,
                                payload: {'propertyId': landedProperty.id},
                              ),
                            );
                          },
                          onDrawSolidarity: () => _sendSimpleAction(
                            context,
                            GameActionType.drawSolidarity,
                          ),
                          onResolveFmi: () => _sendSimpleAction(
                            context,
                            GameActionType.resolveFmiCondition,
                          ),
                          onEndTurn: () => _sendSimpleAction(
                            context,
                            GameActionType.endTurn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (localPlayer != null &&
                            localPlayer.ownedPropertyIds.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedPropertyId,
                            decoration: const InputDecoration(
                              labelText: 'Propiedad para construir',
                              border: OutlineInputBorder(),
                            ),
                            items: localPlayer.ownedPropertyIds
                                .map((propertyId) {
                                  final property = state.properties
                                      .where((item) => item.id == propertyId)
                                      .firstOrNull;
                                  if (property == null) {
                                    return null;
                                  }
                                  return DropdownMenuItem<String>(
                                    value: property.id,
                                    child: Text(property.name),
                                  );
                                })
                                .whereType<DropdownMenuItem<String>>()
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPropertyId = value;
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tablero / Casilla actual',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                if (currentPlayer != null)
                                  Text(
                                    'Posición actual: ${currentPlayer.position}/${controller.rules?.boardLength ?? 40}',
                                  ),
                                if (landedProperty != null) ...[
                                  Text('Sur: ${landedProperty.name}'),
                                  Text(
                                      'Norte: ${landedProperty.manufactureName}'),
                                  Text(
                                      'Dueño: ${landedProperty.ownerId ?? 'Banco/FMI'}'),
                                  Text(
                                    'Casillas: S ${landedProperty.southBoardIndex} / N ${landedProperty.northBoardIndex}',
                                  ),
                                  Text(
                                    landedProperty.hasManufacture
                                        ? 'Manufactura comprada'
                                        : 'Manufactura no comprada',
                                  ),
                                  Text(
                                    'Industrias: ${landedProperty.nationalIndustries} nacionales / ${landedProperty.exportIndustries} exportación',
                                  ),
                                ] else
                                  const Text(
                                      'La casilla actual no es una propiedad.'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Registro',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                for (final entry in state.log.reversed.take(12))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text('• $entry'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: [
                        for (final player in state.players)
                          PlayerPanel(
                            player: player,
                            isCurrentTurn: currentPlayer?.id == player.id,
                            isLocalPlayer:
                                controller.localPlayerId == player.id,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAmountAction(
    BuildContext context,
    String title,
    GameActionType type,
  ) async {
    final controller = context.read<GameController>();
    final amountController = TextEditingController(text: '1000');
    final amount = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(int.tryParse(amountController.text));
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
    if (amount == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    await controller.sendAction(
      GameAction(
        actorId: controller.localPlayerId ?? '',
        type: type,
        payload: {'amount': amount},
      ),
    );
  }

  Future<void> _sendSimpleAction(
    BuildContext context,
    GameActionType type,
  ) async {
    final controller = context.read<GameController>();
    await _sendAction(
      context,
      GameAction(
        actorId: controller.localPlayerId ?? '',
        type: type,
      ),
    );
  }

  Future<void> _sendAction(BuildContext context, GameAction action) {
    return context.read<GameController>().sendAction(action);
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
