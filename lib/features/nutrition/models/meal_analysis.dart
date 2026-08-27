class AnalyzedFoodItem {
  final String foodId;
  final String nameEn;
  final String nameAm;
  final String source;
  final double portionG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fiberG;
  final double fatG;
  final double netCarbsG;
  final double glycemicLoad;

  AnalyzedFoodItem({
    required this.foodId,
    required this.nameEn,
    required this.nameAm,
    required this.source,
    required this.portionG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fiberG,
    required this.fatG,
    required this.netCarbsG,
    required this.glycemicLoad,
  });

  factory AnalyzedFoodItem.fromJson(Map<String, dynamic> json) {
    return AnalyzedFoodItem(
      foodId: json['food_id'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameAm: json['name_am'] as String? ?? '',
      source: json['source'] as String? ?? 'EPHI',
      portionG: (json['portion_g'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      netCarbsG: (json['net_carbs_g'] as num?)?.toDouble() ?? 0.0,
      glycemicLoad: (json['glycemic_load'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String getName(String languageCode) {
    if (languageCode == 'am' && nameAm.isNotEmpty) {
      return nameAm;
    }
    return nameEn;
  }
}

class MealTotals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fiberG;
  final double fatG;
  final double netCarbsG;

  MealTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fiberG,
    required this.fatG,
    required this.netCarbsG,
  });

  factory MealTotals.fromJson(Map<String, dynamic> json) {
    return MealTotals(
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      netCarbsG: (json['net_carbs_g'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopContributor {
  final String foodId;
  final String nameEn;
  final String nameAm;
  final double portionG;
  final double glycemicLoad;

  TopContributor({
    required this.foodId,
    required this.nameEn,
    required this.nameAm,
    required this.portionG,
    required this.glycemicLoad,
  });

  factory TopContributor.fromJson(Map<String, dynamic> json) {
    return TopContributor(
      foodId: json['food_id'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameAm: json['name_am'] as String? ?? '',
      portionG: (json['portion_g'] as num?)?.toDouble() ?? 0.0,
      glycemicLoad: (json['glycemic_load'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String getName(String languageCode) {
    if (languageCode == 'am' && nameAm.isNotEmpty) {
      return nameAm;
    }
    return nameEn;
  }
}

class EvaluationNote {
  final String glycemicLoadClass; // 'low', 'medium', 'high'
  final double totalGlycemicLoad;
  final TopContributor? topContributor;
  final MealTotals totals;
  final String recommendation;

  EvaluationNote({
    required this.glycemicLoadClass,
    required this.totalGlycemicLoad,
    this.topContributor,
    required this.totals,
    required this.recommendation,
  });

  factory EvaluationNote.fromJson(Map<String, dynamic> json) {
    return EvaluationNote(
      glycemicLoadClass: json['glycemic_load_class'] as String? ?? 'low',
      totalGlycemicLoad: (json['total_glycemic_load'] as num?)?.toDouble() ?? 0.0,
      topContributor: json['top_contributor'] != null
          ? TopContributor.fromJson(json['top_contributor'] as Map<String, dynamic>)
          : null,
      totals: MealTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
      recommendation: json['recommendation'] as String? ?? '',
    );
  }
}

class MealAnalysis {
  final List<AnalyzedFoodItem> items;
  final MealTotals totals;
  final double totalGlycemicLoad;
  final EvaluationNote evaluationNote;

  MealAnalysis({
    required this.items,
    required this.totals,
    required this.totalGlycemicLoad,
    required this.evaluationNote,
  });

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return MealAnalysis(
      items: itemsJson
          .map((item) => AnalyzedFoodItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totals: MealTotals.fromJson(json['totals'] as Map<String, dynamic>? ?? {}),
      totalGlycemicLoad: (json['total_glycemic_load'] as num?)?.toDouble() ?? 0.0,
      evaluationNote: EvaluationNote.fromJson(
        json['evaluation_note'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
