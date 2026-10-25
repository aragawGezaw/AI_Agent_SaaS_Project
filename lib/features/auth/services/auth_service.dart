import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/constants/app_constants.dart';

/// Exception thrown when an authentication request fails.
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthException($statusCode):$message';
}

/// Service class for handling authentication operations (login & register).
///
/// Uses the `http` package for network requests and [SecureStorageService]
/// for persisting the JWT token locally.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SecureStorageService _storage = SecureStorageService();

  /// Base URL for the backend API.
  static String get baseUrl => AppConstants.baseUrl;

  /// Login a user with email and password.
  ///
  /// On success, saves the JWT token via [SecureStorageService] and returns
  /// the parsed user map.
  ///
  /// Throws [AuthException] for 4xx/5xx responses or network failures.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      final response = await http
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, action: 'login');
    } on SocketException {
      throw AuthException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw AuthException('The request timed out. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during login.');
    }
  }

  /// Register a new user.
  ///
  /// On success, returns the parsed user map from the response.
  ///
  /// Throws [AuthException] for 4xx/5xx responses or network failures.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String preferredLanguage = 'am',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      final response = await http
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.acceptHeader: 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'full_name': fullName.trim(),
              'preferred_language': preferredLanguage,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, action: 'register');
    } on SocketException {
      throw AuthException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw AuthException('The request timed out. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during registration.');
    }
  }

  /// Returns the currently stored JWT token, if any.
  Future<String?> getToken() => _storage.getToken();

  /// Saves the JWT token to secure storage.
  Future<void> saveToken(String token) => _storage.saveToken(token);

  /// Clears the stored token and session from secure storage.
  Future<void> logout() async {
    await _storage.removeToken();
    await _storage.removeSession();
  }

  /// Centralised response handler for login/register endpoints.
  Map<String, dynamic> _handleResponse(
    http.Response response, {
    required String action,
  }) {
    late final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(
        'Invalid response from server. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (body['message'] is String)
          ? body['message'] as String
          : body['error'] is String
          ? body['error'] as String
          : 'An unexpected error occurred';
      throw AuthException(message, statusCode: response.statusCode);
    }

    if (action == 'login') {
      final token = body['token'] as String?;
      if (token != null && token.isNotEmpty) {
        _storage.saveToken(token);
      }
    }

    final user = body['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw AuthException(
        'Unexpected response format from server.',
        statusCode: response.statusCode,
      );
    }

    return user;
  }
}
