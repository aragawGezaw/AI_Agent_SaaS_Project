import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_api_service.dart';

/// Provider managing state, loading flags, errors, and caching for the Unified Health Dashboard.
class DashboardProvider extends ChangeNotifier {
  final DashboardApiService _service;

  DashboardProvider({DashboardApiService? service})
      : _service = service ?? DashboardApiService();

  // --- State ---
  DashboardSummary? _summaryData;
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  DashboardSummary? get summaryData => _summaryData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _summaryData != null;

  // --- Actions ---

  /// Fetch or refresh the dashboard summary data.
  Future<void> fetchSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getAnalyticsSummary();
      _summaryData = data;
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the local state cache. Suitable for logouts.
  void clear() {
    _summaryData = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Helper to convert exceptions to clean user-facing descriptions.
  String _formatError(dynamic e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return raw;
  }
}
