import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

/// Provider for managing subscription state across the app
class SubscriptionProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final Dio _dio = ApiClient().dio;

  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;

  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasPremiumAccess =>
      _currentSubscription != null &&
      (_currentSubscription!.planType == 'premium' ||
          _currentSubscription!.planType == 'admin');

  bool get isSubscribed => _currentSubscription != null;
  bool get isActive =>
      _currentSubscription != null && _currentSubscription!.isActive;
  String get planType => _currentSubscription?.planType ?? 'free';
  String get status => _currentSubscription?.status ?? 'unknown';
  Map<String, dynamic> get featureGating =>
      _currentSubscription?.featureGating ?? const {};
  bool get isExpired =>
      _currentSubscription != null && _currentSubscription!.isExpired;

  /// Fetch subscription from backend
  Future<void> loadSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/subscription/status');
      if (response.statusCode == 200 && response.data != null) {
        _currentSubscription = Subscription.fromJson(
          response.data as Map<String, dynamic>,
        );
        await _storage.saveSession({
          'subscription': _currentSubscription!.toJson(),
        });
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Failed to load subscription';
      final session = await _storage.getSession();
      if (session?['subscription'] != null) {
        _currentSubscription = Subscription.fromJson(
          session!['subscription'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a Chapa checkout session supporting multi-currency (ETB for local, USD for diaspora)
  Future<String?> createCheckoutSession({
    String amount = '99',
    String currency = 'ETB',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = await _subscriptionService.createCheckoutSession(
        amount: amount,
        currency: currency,
      );
      return url;
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Failed to create checkout';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Verifies transaction with backend and refreshes active subscription
  Future<bool> verifyAndCompletePayment(String txRef) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _subscriptionService.verifyPayment(txRef);
      if (success) {
        await loadSubscription();
      }
      return success;
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Failed to verify payment';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open billing portal
  Future<String?> openBillingPortal() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.post('/subscription/portal');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'] as String?;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      _error = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : e.message ?? 'Failed to open portal';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// Check if user has access to a specific feature
  bool hasFeatureAccess(String feature) {
    return _currentSubscription?.featureGating[feature] == true;
  }

  void reset() {
    _currentSubscription = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> refreshSubscription() async => await loadSubscription();
}
