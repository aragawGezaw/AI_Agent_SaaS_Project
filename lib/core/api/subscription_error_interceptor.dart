import 'package:dio/dio.dart';

/// Exception thrown when subscription is required (403 with subscription error code).
class SubscriptionRequiredException extends DioException {
  final List<String> features;
  final String? code;

  SubscriptionRequiredException({
    required String message,
    this.features = const [],
    this.code,
  }) : super(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
          message: message,
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 403,
          ),
        );
}

/// Interceptor that catches subscription-related 403 errors and transforms
/// them into typed SubscriptionRequiredException for the paywall UI.
class SubscriptionErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == 403 && err.response?.data is Map) {
      final data = err.response!.data as Map<String, dynamic>;
      final errorCode = data['code'] as String?;
      final errorMsg = data['message'] as String?;

      if (_isSubscriptionError(errorCode)) {
        final features = <String>[];
        if (data['features'] is List) {
          features.addAll((data['features'] as List).cast<String>());
        }
        if (data['missing_features'] is List) {
          features.addAll((data['missing_features'] as List).cast<String>());
        }

        handler.next(SubscriptionRequiredException(
          message: errorMsg ?? 'Premium subscription required',
          features: features,
          code: errorCode,
        ));
        return;
      }
    }

    handler.next(err);
  }

  bool _isSubscriptionError(String? code) {
    const subscriptionCodes = [
      'SUBSCRIPTION_REQUIRED',
      'PREMIUM_REQUIRED',
      'SUBSCRIPTION_INACTIVE',
      'SUBSCRIPTION_EXPIRED',
      'FEATURE_NOT_AVAILABLE',
    ];
    return code != null && subscriptionCodes.contains(code);
  }
}
