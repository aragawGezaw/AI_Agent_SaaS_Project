import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_api_service.dart';

/// State management for the AI Meal Planning module.
///
/// Owns:
/// - `currentPlan`: the most recent AI-generated meal plan
/// - `savedPlans`: a list of all meal plans the user has previously generated
/// - `isGenerating` / `isLoadingSaved` loading flags for the two operations
/// - `error` for surfacing user-facing error messages
class MealPlanProvider extends ChangeNotifier {
  final MealPlanApiService _service;

  MealPlanProvider({MealPlanApiService? service})
      : _service = service ?? MealPlanApiService();

  // --- State ---
  MealPlanResponse? _currentPlan;
  List<MealPlan> _savedPlans = [];
  bool _isGenerating = false;
  bool _isLoadingSaved = false;
  String? _error;
  String? _lastGeneratedDate;
  bool _lastFastingPreference = false;

  // --- Getters ---
  MealPlanResponse? get currentPlan => _currentPlan;
  List<MealPlan> get savedPlans => _savedPlans;
  bool get isGenerating => _isGenerating;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;
  String? get lastGeneratedDate => _lastGeneratedDate;
  bool get lastFastingPreference => _lastFastingPreference;
  bool get hasCurrentPlan => _currentPlan != null;
  bool get hasSavedPlans => _savedPlans.isNotEmpty;

  /// Returns the most recent (latest plan_date) set of saved meals, grouped
  /// by date. Used by the history view.
  Map<String, List<MealPlan>> get savedPlansByDate {
    final map = <String, List<MealPlan>>{};
    for (final m in _savedPlans) {
      final key =
          '${m.planDate.year.toString().padLeft(4, '0')}-'
          '${m.planDate.month.toString().padLeft(2, '0')}-'
          '${m.planDate.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(m);
    }
    // Sort each list by meal_type ordering
    const order = ['breakfast', 'lunch', 'dinner', 'snack'];
    for (final list in map.values) {
      list.sort((a, b) {
        final ai = order.indexOf(a.mealType.toLowerCase());
        final bi = order.indexOf(b.mealType.toLowerCase());
        return ai.compareTo(bi);
      });
    }
    return map;
  }

  // --- Actions ---

  /// Request a new AI-generated meal plan from the backend.
  ///
  /// [planDate] (optional) is a `YYYY-MM-DD` string. When null, the server
  /// defaults to today.
  /// [isFastingDay] controls the Ethiopian Orthodox fasting-aware prompt.
  Future<MealPlanResponse?> generateMealPlan({
    String? planDate,
    bool isFastingDay = false,
  }) async {
    _isGenerating = true;
    _error = null;
    _lastGeneratedDate = planDate;
    _lastFastingPreference = isFastingDay;
    notifyListeners();

    try {
      final response = await _service.generateMealPlan(
        planDate: planDate,
        isFastingDay: isFastingDay,
      );
      _currentPlan = response;

      // Prepend new meals to saved list (optimistic update)
      _savedPlans = [...response.meals, ..._savedPlans];

      return response;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Fetch all saved meal plans for the user (optionally filtered by date).
  Future<void> loadSavedPlans({
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    _isLoadingSaved = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.getMealPlans(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      _savedPlans = list;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  /// Delete a saved meal plan by its numeric ID.
  Future<bool> deleteMealPlan(int id) async {
    _error = null;
    try {
      await _service.deleteMealPlan(id);
      _savedPlans = _savedPlans.where((m) => m.id != id).toList();

      // If the deleted meal was part of the currently displayed plan, also
      // remove it from the current plan.
      if (_currentPlan != null) {
        final updatedMeals =
            _currentPlan!.meals.where((m) => m.id != id).toList();
        _currentPlan = MealPlanResponse(
          success: _currentPlan!.success,
          message: _currentPlan!.message,
          planDate: _currentPlan!.planDate,
          isFastingMeal: _currentPlan!.isFastingMeal,
          recommendationSource: _currentPlan!.recommendationSource,
          meals: updatedMeals,
          summary: _calculateSummary(updatedMeals),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  /// Re-compute the MealPlanSummary after meals are deleted client-side.
  MealPlanSummary _calculateSummary(List<MealPlan> meals) {
    final calories = meals.fold<double>(0, (s, m) => s + m.calories);
    final gl = meals.fold<double>(0, (s, m) => s + m.glycemicLoad);
    return MealPlanSummary(
      totalCalories: calories,
      totalGlycemicLoad: gl,
      mealCount: meals.length,
    );
  }

  /// Clear the currently displayed plan (e.g., when user navigates away).
  void clearCurrentPlan() {
    _currentPlan = null;
    notifyListeners();
  }

  /// Reset the entire state (used on logout).
  void reset() {
    _currentPlan = null;
    _savedPlans = [];
    _isGenerating = false;
    _isLoadingSaved = false;
    _error = null;
    _lastGeneratedDate = null;
    _lastFastingPreference = false;
    notifyListeners();
  }

  /// Convert raw exceptions into a user-friendly message.
  String _formatError(Object error) {
    final msg = error.toString();
    // Strip "Exception: " prefix from our service layer for a cleaner display
    return msg.replaceFirst('Exception: ', '');
  }
}
