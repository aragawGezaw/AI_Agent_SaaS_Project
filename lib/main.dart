import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/user_goals_provider.dart';
import 'features/auth/controllers/auth_state.dart';
import 'features/education/providers/education_provider.dart';
import 'features/meal_plan/providers/meal_plan_provider.dart';
import 'features/subscription/providers/subscription_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/subscription/screens/subscription_success_screen.dart';
import 'l10n/app_localizations.dart';

/// Global navigator key for routing paywall pushes from interceptors.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  usePathUrlStrategy();
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
        ChangeNotifierProvider(create: (_) => EducationProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: 'Smart Nutrition and Health',
            theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
            locale: languageProvider.locale,
            initialRoute: AppRoutes.login,
            routes: AppRoutes.routes,
            onGenerateRoute: (settings) {
              final uri = Uri.tryParse(settings.name ?? '');

              // Handle both Chapa (/payment-success or /subscription/success) and Stripe returns
              if (uri != null &&
                  (uri.path == '/subscription/success' ||
                      uri.path == '/payment-success')) {
                final txRef =
                    uri.queryParameters['tx_ref'] ??
                    Uri.base.queryParameters['tx_ref'];

                final sessionId =
                    uri.queryParameters['session_id'] ??
                    Uri.base.queryParameters['session_id'];

                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => SubscriptionSuccessScreen(
                    txRef: txRef,
                    sessionId: sessionId,
                  ),
                );
              }
              return null;
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
