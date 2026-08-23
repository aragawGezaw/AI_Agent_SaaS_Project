import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveSession(Map<String, dynamic> sessionData) async {
    await _storage.write(key: 'session_data', value: jsonEncode(sessionData));
  }

  Future<Map<String, dynamic>?> getSession() async {
    final String? jsonString = await _storage.read(key: 'session_data');
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<void> removeSession() async {
    await _storage.delete(key: 'session_data');
  }
}
