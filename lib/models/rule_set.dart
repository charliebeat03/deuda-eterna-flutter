import 'dart:convert';

import 'package:flutter/services.dart';

import 'game_card.dart';
import 'property_card.dart';

class PropertyTemplate {
  const PropertyTemplate({
    required this.id,
    required this.name,
    required this.manufactureName,
    required this.group,
    required this.southBoardIndex,
    required this.northBoardIndex,
    required this.purchaseCost,
    required this.manufacturePurchaseCost,
    required this.industryBuildCost,
    required this.exportBuildCost,
    required this.southBaseIncome,
    required this.northBaseIncome,
  });

  final String id;
  final String name;
  final String manufactureName;
  final String group;
  final int southBoardIndex;
  final int northBoardIndex;
  final int purchaseCost;
  final int manufacturePurchaseCost;
  final int industryBuildCost;
  final int exportBuildCost;
  final int southBaseIncome;
  final int northBaseIncome;

  PropertyCard toPropertyCard() {
    return PropertyCard(
      id: id,
      name: name,
      manufactureName: manufactureName,
      group: group,
      southBoardIndex: southBoardIndex,
      northBoardIndex: northBoardIndex,
      purchaseCost: purchaseCost,
      manufacturePurchaseCost: manufacturePurchaseCost,
      industryBuildCost: industryBuildCost,
      exportBuildCost: exportBuildCost,
      southBaseIncome: southBaseIncome,
      northBaseIncome: northBaseIncome,
    );
  }

  factory PropertyTemplate.fromJson(Map<String, dynamic> json) {
    return PropertyTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      manufactureName: json['manufactureName'] as String? ?? '',
      group: json['group'] as String? ?? '',
      southBoardIndex: json['southBoardIndex'] as int? ?? 0,
      northBoardIndex: json['northBoardIndex'] as int? ?? 0,
      purchaseCost: json['purchaseCost'] as int? ?? 0,
      manufacturePurchaseCost: json['manufacturePurchaseCost'] as int? ?? 0,
      industryBuildCost: json['industryBuildCost'] as int? ?? 0,
      exportBuildCost: json['exportBuildCost'] as int? ?? 0,
      southBaseIncome: json['southBaseIncome'] as int? ?? 0,
      northBaseIncome: json['northBaseIncome'] as int? ?? 0,
    );
  }
}

class RuleSet {
  const RuleSet({
    required this.title,
    required this.boardLength,
    required this.startingCash,
    required this.startingGold,
    required this.startCashPerDiePoint,
    required this.passStartBonus,
    required this.minLoanStep,
    required this.maxDebt,
    required this.baseInterestRate,
    required this.maxNationalIndustries,
    required this.maxExportIndustries,
    required this.devaluationThresholds,
    required this.specialSpaces,
    required this.properties,
    required this.solidarityCards,
    required this.fmiCards,
  });

  final String title;
  final int boardLength;
  final int startingCash;
  final int startingGold;
  final int startCashPerDiePoint;
  final int passStartBonus;
  final int minLoanStep;
  final int maxDebt;
  final double baseInterestRate;
  final int maxNationalIndustries;
  final int maxExportIndustries;
  final List<int> devaluationThresholds;
  final Map<String, List<int>> specialSpaces;
  final List<PropertyTemplate> properties;
  final List<GameCard> solidarityCards;
  final List<GameCard> fmiCards;

  bool isSpecialSpace(String key, int position) {
    return specialSpaces[key]?.contains(position) ?? false;
  }

  factory RuleSet.fromJson(Map<String, dynamic> json) {
    final rawSpaces =
        json['specialSpaces'] as Map<String, dynamic>? ?? const {};
    return RuleSet(
      title: json['title'] as String? ?? 'Deuda Eterna',
      boardLength: json['boardLength'] as int? ?? 30,
      startingCash: json['startingCash'] as int? ?? 3000,
      startingGold: json['startingGold'] as int? ?? 2,
      startCashPerDiePoint: json['startCashPerDiePoint'] as int? ?? 500,
      passStartBonus: json['passStartBonus'] as int? ?? 750,
      minLoanStep: json['minLoanStep'] as int? ?? 1000,
      maxDebt: json['maxDebt'] as int? ?? 20000,
      baseInterestRate: (json['baseInterestRate'] as num? ?? 0.1).toDouble(),
      maxNationalIndustries: json['maxNationalIndustries'] as int? ?? 3,
      maxExportIndustries: json['maxExportIndustries'] as int? ?? 3,
      devaluationThresholds:
          ((json['devaluationThresholds'] as List<dynamic>?) ?? const [])
              .map((item) => item as int)
              .toList(),
      specialSpaces: rawSpaces.map(
        (key, value) => MapEntry(
          key,
          ((value as List<dynamic>?) ?? const [])
              .map((item) => item as int)
              .toList(),
        ),
      ),
      properties: ((json['properties'] as List<dynamic>?) ?? const [])
          .map(
              (item) => PropertyTemplate.fromJson(item as Map<String, dynamic>))
          .toList(),
      solidarityCards: ((json['solidarityCards'] as List<dynamic>?) ?? const [])
          .map((item) => GameCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      fmiCards: ((json['fmiCards'] as List<dynamic>?) ?? const [])
          .map((item) => GameCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RuleSetLoader {
  static Future<RuleSet> loadDefault() async {
    final rawJson =
        await rootBundle.loadString('assets/rules/default_rules.json');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return RuleSet.fromJson(decoded);
  }
}
