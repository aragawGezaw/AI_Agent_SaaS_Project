import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_screen.dart';
import 'features/nutrition/screens/meal_logging_screen.dart';
import 'features/nutrition/screens/meal_history_screen.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/language_provider.dart';

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
                appBar: AppBar(title: const Text('Smart Nutrition & Health')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Welcome to Smart Nutrition & Health Home!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        icon: const Icon(Icons.restaurant_menu_rounded),
                        label: const Text('Open Meal Logger & GL Tracker'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              '/meal-logging': (context) => const MealLoggingScreen(),
              '/meal-history': (context) => const MealHistoryScreen(),
            },
            debugShowCheckedModeBanner: false,
            // Phase 2 Localization Setup
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
