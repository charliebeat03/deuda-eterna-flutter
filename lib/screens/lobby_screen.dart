import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final players = controller.lobbyPlayers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby LAN'),
        actions: [
          TextButton(
            onPressed: controller.returnToMenu,
            child: const Text('Salir'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.isHosting)
              Text(
                'Host: ${controller.hostIp ?? 'IP no detectada'}:${controller.port}',
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              Text(
                'Conectado a ${controller.hostIp ?? '-'}:${controller.port}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 12),
            if (controller.statusMessage != null)
              Text(controller.statusMessage!),
            const SizedBox(height: 20),
            Text(
              'Jugadores (${players.length}/5)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Card(
                    child: ListTile(
                      title: Text(player.name),
                      subtitle: Text(player.address ?? 'sin IP'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (player.isHost) const Chip(label: Text('Host')),
                          Chip(
                            label: Text(
                              player.isConnected ? 'Conectado' : 'Offline',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                if (controller.isHosting)
                  FilledButton(
                    onPressed: players.isEmpty
                        ? null
                        : () {
                            controller.startHostedLanMatch();
                          },
                    child: const Text('Iniciar partida'),
                  ),
                if (controller.isClient)
                  OutlinedButton(
                    onPressed: controller.reconnectToHost,
                    child: const Text('Reconectar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
