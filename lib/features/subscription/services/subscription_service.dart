import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final Dio _dio;

  SubscriptionService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  /// Helper to safely extract error messages from Dio exceptions
  String _extractErrorMessage(DioException e, String fallbackMessage) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallbackMessage;
  }

  Future<Subscription?> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscription/status');
      if (response.statusCode == 200 && response.data != null) {
        return Subscription.fromJson(response.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to fetch subscription status'),
      );
    }
    return null;
  }

  /// Initializes a Chapa payment session supporting local ETB and global USD currency
  Future<String> createCheckoutSession({
    String amount = '99',
    String currency = 'ETB',
  }) async {
    try {
      final response = await _dio.post(
        '/payment/initialize',
        data: {
          'amount': amount,
          'currency': currency.toUpperCase(),
          'moduleType': 'subscription',
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['checkoutUrl'] as String?;
        if (url == null) throw Exception('No checkout URL returned');
        return url;
      }
      throw Exception('Failed to create checkout session');
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to create checkout session'),
      );
    }
  }

  /// Verifies Chapa transaction with backend
  Future<bool> verifyPayment(String txRef) async {
    try {
      final response = await _dio.get('/payment/verify/$txRef');
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to verify payment'));
    }
  }

  Future<String> openBillingPortal() async {
    try {
      final response = await _dio.post('/subscription/portal');
      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url == null) throw Exception('No portal URL returned');
        return url;
      }
      throw Exception('Failed to open billing portal');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to open billing portal'));
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final response = await _dio.post('/subscription/cancel');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to cancel subscription'));
    }
  }

  Future<bool> resumeSubscription() async {
    try {
      final response = await _dio.post('/subscription/resume');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to resume subscription'));
    }
  }
}
