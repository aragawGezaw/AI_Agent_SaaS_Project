import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// NotificationProvider — manages FCM registration, local notification setup,
/// and routes notification taps to the appropriate screen.
///
/// Usage:
///   1. Call `init()` early in app startup (e.g. after auth).
///   2. Listen to `onNotificationTap` stream to react to taps.
///   3. Call `dispose()` on logout.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  String? _fcmToken;
  NotificationPreferences _prefs = const NotificationPreferences();
  List<NotificationLogEntry> _log = [];
  List<FastingDay> _upcomingFasts = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Stream controller for notification tap events (deep-link routing)
  final _tapController = _NotificationTapController();

  String? get fcmToken => _fcmToken;
  NotificationPreferences get prefs => _prefs;
  List<NotificationLogEntry> get log => _log;
  List<FastingDay> get upcomingFasts => _upcomingFasts;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  Stream<TapEvent> get onNotificationTap => _tapController.stream;

  // --- Initialization ---

  Future<void> init() async {
    if (_isInitialized) return;

    await _setupLocalNotifications();
    await _loadPreferences();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _setupLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );
    } catch (e) {
      debugPrint('Local notifications init failed: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    final data = _parsePayload(payload);
    final route = data['route'] ?? '/home';
    _tapController.add(TapEvent(route: route, payload: data));
  }

  Map<String, String> _parsePayload(String payload) {
    if (payload.isEmpty) return {};
    try {
      if (payload.startsWith('{')) {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      } else {
        return Uri.splitQueryString(payload);
      }
    } catch (_) {
      return {'route': payload};
    }
  }

  // --- FCM token management ---

  /// Call this with the token obtained from FirebaseMessaging.getToken().
  Future<void> setFcmToken(String token) async {
    if (_fcmToken == token) return;
    _fcmToken = token;
    await _service.registerToken(
      token,
      deviceType: NotificationService.deviceType,
      deviceName: _deviceName,
    );
  }

  String get _deviceName {
    return Platform.isAndroid ? 'Android Device' : (Platform.isIOS ? 'iOS Device' : 'Web Device');
  }

  Future<void> disposeToken() async {
    if (_fcmToken != null) {
      await _service.unregisterToken(_fcmToken!);
      _fcmToken = null;
    }
  }

  // --- Preferences ---

  Future<void> _loadPreferences() async {
    _prefs = await _service.getPreferences();
    notifyListeners();
  }

  Future<bool> updatePreferences(NotificationPreferences prefs) async {
    final ok = await _service.updatePreferences(prefs);
    if (ok) {
      _prefs = prefs;
      notifyListeners();
    }
    return ok;
  }

  // --- Notification log ---

  Future<void> loadLog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _log = await _service.getNotificationLog();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Fasting days ---

  Future<void> loadUpcomingFasts({int days = 60}) async {
    try {
      _upcomingFasts = await _service.getUpcomingFasts(days: days);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load fasting days: $e');
    }
  }

  // --- Test ---

  Future<bool> sendTestNotification() async {
    return _service.sendTestNotification();
  }

  // --- Reset (on logout) ---

  Future<void> reset() async {
    await disposeToken();
    _log = [];
    _upcomingFasts = [];
    _prefs = const NotificationPreferences();
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }

  // --- Local notification display (for foreground FCM messages) ---

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Show a local notification (called by FCM onMessage handler in main.dart).
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'health_reminders',
      'Health Reminders',
      channelDescription: 'Meal logging, fasting, and health reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}

/// Internal stream controller for notification tap routing events.
class _NotificationTapController {
  final _controller = StreamController<TapEvent>.broadcast();
  Stream<TapEvent> get stream => _controller.stream;
  void add(TapEvent event) => _controller.add(event);
  void dispose() => _controller.close();
}

/// A notification tap event carrying the target route and optional payload.
class TapEvent {
  final String route;
  final Map<String, String> payload;
  const TapEvent({required this.route, required this.payload});
}
