import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthState with ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Handles user login. Returns true on success, false on failure.
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred during login.';
      notifyListeners();
      return false;
    }
  }

  /// Handles user registration. Returns true on success, false on failure.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'am',
  }) async {
    _isLoading = true;
    _errorMessage = '';
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
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred during registration.';
      notifyListeners();
      return false;
    }
  }

  /// NEW: Handles user logout session clearing
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout(); // Clears stored tokens/session
    } catch (e) {
      // Handle or ignore cleanup errors if necessary
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
