import 'package:flutter/material.dart';

import '../models/player.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.isLocalPlayer,
  });

  final Player player;
  final bool isCurrentTurn;
  final bool isLocalPlayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isCurrentTurn
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isLocalPlayer)
                  const Chip(
                    label: Text('Tú'),
                    visualDensity: VisualDensity.compact,
                  ),
                if (player.type == PlayerType.cpu)
                  const Chip(
                    label: Text('CPU'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Caja: \$${player.cash}'),
            Text('Deuda: \$${player.debt.total}'),
            Text('Oro: ${player.goldReserves}'),
            Text('Posición: ${player.position}'),
            Text('Devaluación: nivel ${player.devaluationLevel}'),
            if (player.skipNextInterest) const Text('No Pagar activo'),
            if (player.hasBolivarSword) const Text('Espada de Bolívar'),
            if (player.underEmbargo) const Text('Bajo embargo'),
            Text(player.isConnected ? 'Conectado' : 'Desconectado'),
          ],
        ),
      ),
    );
  }
}
