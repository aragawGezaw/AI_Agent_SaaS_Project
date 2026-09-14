/// Data model representing a user's subscription.
/// Maps to the backend `subscriptions` table.
class Subscription {
  final String id;
  final String userId;
  final String planType; // free, premium, admin
  final String status; // active, cancelled, expired
  final DateTime? currentPeriodEnd;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> featureGating;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    this.currentPeriodEnd,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.createdAt,
    this.updatedAt,
    this.featureGating = const {},
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      planType: json['plan_type'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'].toString())
          : null,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      featureGating: (json['feature_gating'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'status': status,
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'feature_gating': featureGating,
    };
  }

  bool hasFeatureAccess(String feature) =>
      featureGating[feature] == true;

  bool get isPremium => planType == 'premium' || planType == 'admin';
  bool get isActive => status == 'active';
  bool get isExpired =>
      status == 'expired' ||
      (currentPeriodEnd != null && currentPeriodEnd!.isBefore(DateTime.now()));
}
