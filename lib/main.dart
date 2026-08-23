import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_screen.dart';
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
                appBar: AppBar(title: const Text('Home')),
                body: const Center(
                  child: Text('Welcome to Smart Nutrition & Health Home!'),
                ),
              ),
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
