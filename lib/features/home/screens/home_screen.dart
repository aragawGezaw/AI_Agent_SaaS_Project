// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/responsive_scaffold.dart';
import '../../nutrition/screens/meal_logging_screen.dart';
import '../../nutrition/screens/settings_screen.dart';

import '../../subscription/screens/paywall_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Smart Nutrition & Health',
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Smart Nutrition & Health Home!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureButton(
                context,
                title: 'Open Meal Logger & GL Tracker',
                icon: Icons.restaurant_menu_rounded,
                backgroundColor: Colors.green,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealLoggingScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureButton(
                context,
                title: 'Educational Resource Hub',
                icon: Icons.menu_book,
                backgroundColor: const Color(0xFF2E7D32),
                onPressed: () => Navigator.pushNamed(context, '/resources'),
              ),
              const SizedBox(height: 12),
              _buildFeatureButton(
                context,
                title: 'AI Meal Planner',
                icon: Icons.auto_awesome_rounded,
                backgroundColor: const Color(0xFF6A1B9A),
                onPressed: () => Navigator.pushNamed(context, '/meal-plan'),
              ),
              const SizedBox(height: 12),
              _buildFeatureButton(
                context,
                title: 'Upgrade to Premium',
                icon: Icons.workspace_premium_rounded,
                backgroundColor: Colors.orange.shade700,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 320,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }
}
