import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Nutrition'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @mealHistory.
  ///
  /// In en, this message translates to:
  /// **'Meal History'**
  String get mealHistory;

  /// No description provided for @mealHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Nutritional Journey'**
  String get mealHistoryTitle;

  /// No description provided for @noMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet. Start tracking your nutrition!'**
  String get noMealsLogged;

  /// No description provided for @deleteMeal.
  ///
  /// In en, this message translates to:
  /// **'Delete Meal'**
  String get deleteMeal;

  /// No description provided for @caloriesToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Calories'**
  String get caloriesToday;

  /// No description provided for @totalCalories.
  ///
  /// In en, this message translates to:
  /// **'Total Calories'**
  String get totalCalories;

  /// No description provided for @totalGL.
  ///
  /// In en, this message translates to:
  /// **'Total Glycemic Load'**
  String get totalGL;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All Meals'**
  String get filterAll;

  /// No description provided for @filterBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get filterBreakfast;

  /// No description provided for @filterLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get filterLunch;

  /// No description provided for @filterDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get filterDinner;

  /// No description provided for @filterSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get filterSnack;

  /// No description provided for @emptyState.
  ///
  /// In en, this message translates to:
  /// **'No meals match this filter'**
  String get emptyState;

  /// No description provided for @weeklyTrends.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trends'**
  String get weeklyTrends;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @goalFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Goal Focus'**
  String get goalFocusTitle;

  /// No description provided for @goalFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Select your primary health goal'**
  String get goalFocusLabel;

  /// No description provided for @goalMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintain Current Weight'**
  String get goalMaintenance;

  /// No description provided for @goalWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get goalWeightLoss;

  /// No description provided for @goalMuscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle Gain'**
  String get goalMuscleGain;

  /// No description provided for @goalFasting.
  ///
  /// In en, this message translates to:
  /// **'Fasting Support'**
  String get goalFasting;

  /// No description provided for @goalDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Management'**
  String get goalDiabetes;

  /// No description provided for @dailyTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Nutritional Targets'**
  String get dailyTargetsTitle;

  /// No description provided for @dailyCalorieTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Calorie Target (kcal)'**
  String get dailyCalorieTarget;

  /// No description provided for @dailyProteinTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Protein Target (g)'**
  String get dailyProteinTarget;

  /// No description provided for @dailyCarbsTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Carbohydrates Target (g)'**
  String get dailyCarbsTarget;

  /// No description provided for @dailyFatTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Fat Target (g)'**
  String get dailyFatTarget;

  /// No description provided for @glThresholdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Glycemic Load Thresholds'**
  String get glThresholdsTitle;

  /// No description provided for @glLowThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low GL Threshold'**
  String get glLowThreshold;

  /// No description provided for @glMediumThreshold.
  ///
  /// In en, this message translates to:
  /// **'Medium GL Threshold'**
  String get glMediumThreshold;

  /// No description provided for @dailyGlycemicLoadLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily Glycemic Load Limit'**
  String get dailyGlycemicLoadLimit;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Preference'**
  String get languageTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAmharic.
  ///
  /// In en, this message translates to:
  /// **'አመርኛ (Amharic)'**
  String get languageAmharic;

  /// Title of the educational resources hub screen
  ///
  /// In en, this message translates to:
  /// **'Resource Hub'**
  String get resourceHub;

  /// Search field placeholder for resources
  ///
  /// In en, this message translates to:
  /// **'Search resources...'**
  String get searchResources;

  /// Empty state when no resources are available
  ///
  /// In en, this message translates to:
  /// **'No resources found'**
  String get noResources;

  /// Empty state when search yields no results
  ///
  /// In en, this message translates to:
  /// **'No search results found'**
  String get noSearchResults;

  /// Featured resource badge label
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// View count suffix
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get views;

  /// Video indicator label
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// Video tutorial section title
  ///
  /// In en, this message translates to:
  /// **'Video Tutorial'**
  String get videoTutorial;

  /// Watch video button label
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// Back navigation button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Refresh action
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Error message when a resource is not found
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get resourceNotFound;

  /// Nutrition category label
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get eduCategoryNutrition;

  /// Glycemic Index category label
  ///
  /// In en, this message translates to:
  /// **'Glycemic Index'**
  String get eduCategoryGlycemicIndex;

  /// Fasting category label
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get eduCategoryFasting;

  /// Recipes category label
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get eduCategoryRecipes;

  /// Health Tips category label
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get eduCategoryHealthTips;

  /// Exercise category label
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get eduCategoryExercise;

  /// Title of the AI meal planner screen
  ///
  /// In en, this message translates to:
  /// **'AI Meal Planner'**
  String get aiMealPlanner;

  /// First tab label for the latest generated plan
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get todaysPlan;

  /// Second tab label for saved plan history
  ///
  /// In en, this message translates to:
  /// **'Plan History'**
  String get planHistory;

  /// Heading on the generate-plan card
  ///
  /// In en, this message translates to:
  /// **'Generate New Plan'**
  String get generateNewPlan;

  /// Subheading on the generate-plan card
  ///
  /// In en, this message translates to:
  /// **'AI will create a personalized 4-meal plan for you'**
  String get aiWillCreatePersonalizedPlan;

  /// Button label to open the date picker
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Clear button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Toggle label for Ethiopian Orthodox fasting
  ///
  /// In en, this message translates to:
  /// **'Fasting Day'**
  String get fastingDay;

  /// Primary CTA button label to generate an AI meal plan
  ///
  /// In en, this message translates to:
  /// **'Generate Plan'**
  String get generatePlan;

  /// Loading state label while AI generates the plan
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// Snackbar success message after plan generation
  ///
  /// In en, this message translates to:
  /// **'Meal plan generated successfully!'**
  String get mealPlanGeneratedSuccess;

  /// Empty state message in the history tab
  ///
  /// In en, this message translates to:
  /// **'No saved meal plans found'**
  String get noMealPlansFound;

  /// Helper text under empty state
  ///
  /// In en, this message translates to:
  /// **'Generate a plan from the Generate tab above'**
  String get generateFirstPlan;

  /// Title of the health analytics dashboard screen
  ///
  /// In en, this message translates to:
  /// **'Health Dashboard'**
  String get healthDashboard;

  /// Heading for the weekly summary section
  ///
  /// In en, this message translates to:
  /// **'7-Day Overview'**
  String get weeklyOverview;

  /// Heading for today's metrics section
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// Label for calories metric
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// Label for glycemic load metric
  ///
  /// In en, this message translates to:
  /// **'Glycemic Load'**
  String get glycemicLoad;

  /// Label for protein macro
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// Label for carbohydrates macro
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// Label for fat macro
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// Label for meal count metric
  ///
  /// In en, this message translates to:
  /// **'Meals Logged'**
  String get mealsLogged;

  /// Suffix for daily average values
  ///
  /// In en, this message translates to:
  /// **'Avg / Day'**
  String get avgDaily;

  /// Label for total values
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Label for goal/target values
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// Progress label showing percentage of daily target
  ///
  /// In en, this message translates to:
  /// **'{value}% of target'**
  String ofTarget(int value);

  /// Low glycemic load status label
  ///
  /// In en, this message translates to:
  /// **'Low GL'**
  String get glycemicLoadLow;

  /// Moderate glycemic load status label
  ///
  /// In en, this message translates to:
  /// **'Moderate GL'**
  String get glycemicLoadModerate;

  /// Exceeded glycemic load status label
  ///
  /// In en, this message translates to:
  /// **'GL Exceeded'**
  String get glycemicLoadExceeded;

  /// Abbreviation for kilocalories
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// Abbreviation for grams
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get g;

  /// Empty state when no meal history data is available
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet'**
  String get noAnalyticsData;

  /// Helper text under empty analytics state
  ///
  /// In en, this message translates to:
  /// **'Start logging meals to see your health analytics'**
  String get startTrackingMeals;

  /// Quick-nav button to navigate to the AI meal plan screen
  ///
  /// In en, this message translates to:
  /// **'View Today\'s Meal Plan'**
  String get viewTodaysMealPlan;

  /// Quick-nav button to navigate to the meal history screen
  ///
  /// In en, this message translates to:
  /// **'View Food Log'**
  String get viewFoodLog;

  /// Heading for the metabolic gauge section
  ///
  /// In en, this message translates to:
  /// **'Metabolic Health'**
  String get metabolicHealth;

  /// Heading for macro distribution section
  ///
  /// In en, this message translates to:
  /// **'Nutrient Breakdown'**
  String get nutrientBreakdown;

  /// Heading for macro pie/distribution chart
  ///
  /// In en, this message translates to:
  /// **'Macros Distribution'**
  String get macrosDistribution;

  /// Label for today's date/time reference
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
