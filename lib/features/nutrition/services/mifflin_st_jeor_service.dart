/// Mifflin-St Jeor equation service for calculating BMR, TDEE, and nutritional targets.
///
/// This service implements the Mifflin-St Jeor formula for Basal Metabolic Rate (BMR)
/// and applies activity multipliers and goal adjustments to compute daily calorie
/// and macronutrient targets.
class MifflinStJeorService {
  /// Calculates BMR using the Mifflin-St Jeor equation.
  ///
  /// [weightKg] - Weight in kilograms
  /// [heightCm] - Height in centimeters
  /// [age] - Age in years
  /// [isMale] - true for male, false for female
  ///
  /// Returns BMR in kcal/day.
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    // Mifflin-St Jeor Equation
    // Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 5
    // Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
    if (isMale) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  /// Activity level multipliers for TDEE calculation.
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2,         // Little or no exercise
    'light': 1.375,           // Light exercise 1-3 days/week
    'moderate': 1.55,         // Moderate exercise 3-5 days/week
    'active': 1.725,          // Hard exercise 6-7 days/week
    'very_active': 1.9,       // Very hard exercise, physical job, or 2x training
  };

  /// Goal adjustment factors (calorie surplus/deficit from TDEE).
  static const Map<String, double> goalAdjustments = {
    'maintenance': 0,
    'weight_loss': -500,      // ~0.5 kg/week loss
    'muscle_gain': 300,       // Moderate surplus for lean gain
    'fasting_support': -300,  // Mild deficit for fasting support
    'diabetes_management': -500, // Weight loss focus for insulin sensitivity
  };

  /// Macro distribution ratios for different goals.
  /// Returns {protein: %, carbs: %, fat: %} where each is a fraction of total calories.
  static const Map<String, Map<String, double>> macroRatios = {
    'maintenance': {'protein': 0.25, 'carbs': 0.45, 'fat': 0.30},
    'weight_loss': {'protein': 0.30, 'carbs': 0.40, 'fat': 0.30},
    'muscle_gain': {'protein': 0.30, 'carbs': 0.45, 'fat': 0.25},
    'fasting_support': {'protein': 0.30, 'carbs': 0.35, 'fat': 0.35},
    'diabetes_management': {'protein': 0.25, 'carbs': 0.35, 'fat': 0.40}, // Lower carb
  };

  /// Calculates Total Daily Energy Expenditure (TDEE).
  ///
  /// [bmr] - Basal Metabolic Rate in kcal/day
  /// [activityLevel] - One of: sedentary, light, moderate, active, very_active
  ///
  /// Returns TDEE in kcal/day.
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Calculates daily calorie target based on TDEE and goal.
  ///
  /// [tdee] - Total Daily Energy Expenditure in kcal/day
  /// [goalFocus] - One of: maintenance, weight_loss, muscle_gain, fasting_support, diabetes_management
  ///
  /// Returns adjusted daily calorie target in kcal/day.
  static int calculateDailyCalories({
    required double tdee,
    required String goalFocus,
  }) {
    final adjustment = goalAdjustments[goalFocus] ?? 0;
    return (tdee + adjustment).round();
  }

  /// Calculates macronutrient targets in grams.
  ///
  /// [dailyCalories] - Daily calorie target in kcal
  /// [goalFocus] - Goal to determine macro ratio
  ///
  /// Returns map with keys: protein_g, carbs_g, fat_g
  static Map<String, double> calculateMacros({
    required int dailyCalories,
    required String goalFocus,
  }) {
    final ratios = macroRatios[goalFocus] ?? macroRatios['maintenance']!;
    
    // Protein: 4 kcal/g, Carbs: 4 kcal/g, Fat: 9 kcal/g
    final proteinG = (dailyCalories * ratios['protein']! / 4).roundToDouble();
    final carbsG = (dailyCalories * ratios['carbs']! / 4).roundToDouble();
    final fatG = (dailyCalories * ratios['fat']! / 9).roundToDouble();
    
    return {
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    };
  }

  /// Calculates glycemic load thresholds.
  /// Standard thresholds: Low ≤ 10, Medium ≤ 19, High > 19
  ///
  /// [dailyCalories] - Daily calorie target (used to scale daily GL limit)
  /// [goalFocus] - Goal focus for personalized limits
  ///
  /// Returns map with keys: low_threshold, medium_threshold, daily_limit
  static Map<String, double> calculateGLThresholds({
    required int dailyCalories,
    required String goalFocus,
  }) {
    // Standard GL classification thresholds (per meal)
    const lowThreshold = 10.0;
    const mediumThreshold = 19.0;
    
    // Daily GL limit scales with calorie intake
    // ~1 GL per 100 kcal is a reasonable baseline
    double dailyLimit = dailyCalories / 100;
    
    // Adjust for goals
    switch (goalFocus) {
      case 'diabetes_management':
        dailyLimit *= 0.7; // Stricter GL control
        break;
      case 'weight_loss':
        dailyLimit *= 0.85;
        break;
      case 'muscle_gain':
        dailyLimit *= 1.1;
        break;
      default:
        break;
    }
    
    return {
      'low_threshold': lowThreshold,
      'medium_threshold': mediumThreshold,
      'daily_limit': dailyLimit.roundToDouble(),
    };
  }

  /// Complete calculation: BMR → TDEE → Daily Calories → Macros → GL Thresholds.
  ///
  /// [weightKg] - Weight in kilograms
  /// [heightCm] - Height in centimeters
  /// [age] - Age in years
  /// [isMale] - true for male, false for female
  /// [activityLevel] - Activity level key
  /// [goalFocus] - Health goal key
  ///
  /// Returns a map with all calculated targets.
  static Map<String, dynamic> calculateAll({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
    required String activityLevel,
    required String goalFocus,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isMale: isMale,
    );
    
    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);
    final dailyCalories = calculateDailyCalories(tdee: tdee, goalFocus: goalFocus);
    final macros = calculateMacros(dailyCalories: dailyCalories, goalFocus: goalFocus);
    final glThresholds = calculateGLThresholds(dailyCalories: dailyCalories, goalFocus: goalFocus);
    
    return {
      'bmr': bmr.round(),
      'tdee': tdee.round(),
      'daily_calorie_target': dailyCalories,
      'daily_protein_target_g': macros['protein_g'],
      'daily_carbs_target_g': macros['carbs_g'],
      'daily_fat_target_g': macros['fat_g'],
      'glycemic_load_low_threshold': glThresholds['low_threshold'],
      'glycemic_load_medium_threshold': glThresholds['medium_threshold'],
      'daily_glycemic_load_limit': glThresholds['daily_limit'],
    };
  }

  /// Validates biometric inputs.
  ///
  /// Returns null if valid, or an error message string if invalid.
  static String? validateInputs({
    required double? weightKg,
    required double? heightCm,
    required int? age,
    required String? gender,
    required String? activityLevel,
    required String? goalFocus,
  }) {
    if (weightKg == null || weightKg <= 0) {
      return 'Please enter a valid weight';
    }
    if (weightKg < 30 || weightKg > 300) {
      return 'Weight must be between 30 and 300 kg';
    }
    if (heightCm == null || heightCm <= 0) {
      return 'Please enter a valid height';
    }
    if (heightCm < 100 || heightCm > 250) {
      return 'Height must be between 100 and 250 cm';
    }
    if (age == null || age <= 0) {
      return 'Please enter a valid age';
    }
    if (age < 10 || age > 120) {
      return 'Age must be between 10 and 120';
    }
    if (gender == null || gender.isEmpty) {
      return 'Please select gender';
    }
    if (activityLevel == null || activityLevel.isEmpty) {
      return 'Please select activity level';
    }
    if (goalFocus == null || goalFocus.isEmpty) {
      return 'Please select health goal';
    }
    return null;
  }
}