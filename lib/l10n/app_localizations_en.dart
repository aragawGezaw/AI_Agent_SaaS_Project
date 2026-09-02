// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Nutrition';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get registerButton => 'Register';

  @override
  String get mealHistory => 'Meal History';

  @override
  String get mealHistoryTitle => 'Your Nutritional Journey';

  @override
  String get noMealsLogged =>
      'No meals logged yet. Start tracking your nutrition!';

  @override
  String get deleteMeal => 'Delete Meal';

  @override
  String get caloriesToday => 'Today\'s Calories';

  @override
  String get totalCalories => 'Total Calories';

  @override
  String get totalGL => 'Total Glycemic Load';

  @override
  String get filterAll => 'All Meals';

  @override
  String get filterBreakfast => 'Breakfast';

  @override
  String get filterLunch => 'Lunch';

  @override
  String get filterDinner => 'Dinner';

  @override
  String get filterSnack => 'Snack';

  @override
  String get emptyState => 'No meals match this filter';

  @override
  String get weeklyTrends => 'Weekly Trends';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  // --- Settings & User Goals ---
  @override
  String get settings => 'Settings';
  @override
  String get settingsTitle => 'Personalized Goals & Thresholds';
  @override
  String get goalFocusTitle => 'Goal Focus';
  @override
  String get goalFocusLabel => 'Primary Health Goal';
  @override
  String get goalMaintenance => 'Maintenance';
  @override
  String get goalWeightLoss => 'Weight Loss';
  @override
  String get goalMuscleGain => 'Muscle Gain';
  @override
  String get goalFasting => 'Fasting Support';
  @override
  String get goalDiabetes => 'Diabetes Management';
  @override
  String get dailyTargetsTitle => 'Daily Targets';
  @override
  String get dailyCalorieTarget => 'Daily Calorie Target';
  @override
  String get dailyProteinTarget => 'Daily Protein Target (g)';
  @override
  String get dailyCarbsTarget => 'Daily Carbs Target (g)';
  @override
  String get dailyFatTarget => 'Daily Fat Target (g)';
  @override
  String get glThresholdsTitle => 'Glycemic Load Thresholds';
  @override
  String get glLowThreshold => 'GL Low Threshold';
  @override
  String get glMediumThreshold => 'GL Medium Threshold';
  @override
  String get dailyGlycemicLoadLimit => 'Daily GL Limit (optional)';
  @override
  String get languageTitle => 'Language';
  @override
  String get languageLabel => 'Preferred Language';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageAmharic => 'Amharic';
  @override
  String get saveSettings => 'Save Changes';
  @override
  String get settingsSaved => 'Settings saved successfully';
  @override
  String get saveFailed => 'Failed to save settings';
}
