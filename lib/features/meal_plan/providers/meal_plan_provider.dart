import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/subscription_error_interceptor.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_api_service.dart';

/// State management for the AI Meal Planning module with offline resilience.
class MealPlanProvider extends ChangeNotifier {
  final MealPlanApiService _service;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _cachedPlansKey = 'cached_meal_plans_key';

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
  SubscriptionRequiredException? _subscriptionError;

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
  SubscriptionRequiredException? get subscriptionError => _subscriptionError;

  Map<String, List<MealPlan>> get savedPlansByDate {
    final map = <String, List<MealPlan>>{};
    for (final m in _savedPlans) {
      // Convert to local time to prevent UTC timezone date shifting
      final localDate = m.planDate.toLocal();
      final key =
          '${localDate.year.toString().padLeft(4, '0')}-'
          '${localDate.month.toString().padLeft(2, '0')}-'
          '${localDate.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(m);
    }
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

  Future<MealPlanResponse?> generateMealPlan({
    String? planDate,
    bool isFastingDay = false,
    String languageCode = 'am', // Defaults to Amharic
  }) async {
    _isGenerating = true;
    _error = null;
    _subscriptionError = null;
    _lastGeneratedDate = planDate;
    _lastFastingPreference = isFastingDay;
    notifyListeners();

    try {
      final response = await _service.generateMealPlan(
        planDate: planDate,
        isFastingDay: isFastingDay,
        language: languageCode,
      );
      _currentPlan = response;
      _savedPlans = [...response.meals, ..._savedPlans];

      // Cache updated saved plans locally for offline access
      await _cacheSavedPlansLocally(_savedPlans);

      return response;
    } on SubscriptionRequiredException catch (e) {
      _subscriptionError = e;
      _error = e.message ?? 'Premium subscription required';
      return null;
    } catch (e) {
      _error = _formatError(e);
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

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

      // Successfully fetched from server -> update local cache
      await _cacheSavedPlansLocally(list);
    } catch (e) {
      // OFFLINE FALLBACK: Load from secure storage cache if network fails
      final cachedList = await _loadCachedPlansLocally();
      if (cachedList.isNotEmpty) {
        _savedPlans = cachedList;
        _error = null; // Clear error since offline cache successfully loaded
      } else {
        _error = _formatError(e);
      }
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMealPlan(int id) async {
    _error = null;
    try {
      await _service.deleteMealPlan(id);
      _savedPlans = _savedPlans.where((m) => m.id != id).toList();

      // Update local cache after deletion
      await _cacheSavedPlansLocally(_savedPlans);

      if (_currentPlan != null) {
        final updatedMeals = _currentPlan!.meals
            .where((m) => m.id != id)
            .toList();
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

  // --- Local Caching Helpers ---

  Future<void> _cacheSavedPlansLocally(List<MealPlan> plans) async {
    try {
      final jsonString = jsonEncode(plans.map((m) => m.toJson()).toList());
      await _secureStorage.write(key: _cachedPlansKey, value: jsonString);
    } catch (_) {
      // Ignore caching errors silently
    }
  }

  Future<List<MealPlan>> _loadCachedPlansLocally() async {
    try {
      final jsonString = await _secureStorage.read(key: _cachedPlansKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((item) => MealPlan.fromJson(item)).toList();
      }
    } catch (_) {
      // Ignore decryption/parsing errors silently
    }
    return [];
  }

  MealPlanSummary _calculateSummary(List<MealPlan> meals) {
    final calories = meals.fold<double>(0, (s, m) => s + m.calories);
    final gl = meals.fold<double>(0, (s, m) => s + m.glycemicLoad);
    return MealPlanSummary(
      totalCalories: calories,
      totalGlycemicLoad: gl,
      mealCount: meals.length,
    );
  }

  void clearCurrentPlan() {
    _currentPlan = null;
    notifyListeners();
  }

  void clearSubscriptionError() {
    _subscriptionError = null;
    notifyListeners();
  }

  void reset() {
    _currentPlan = null;
    _savedPlans = [];
    _isGenerating = false;
    _isLoadingSaved = false;
    _error = null;
    _lastGeneratedDate = null;
    _lastFastingPreference = false;
    _subscriptionError = null;
    notifyListeners();
  }

  String _formatError(Object error) {
    final msg = error.toString();
    return msg.replaceFirst('Exception: ', '');
  }
}
