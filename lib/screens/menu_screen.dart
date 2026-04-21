import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _nameController = TextEditingController(text: 'Jugador 1');
  final _hostIpController = TextEditingController(text: '192.168.0.10');
  final _portController = TextEditingController(text: '4040');
  int _cpuPlayers = 2;

  @override
  void dispose() {
    _nameController.dispose();
    _hostIpController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deuda Eterna',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esqueleto Flutter para juego local vs CPU y LAN por TCP.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del jugador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildLocalCard(context, controller),
                      _buildLanHostCard(context, controller),
                      _buildLanJoinCard(context, controller),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (controller.errorMessage != null)
                    Text(
                      controller.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (controller.statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(controller.statusMessage!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCard(BuildContext context, GameController controller) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local vs CPU',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _cpuPlayers,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 CPU')),
                  DropdownMenuItem(value: 2, child: Text('2 CPU')),
                  DropdownMenuItem(value: 3, child: Text('3 CPU')),
                  DropdownMenuItem(value: 4, child: Text('4 CPU')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Rivales CPU',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _cpuPlayers = value ?? 2;
                  });
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.isLoading
                    ? null
                    : () {
                        controller.startLocalGame(
                          playerName: _nameController.text.trim().isEmpty
                              ? 'Jugador 1'
                              : _nameController.text.trim(),
                          cpuPlayers: _cpuPlayers,
                        );
                      },
                child: const Text('Iniciar local'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanHostCard(BuildContext context, GameController controller) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crear sala LAN',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puerto TCP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.isLoading
                    ? null
                    : () {
                        controller.createLanRoom(
                          playerName: _nameController.text.trim().isEmpty
                              ? 'Host'
                              : _nameController.text.trim(),
                          port: int.tryParse(_portController.text) ?? 4040,
                        );
                      },
                child: const Text('Crear sala'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanJoinCard(BuildContext context, GameController controller) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unirse por IP',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _hostIpController,
                decoration: const InputDecoration(
                  labelText: 'IP del host',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.isLoading
                    ? null
                    : () {
                        controller.joinLanRoom(
                          playerName: _nameController.text.trim().isEmpty
                              ? 'Cliente'
                              : _nameController.text.trim(),
                          hostIp: _hostIpController.text.trim(),
                          port: int.tryParse(_portController.text) ?? 4040,
                        );
                      },
                child: const Text('Conectar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
