import 'package:flutter/material.dart';
import '../../features/nutrition/models/user_goals_model.dart';
import '../../features/nutrition/services/user_goals_service.dart';

/// State notifier for managing user goals state (loading, error, success).
class UserGoalsNotifier extends ChangeNotifier {
  final UserGoalsService _service;
  UserGoals? _goals;
  bool _isLoading = false;
  String? _error;

  UserGoalsNotifier({UserGoalsService? service})
      : _service = service ?? UserGoalsService();

  UserGoals? get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasGoals => _goals != null;

  /// Fetch user goals from the backend. Creates defaults if none exist.
  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final goals = await _service.getUserGoals();
      _goals = goals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lazily load goals if not already loaded
  Future<void> ensureLoaded() async {
    if (!_isLoading && !hasGoals) {
      await loadGoals();
    }
  }

  /// Update goals with the provided data.
  /// This merges with existing defaults and persists to the backend.
  Future<void> saveGoals(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedGoals = await _service.updateUserGoals(updates);
      _goals = updatedGoals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convenience method to save goals
  Future<void> save(Map<String, dynamic> updates) async {
    await saveGoals(updates);
  }

  /// Reset/clear goals state
  void reset() {
    _goals = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}