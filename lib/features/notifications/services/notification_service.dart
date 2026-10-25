import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/notification_model.dart';

/// NotificationService
///
/// Thin wrapper over Firebase Messaging + local notifications.
/// Handles:
///  - FCM token registration/unregistration with the backend
///  - Local notification display (for foreground messages)
///  - Permission requests
///
/// The actual push-to-foreground (in-app) display is handled by
/// NotificationProvider, which subscribes to FCM onMessage / onMessageOpened
/// streams and calls the local notification plugin.
class NotificationService {
  final Dio _dio = ApiClient().dio;

  /// Register the device FCM token with the backend.
  Future<bool> registerToken(String token, {String? deviceType, String? deviceName}) async {
    try {
      final response = await _dio.post(
        '/notifications/register-token',
        data: {
          'token': token,
          ...deviceType != null ? {'deviceType': deviceType} : {},
          ...deviceName != null ? {'deviceName': deviceName} : {},
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Failed to register FCM token: ${e.message}');
      return false;
    }
  }

  /// Unregister the device FCM token from the backend.
  Future<bool> unregisterToken(String token) async {
    try {
      final response = await _dio.delete(
        '/notifications/unregister-token',
        data: {'token': token},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Failed to unregister FCM token: ${e.message}');
      return false;
    }
  }

  /// Fetch the user's notification preferences from the backend.
  Future<NotificationPreferences> getPreferences() async {
    try {
      final response = await _dio.get('/notifications/preferences');
      if (response.statusCode == 200 && response.data != null) {
        return NotificationPreferences.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } on DioException catch (e) {
      debugPrint('Failed to get notification prefs: ${e.message}');
    }
    return const NotificationPreferences();
  }

  /// Update the user's notification preferences on the backend.
  Future<bool> updatePreferences(NotificationPreferences prefs) async {
    try {
      final response = await _dio.put(
        '/notifications/preferences',
        data: prefs.toJson(),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Failed to update notification prefs: ${e.message}');
      return false;
    }
  }

  /// Fetch upcoming Ethiopian Orthodox fasting days from the backend.
  Future<List<FastingDay>> getUpcomingFasts({int days = 60}) async {
    try {
      final response = await _dio.get(
        '/notifications/upcoming-fasts',
        queryParameters: {'days': days},
      );
      if (response.statusCode == 200 && response.data != null) {
        final fasts = (response.data['fasts'] as List?)
            ?.map((e) => FastingDay.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        return fasts;
      }
    } on DioException catch (e) {
      debugPrint('Failed to get fasting days: ${e.message}');
    }
    return [];
  }

  /// Fetch the user's notification history log from the backend.
  Future<List<NotificationLogEntry>> getNotificationLog({int limit = 30}) async {
    try {
      final response = await _dio.get(
        '/notifications/log',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['notifications'] as List?)
                ?.map((e) => NotificationLogEntry.fromJson(e as Map<String, dynamic>))
                .toList() ?? [];
      }
    } on DioException catch (e) {
      debugPrint('Failed to get notification log: ${e.message}');
    }
    return [];
  }

  /// Mark a notification as opened (for analytics).
  Future<void> markOpened(String notificationId) async {
    try {
      await _dio.post(
        '/notifications/mark-opened',
        data: {'notificationId': notificationId},
      );
    } on DioException catch (e) {
      debugPrint('Failed to mark notification opened: ${e.message}');
    }
  }

  /// Send a test push notification to the current user.
  Future<bool> sendTestNotification() async {
    try {
      final response = await _dio.post('/notifications/test');
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Failed to send test notification: ${e.message}');
      return false;
    }
  }

  /// Detects the current device type string.
  static String get deviceType {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (kIsWeb) return 'web';
    return 'unknown';
  }
}
