import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_screen.dart';
import 'features/nutrition/screens/meal_logging_screen.dart';
import 'features/nutrition/screens/meal_history_screen.dart';
import 'features/nutrition/screens/settings_screen.dart';
import 'features/education/providers/education_provider.dart';
import 'features/education/screens/resources_screen.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/user_goals_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserGoalsNotifier()),
        ChangeNotifierProvider(
          create: (_) => EducationProvider(),
        ), // Added provider
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'Smart Nutrition and Health',
            theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
            locale: languageProvider.locale,
            home: const AuthScreen(),
            routes: {
              '/home': (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Smart Nutrition & Health'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome to Smart Nutrition & Health Home!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.restaurant_menu_rounded),
                        label: const Text('Open Meal Logger & GL Tracker'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MealLoggingScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Educational Resource Hub'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/resources',
                        ), // Added navigation button
                      ),
                    ],
                  ),
                ),
              ),
              '/meal-logging': (context) => const MealLoggingScreen(),
              '/meal-history': (context) => const MealHistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/resources': (context) => const ResourcesScreen(), // Added route
            },
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
