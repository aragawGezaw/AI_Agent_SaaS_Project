/// Data model representing a single AI-generated meal plan entry.
/// Maps to the backend `meal_plans` table (migration 009).
class MealPlan {
  final int id;
  final String userId;
  final DateTime planDate;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? recipeId;
  final double glycemicLoad;
  final double calories;
  final Map<String, dynamic> macronutrients; // {protein_g, carbs_g, fat_g}
  final bool isFastingMeal;
  final String? recommendationSource;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.mealType,
    this.recipeId,
    required this.glycemicLoad,
    required this.calories,
    required this.macronutrients,
    required this.isFastingMeal,
    this.recommendationSource,
    required this.createdAt,
    this.updatedAt,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: _parseInt(json['id']),
      userId: json['user_id'] as String? ?? '',
      planDate: DateTime.parse(
        json['plan_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      mealType: json['meal_type'] as String? ?? 'snack',
      recipeId: json['recipe_id'] as String?,
      glycemicLoad: _parseDouble(json['glycemic_load']),
      calories: _parseDouble(json['calories']),
      macronutrients:
          json['macronutrients'] as Map<String, dynamic>? ?? const {},
      isFastingMeal: json['is_fasting_meal'] as bool? ?? false,
      recommendationSource: json['recommendation_source'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_date': planDate.toIso8601String(),
      'meal_type': mealType,
      'recipe_id': recipeId,
      'glycemic_load': glycemicLoad,
      'calories': calories,
      'macronutrients': macronutrients,
      'is_fasting_meal': isFastingMeal,
      'recommendation_source': recommendationSource,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // --- Localized Display Helpers ---

  /// Returns a localized label for the meal type (breakfast/lunch/dinner/snack)
  String getMealTypeLabel(String langCode) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return langCode == 'am' ? 'ቁርስ' : 'Breakfast';
      case 'lunch':
        return langCode == 'am' ? 'ምሳ' : 'Lunch';
      case 'dinner':
        return langCode == 'am' ? 'እራት' : 'Dinner';
      case 'snack':
        return langCode == 'am' ? 'ትንሽ ምግብ' : 'Snack';
      default:
        return mealType;
    }
  }

  /// Returns the appropriate Material icon for the meal type
  String getMealTypeIconKey() {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'free_breakfast';
      case 'lunch':
        return 'lunch_dining';
      case 'dinner':
        return 'dinner_dining';
      case 'snack':
        return 'cookie';
      default:
        return 'restaurant';
    }
  }

  /// Returns the brand color for the meal type
  int getMealTypeColor() {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 0xFFFB8C00; // Orange
      case 'lunch':
        return 0xFF2E7D32; // Green
      case 'dinner':
        return 0xFF6A1B9A; // Purple
      case 'snack':
        return 0xFFD81B60; // Pink
      default:
        return 0xFF455A64;
    }
  }

  /// Classifies glycemic load into low/medium/high buckets
  String getGlClass() {
    if (glycemicLoad <= 10.0) return 'low';
    if (glycemicLoad <= 19.99) return 'medium';
    return 'high';
  }

  /// Returns localized GL classification label
  String getGlClassLabel(String langCode) {
    final cls = getGlClass();
    if (langCode == 'am') {
      switch (cls) {
        case 'low':
          return 'ዝቅተኛ GL (Low)';
        case 'medium':
          return 'መካከለኛ GL (Med)';
        case 'high':
          return 'ከፍተኛ GL (High)';
      }
    }
    switch (cls) {
      case 'low':
        return 'Low GL';
      case 'medium':
        return 'Medium GL';
      case 'high':
        return 'High GL';
    }
    return 'Low GL';
  }

  // --- Macro Accessors ---
  double get proteinG => _readMacro(macronutrients, 'protein_g');
  double get carbsG => _readMacro(macronutrients, 'carbs_g');
  double get fatG => _readMacro(macronutrients, 'fat_g');
}

// --- Internal numeric parsers (handle pg DECIMAL → String or JSON int → num) ---

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _readMacro(Map<String, dynamic> macros, String key) {
  final value = macros[key];
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
