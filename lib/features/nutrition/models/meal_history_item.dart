import 'package:flutter/material.dart' show Color;

/// Safely converts a dynamic value to a double.
///
/// PostgreSQL DECIMAL columns are returned as strings by the `pg` driver,
/// while INT/JSON numeric fields are returned as `num`.  Casting a `String`
/// with `as num?` throws `TypeError`, so this helper accepts `num`, `String`,
/// and `null` — converting each to `double` without throwing.
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Safely converts a dynamic value to an int.
///
/// Handles `num`, `String`, and `null`.
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class MealHistoryItem {
  final String id;
  final String userId;
  final String mealType;
  final String foodName;
  final List<String> foodIds;
  final int calories;
  final Map<String, dynamic> macros;
  final double totalGlycemicLoad;
  final double netCarbsG;
  final String glClass; // low, medium, high
  final DateTime loggedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealHistoryItem({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodName,
    required this.foodIds,
    required this.calories,
    required this.macros,
    required this.totalGlycemicLoad,
    required this.netCarbsG,
    required this.glClass,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealHistoryItem.fromJson(Map<String, dynamic> json) {
    return MealHistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? '',
      foodName: json['food_name'] as String? ?? '',
      foodIds: List<String>.from(json['food_ids'] ?? []),
      calories: _parseInt(json['calories']),
      macros: json['macros'] as Map<String, dynamic>? ?? {},
      // PostgreSQL DECIMAL columns are returned as strings by the pg driver.
      // _parseDouble handles both num (JSON int) and String (pg DECIMAL).
      totalGlycemicLoad: _parseDouble(json['total_glycemic_load']),
      netCarbsG: _parseDouble(json['net_carbs_g']),
      glClass: json['gl_class'] as String? ?? 'low',
      loggedAt: DateTime.parse(json['logged_at'] as String? ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'meal_type': mealType,
      'food_name': foodName,
      'food_ids': foodIds,
      'calories': calories,
      'macros': macros,
      'total_glycemic_load': totalGlycemicLoad,
      'net_carbs_g': netCarbsG,
      'gl_class': glClass,
      'logged_at': loggedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getMealTypeDisplay(String langCode) {
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
        return langCode == 'am' ? mealType : mealType;
    }
  }

  Color getGlClassColor() {
    switch (glClass.toLowerCase()) {
      case 'low':
        return const Color(0xFF2E7D32); // Green
      case 'medium':
        return const Color(0xFFE65100); // Orange
      case 'high':
        return const Color(0xFFC62828); // Red
      default:
        return const Color(0xFF2E7D32); // Default to green
    }
  }

  String getGlClassLabel(String langCode) {
    switch (glClass.toLowerCase()) {
      case 'low':
        return langCode == 'am' ? 'ዝቅተኛ GL (Low)' : 'Low GL';
      case 'medium':
        return langCode == 'am' ? 'መካከለኛ GL (Med)' : 'Medium GL';
      case 'high':
        return langCode == 'am' ? 'ከፍተኛ GL (High)' : 'High GL';
      default:
        return langCode == 'am' ? 'ዝቅተኛ GL (Low)' : 'Low GL';
    }
  }
}