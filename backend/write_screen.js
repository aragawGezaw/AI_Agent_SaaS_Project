const fs = require('fs');
const path = 'd:/AI_Agent_SaaS_Project/lib/features/meal_plan/screens/meal_plan_screen.dart';
const content = String.raw`import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../services/meal_plan_api_service.dart';
import '../widgets/meal_card.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime? _selectedDate;
  bool _isFastingDay = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadSavedPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _generatePlan() async {
    final dateStr = _selectedDate != null ? _formatDate(_selectedDate!) : null;
    final provider = context.read<MealPlanProvider>();
    final result = await provider.generateMealPlan(
      planDate: dateStr,
      isFastingDay: _isFastingDay,
    );
    if (!mounted) return;
    if (result != null) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mealPlanGeneratedSuccess),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.aiMealPlanner),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.todaysPlan),
            Tab(text: loc.planHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(loc, isAm),
          _buildHistoryTab(loc, isAm),
        ],
      ),
    );
  }
`;
fs.writeFileSync(path, content + '\n');
console.log('Part 1 written:', content.length, 'chars');
