import 'package:flutter/material.dart';

/// Data model representing a single AI-generated meal plan entry.
/// Maps to the backend `meal_plans` table (migration 009).
class MealPlan {
  final int id;
  final String userId;
  final DateTime planDate;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? recipeId;
  final String? foodName; // Specific food/dish name (e.g., Shiro Wat, Injera)
  final double glycemicLoad;
  final double calories;
  final Map<String, dynamic> macronutrients; // {protein_g, carbs_g, fat_g}
  final bool isFastingMeal;
  final String? recommendationSource;
  final List<String> ingredients; // For Smart Grocery List generation
  final List<String> instructions; // Step-by-step recipe instructions
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.planDate,
    required this.mealType,
    this.recipeId,
    this.foodName,
    required this.glycemicLoad,
    required this.calories,
    required this.macronutrients,
    required this.isFastingMeal,
    this.recommendationSource,
    this.ingredients = const [],
    this.instructions = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    // 1. Robust macronutrients extraction supporting both nested map and flat root keys
    Map<String, dynamic> macros = {};
    if (json['macronutrients'] is Map) {
      macros = Map<String, dynamic>.from(json['macronutrients']);
    }
    if (macros.isEmpty) {
      macros = {
        'protein_g': json['protein'] ?? json['protein_g'] ?? 0.0,
        'carbs_g':
            json['carbs'] ?? json['carbs_g'] ?? json['carbohydrates'] ?? 0.0,
        'fat_g': json['fat'] ?? json['fat_g'] ?? 0.0,
      };
    }

    // 2. Robust safe parsing for ingredients list
    List<String> parsedIngredients = [];
    if (json['ingredients'] is List) {
      parsedIngredients = (json['ingredients'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['ingredients'] is String) {
      parsedIngredients = [json['ingredients'] as String];
    }

    // 3. Robust safe parsing for instructions list
    List<String> parsedInstructions = [];
    if (json['instructions'] is List) {
      parsedInstructions = (json['instructions'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['instructions'] is String) {
      parsedInstructions = [json['instructions'] as String];
    }

    return MealPlan(
      id: _parseInt(json['id']),
      userId: json['user_id'] as String? ?? '',
      planDate: DateTime.parse(
        json['plan_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      mealType: json['meal_type'] as String? ?? 'snack',
      recipeId: json['recipe_id'] as String?,
      foodName:
          json['food_name'] as String? ??
          json['recipe_name'] as String? ??
          json['title'] as String? ??
          json['description'] as String? ??
          json['name'] as String?,
      glycemicLoad: _parseDouble(json['glycemic_load']),
      calories: _parseDouble(json['calories']),
      macronutrients: macros,
      isFastingMeal: json['is_fasting_meal'] as bool? ?? false,
      recommendationSource: json['recommendation_source'] as String?,
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
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
      'food_name': foodName,
      'glycemic_load': glycemicLoad,
      'calories': calories,
      'macronutrients': macronutrients,
      'is_fasting_meal': isFastingMeal,
      'recommendation_source': recommendationSource,
      'ingredients': ingredients,
      'instructions': instructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // --- Localized Display Helpers ---

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

  // --- Macro Accessors ---
  double get proteinG => _readMacro(macronutrients, 'protein_g');
  double get carbsG => _readMacro(macronutrients, 'carbs_g');
  double get fatG => _readMacro(macronutrients, 'fat_g');
}

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
