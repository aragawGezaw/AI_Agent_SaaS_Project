import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final Dio _dio;

  SubscriptionService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<Subscription?> getSubscriptionStatus() async {
    try {
      final response = await _dio.get('/subscription/status');
      if (response.statusCode == 200 && response.data != null) {
        return Subscription.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch subscription status',
      );
    }
    return null;
  }

  Future<String> createCheckoutSession() async {
    try {
      final response = await _dio.post('/subscription/checkout');
      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url == null) throw Exception('No checkout URL returned');
        return url;
      }
      throw Exception('Failed to create checkout session');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create checkout session',
      );
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
      throw Exception(
        e.response?.data['message'] ?? 'Failed to open billing portal',
      );
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final response = await _dio.post('/subscription/cancel');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to cancel subscription',
      );
    }
  }

  Future<bool> resumeSubscription() async {
    try {
      final response = await _dio.post('/subscription/resume');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to resume subscription',
      );
    }
  }
}
