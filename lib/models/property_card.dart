class PropertyCard {
  const PropertyCard({
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
    this.ownerId,
    this.hasManufacture = false,
    this.nationalIndustries = 0,
    this.exportIndustries = 0,
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
  final String? ownerId;
  final bool hasManufacture;
  final int nationalIndustries;
  final int exportIndustries;

  bool get isOwned => ownerId != null;
  int get totalIndustries => nationalIndustries + exportIndustries;
  bool get canCollectSouthRent => nationalIndustries > 0;
  bool get canCollectNorthRent => hasManufacture && exportIndustries > 0;
  bool matchesPosition(int position) {
    return southBoardIndex == position || northBoardIndex == position;
  }

  PropertyCard copyWith({
    String? id,
    String? name,
    String? manufactureName,
    String? group,
    int? southBoardIndex,
    int? northBoardIndex,
    int? purchaseCost,
    int? manufacturePurchaseCost,
    int? industryBuildCost,
    int? exportBuildCost,
    int? southBaseIncome,
    int? northBaseIncome,
    String? ownerId,
    bool clearOwner = false,
    bool? hasManufacture,
    int? nationalIndustries,
    int? exportIndustries,
  }) {
    return PropertyCard(
      id: id ?? this.id,
      name: name ?? this.name,
      manufactureName: manufactureName ?? this.manufactureName,
      group: group ?? this.group,
      southBoardIndex: southBoardIndex ?? this.southBoardIndex,
      northBoardIndex: northBoardIndex ?? this.northBoardIndex,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      manufacturePurchaseCost:
          manufacturePurchaseCost ?? this.manufacturePurchaseCost,
      industryBuildCost: industryBuildCost ?? this.industryBuildCost,
      exportBuildCost: exportBuildCost ?? this.exportBuildCost,
      southBaseIncome: southBaseIncome ?? this.southBaseIncome,
      northBaseIncome: northBaseIncome ?? this.northBaseIncome,
      ownerId: clearOwner ? null : ownerId ?? this.ownerId,
      hasManufacture: hasManufacture ?? this.hasManufacture,
      nationalIndustries: nationalIndustries ?? this.nationalIndustries,
      exportIndustries: exportIndustries ?? this.exportIndustries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufactureName': manufactureName,
      'group': group,
      'southBoardIndex': southBoardIndex,
      'northBoardIndex': northBoardIndex,
      'purchaseCost': purchaseCost,
      'manufacturePurchaseCost': manufacturePurchaseCost,
      'industryBuildCost': industryBuildCost,
      'exportBuildCost': exportBuildCost,
      'southBaseIncome': southBaseIncome,
      'northBaseIncome': northBaseIncome,
      'ownerId': ownerId,
      'hasManufacture': hasManufacture,
      'nationalIndustries': nationalIndustries,
      'exportIndustries': exportIndustries,
    };
  }

  factory PropertyCard.fromJson(Map<String, dynamic> json) {
    return PropertyCard(
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
      ownerId: json['ownerId'] as String?,
      hasManufacture: json['hasManufacture'] as bool? ?? false,
      nationalIndustries: json['nationalIndustries'] as int? ?? 0,
      exportIndustries: json['exportIndustries'] as int? ?? 0,
    );
  }
}
