class FoodItem {
  final String id;
  final String nameEn;
  final String nameAm;
  final double caloriesPer100g;
  final double proteinG;
  final double carbsG;
  final double fiberG;
  final double fatG;
  final double? glycemicIndex;
  final String source;

  FoodItem({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    required this.caloriesPer100g,
    required this.proteinG,
    required this.carbsG,
    required this.fiberG,
    required this.fatG,
    this.glycemicIndex,
    required this.source,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      nameEn: json['name_en'] as String? ?? '',
      nameAm: json['name_am'] as String? ?? '',
      caloriesPer100g: (json['calories_per_100g'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      glycemicIndex: (json['glycemic_index'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'EPHI',
    );
  }

  String getName(String languageCode) {
    if (languageCode == 'am' && nameAm.isNotEmpty) {
      return nameAm;
    }
    return nameEn;
  }
}
