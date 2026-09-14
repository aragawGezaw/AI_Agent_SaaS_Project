class DashboardSummary {
  final SummarySection summary;
  final Map<String, dynamic> goals;
  final ComparisonSection comparisons;
  final List<DailyTrend> dailyTrends;

  const DashboardSummary({
    required this.summary,
    required this.goals,
    required this.comparisons,
    required this.dailyTrends,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final trendsList = json['daily_trends'] as List? ?? [];
    return DashboardSummary(
      summary: SummarySection.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      goals: json['goals'] as Map<String, dynamic>? ?? {},
      comparisons: ComparisonSection.fromJson(json['comparisons'] as Map<String, dynamic>? ?? {}),
      dailyTrends: trendsList.map((t) => DailyTrend.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

class SummarySection {
  final int periodDays;
  final double totalCalories;
  final double avgDailyCalories;
  final double totalGlycemicLoad;
  final double avgDailyGlycemicLoad;
  final MacroSet totalMacros;
  final MacroSet avgDailyMacros;
  final TodaySummary today;

  const SummarySection({
    required this.periodDays,
    required this.totalCalories,
    required this.avgDailyCalories,
    required this.totalGlycemicLoad,
    required this.avgDailyGlycemicLoad,
    required this.totalMacros,
    required this.avgDailyMacros,
    required this.today,
  });

  factory SummarySection.fromJson(Map<String, dynamic> json) {
    return SummarySection(
      periodDays: json['period_days'] as int? ?? 7,
      totalCalories: _parseDouble(json['total_calories']),
      avgDailyCalories: _parseDouble(json['avg_daily_calories']),
      totalGlycemicLoad: _parseDouble(json['total_glycemic_load']),
      avgDailyGlycemicLoad: _parseDouble(json['avg_daily_glycemic_load']),
      totalMacros: MacroSet.fromJson(json['total_macros'] as Map<String, dynamic>? ?? {}),
      avgDailyMacros: MacroSet.fromJson(json['avg_daily_macros'] as Map<String, dynamic>? ?? {}),
      today: TodaySummary.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class MacroSet {
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroSet({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MacroSet.fromJson(Map<String, dynamic> json) {
    return MacroSet(
      proteinG: _parseDouble(json['protein_g']),
      carbsG: _parseDouble(json['carbs_g']),
      fatG: _parseDouble(json['fat_g']),
    );
  }
}

class TodaySummary {
  final String date;
  final double calories;
  final double glycemicLoad;
  final MacroSet macros;
  final int mealCount;

  const TodaySummary({
    required this.date,
    required this.calories,
    required this.glycemicLoad,
    required this.macros,
    required this.mealCount,
  });

  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      date: json['date'] as String? ?? '',
      calories: _parseDouble(json['calories']),
      glycemicLoad: _parseDouble(json['glycemic_load']),
      macros: MacroSet.fromJson(json['macros'] as Map<String, dynamic>? ?? {}),
      mealCount: json['meal_count'] as int? ?? 0,
    );
  }
}

class ComparisonSection {
  final double calorieTarget;
  final int caloriePercentage;
  final double glycemicLoadLimit;
  final int glycemicLoadPercentage;
  final String glycemicStatus;
  final double proteinTargetG;
  final double carbsTargetG;
  final double fatTargetG;
  final int proteinPercentage;
  final int carbsPercentage;
  final int fatPercentage;

  const ComparisonSection({
    required this.calorieTarget,
    required this.caloriePercentage,
    required this.glycemicLoadLimit,
    required this.glycemicLoadPercentage,
    required this.glycemicStatus,
    required this.proteinTargetG,
    required this.carbsTargetG,
    required this.fatTargetG,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatPercentage,
  });

  factory ComparisonSection.fromJson(Map<String, dynamic> json) {
    return ComparisonSection(
      calorieTarget: _parseDouble(json['calorie_target']),
      caloriePercentage: json['calorie_percentage'] as int? ?? 0,
      glycemicLoadLimit: _parseDouble(json['glycemic_load_limit']),
      glycemicLoadPercentage: json['glycemic_load_percentage'] as int? ?? 0,
      glycemicStatus: json['glycemic_status'] as String? ?? 'low',
      proteinTargetG: _parseDouble(json['protein_target_g']),
      carbsTargetG: _parseDouble(json['carbs_target_g']),
      fatTargetG: _parseDouble(json['fat_target_g']),
      proteinPercentage: json['protein_percentage'] as int? ?? 0,
      carbsPercentage: json['carbs_percentage'] as int? ?? 0,
      fatPercentage: json['fat_percentage'] as int? ?? 0,
    );
  }
}

class DailyTrend {
  final String date;
  final double calories;
  final double glycemicLoad;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int mealCount;

  const DailyTrend({
    required this.date,
    required this.calories,
    required this.glycemicLoad,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.mealCount,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] as String? ?? '',
      calories: _parseDouble(json['calories']),
      glycemicLoad: _parseDouble(json['glycemic_load']),
      proteinG: _parseDouble(json['protein_g']),
      carbsG: _parseDouble(json['carbs_g']),
      fatG: _parseDouble(json['fat_g']),
      mealCount: json['meal_count'] as int? ?? 0,
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
