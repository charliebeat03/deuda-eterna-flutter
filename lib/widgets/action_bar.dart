import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.canAct,
    required this.onRequestLoan,
    required this.onPayDebt,
    required this.onRollDice,
    required this.onBuyProperty,
    required this.onBuyManufacture,
    required this.onBuildIndustry,
    required this.onPirateProperty,
    required this.onDrawSolidarity,
    required this.onResolveFmi,
    required this.onEndTurn,
  });

  final bool canAct;
  final VoidCallback onRequestLoan;
  final VoidCallback onPayDebt;
  final VoidCallback onRollDice;
  final VoidCallback onBuyProperty;
  final VoidCallback onBuyManufacture;
  final VoidCallback onBuildIndustry;
  final VoidCallback onPirateProperty;
  final VoidCallback onDrawSolidarity;
  final VoidCallback onResolveFmi;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: canAct ? onRequestLoan : null,
          child: const Text('Pedir préstamo'),
        ),
        FilledButton(
          onPressed: canAct ? onPayDebt : null,
          child: const Text('Pagar deuda'),
        ),
        OutlinedButton(
          onPressed: canAct ? onRollDice : null,
          child: const Text('Tirar dados'),
        ),
        OutlinedButton(
          onPressed: canAct ? onBuyProperty : null,
          child: const Text('Comprar terreno'),
        ),
        OutlinedButton(
          onPressed: canAct ? onBuyManufacture : null,
          child: const Text('Comprar manufactura'),
        ),
        OutlinedButton(
          onPressed: canAct ? onBuildIndustry : null,
          child: const Text('Construir'),
        ),
        OutlinedButton(
          onPressed: canAct ? onPirateProperty : null,
          child: const Text('Piratear'),
        ),
        OutlinedButton(
          onPressed: canAct ? onDrawSolidarity : null,
          child: const Text('Solidaridad'),
        ),
        OutlinedButton(
          onPressed: canAct ? onResolveFmi : null,
          child: const Text('Condición FMI'),
        ),
        FilledButton.tonal(
          onPressed: canAct ? onEndTurn : null,
          child: const Text('Terminar turno'),
        ),
      ],
    );
  }
}
