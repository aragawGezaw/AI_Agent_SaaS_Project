import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // Use the singleton instance instead of calling AuthService()
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Pass parameters as named arguments
      await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _isLoading = false;
      // Clean up the exception message for UI display
      _errorMessage = e
          .toString()
          .replaceAll(RegExp(r'^AuthException\(.*?\):'), '')
          .replaceAll('Exception: ', '')
          .trim();
      notifyListeners();
      return false; // Failure
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'am',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        preferredLanguage: preferredLanguage,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e
          .toString()
          .replaceAll(RegExp(r'^AuthException\(.*?\):'), '')
          .replaceAll('Exception: ', '')
          .trim();
      notifyListeners();
      return false;
    }
  }
}
