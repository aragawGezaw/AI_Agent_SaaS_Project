// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/nutrition/screens/meal_logging_screen.dart';
import '../../features/nutrition/screens/meal_history_screen.dart';
import '../../features/nutrition/screens/settings_screen.dart';
import '../../features/education/screens/resources_screen.dart';
import '../../features/meal_plan/screens/meal_plan_screen.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String mealPlan = '/meal-plan';
  static const String mealLogging = '/meal-logging';
  static const String mealHistory = '/meal-history';
  static const String settings = '/settings';
  static const String resources = '/resources';
  static const String paywall = '/paywall';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    mealPlan: (context) => const MealPlanScreen(),
    mealLogging: (context) => const MealLoggingScreen(),
    mealHistory: (context) => const MealHistoryScreen(),
    settings: (context) => const SettingsScreen(),
    resources: (context) => const ResourcesScreen(),
    paywall: (context) => const PaywallScreen(),
    notifications: (context) => const NotificationSettingsScreen(),
  };
}
