import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'screens/game_table_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/menu_screen.dart';

class DeudaEternaApp extends StatelessWidget {
  const DeudaEternaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController()..initialize(),
      child: MaterialApp(
        title: 'Deuda Eterna',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B7F5B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    return switch (controller.screen) {
      AppScreen.menu => const MenuScreen(),
      AppScreen.lobby => const LobbyScreen(),
      AppScreen.game => const GameTableScreen(),
    };
  }
}
