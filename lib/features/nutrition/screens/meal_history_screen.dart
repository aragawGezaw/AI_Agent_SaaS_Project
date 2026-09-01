import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../models/meal_history_item.dart';
import '../models/weekly_trend_data.dart';
import '../services/meal_history_service.dart';
import '../widgets/meal_history_card.dart';
import '../widgets/calorie_summary_header.dart';
import '../widgets/weekly_trends_card.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final MealHistoryService _service = MealHistoryService();

  List<MealHistoryItem> _meals = [];
  bool _loading = true;
  String? _error;
  String _filterMealType = 'all';

  // Weekly trends data
  WeeklyTrendResponse? _weeklyTrends;
  bool _trendsLoading = false;
  String? _trendsError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    setState(() {
      _trendsLoading = true;
      _trendsError = null;
    });
    try {
      final trends = await _service.getWeeklyTrends();
      if (mounted) {
        setState(() {
          _weeklyTrends = trends;
          _trendsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _trendsError = e.toString();
          _trendsLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getHistory(
        limit: 100,
        mealType: _filterMealType == 'all' ? null : _filterMealType,
      );
      if (mounted) {
        setState(() {
          _meals = result['meals'] as List<MealHistoryItem>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteMeal(String id) async {
    try {
      await _service.deleteMeal(id);
      if (mounted) {
        setState(() => _meals.removeWhere((m) => m.id == id));
        final isAm = Localizations.localeOf(context).languageCode == 'am';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAm ? 'ምግብ ተሰርዟል' : 'Meal deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _changeFilter(String filter) {
    setState(() => _filterMealType = filter);
    _loadHistory();
  }

  List<MealHistoryItem> get _todayMeals {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _meals
        .where((m) => m.loggedAt.isAfter(startOfDay) && m.loggedAt.isBefore(endOfDay))
        .toList();
  }

  int get _todayCalories => _todayMeals.fold<int>(0, (sum, m) => sum + m.calories);
  double get _todayGL => _todayMeals.fold<double>(0.0, (sum, m) => sum + m.totalGlycemicLoad);
  int get _totalCalories => _meals.fold<int>(0, (sum, m) => sum + m.calories);
  double get _totalGL => _meals.fold<double>(0.0, (sum, m) => sum + m.totalGlycemicLoad);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isAm = langCode == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.mealHistory,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isAm ? 'ዳግም ጫን' : 'Refresh',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          WeeklyTrendsCard(
            trendsData: _weeklyTrends,
            isLoading: _trendsLoading,
            error: _trendsError,
          ),
          CalorieSummaryHeader(
            todayCalories: _todayCalories,
            totalCalories: _totalCalories,
            todayGL: _todayGL,
            totalGL: _totalGL,
            mealCount: _meals.length,
          ),
          _buildFilterChips(localizations, isAm),
          Expanded(child: _buildMealList(localizations, isAm)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations localizations, bool isAm) {
    final filters = <String, String>{
      'all': localizations.filterAll,
      'breakfast': localizations.filterBreakfast,
      'lunch': localizations.filterLunch,
      'dinner': localizations.filterDinner,
      'snack': localizations.filterSnack,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: filters.entries.map((entry) {
          final selected = _filterMealType == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => _changeFilter(entry.key),
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealList(AppLocalizations localizations, bool isAm) {
    if (_loading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                localizations.emptyState,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isAm ? 'እንደገና ሞክር' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                localizations.noMealsLogged,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          final meal = _meals[index];
          return MealHistoryCard(
            meal: meal,
            onDelete: () => _deleteMeal(meal.id),
          );
        },
      ),
    );
  }
}
