import 'package:flutter/material.dart';
import '../models/educational_resource.dart';
import '../services/education_api_service.dart';

/// State notifier for managing the educational resources hub.
/// Handles loading, filtering, searching, and error states.
class EducationProvider extends ChangeNotifier {
  final EducationApiService _service;

  List<EducationalResource> _resources = [];
  List<ResourceCategory> _categories = [];
  String? _selectedCategory;
  String? _searchQuery;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  int _totalCount = 0;

  EducationProvider({EducationApiService? service})
      : _service = service ?? EducationApiService();

  // Getters
  List<EducationalResource> get resources => _resources;
  List<ResourceCategory> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  int get totalCount => _totalCount;

  /// Featured resources shown on the home of the resources screen.
  List<EducationalResource> get featuredResources =>
      _resources.where((r) => r.isFeatured).toList();

  /// Whether a category filter is currently active.
  bool get hasActiveFilter => _selectedCategory != null;

  /// Loads the full list of resources, optionally filtered by category.
  Future<void> loadResources({String? category, String? language}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getResources(
        category: category,
        language: language,
      );
      _resources = result.resources;
      _totalCount = result.total;
      _selectedCategory = category;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the list of categories with their counts.
  Future<void> loadCategories({String? language}) async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      // Non-blocking error: category list failure shouldn't break the screen.
      debugPrint('Failed to load categories: $e');
    }
  }

  /// Loads a single resource by its ID.
  Future<EducationalResource?> loadResourceById(String id) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final resource = await _service.getResourceById(id);
      _isLoadingDetail = false;
      notifyListeners();
      return resource;
    } catch (e) {
      _error = e.toString();
      _isLoadingDetail = false;
      notifyListeners();
      return null;
    }
  }

  /// Sets a category filter and reloads the resource list.
  Future<void> setCategory(String? category) async {
    if (category == _selectedCategory) return;
    await loadResources(category: category);
  }

  /// Clears any active category filter and reloads all resources.
  Future<void> clearCategory() async {
    await loadResources();
  }

  /// Performs a search by a term, using the existing category filter.
  Future<void> search(String term) async {
    if (term.trim().isEmpty) {
      await loadResources(category: _selectedCategory);
      return;
    }
    _isLoading = true;
    _error = null;
    _searchQuery = term;
    notifyListeners();

    try {
      final results = await _service.searchResources(term);
      _resources = results;
      _totalCount = results.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the current view.
  Future<void> refresh() async {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      await search(_searchQuery!);
    } else {
      await loadResources(category: _selectedCategory);
    }
  }

  /// Resets the entire state, including errors and search.
  void reset() {
    _resources = [];
    _selectedCategory = null;
    _searchQuery = null;
    _error = null;
    _isLoading = false;
    _isLoadingDetail = false;
    notifyListeners();
  }
}
