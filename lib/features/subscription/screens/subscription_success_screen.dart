import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_agent_saas_project/features/subscription/providers/subscription_provider.dart';

/// Screen displayed upon successful subscription completion via Stripe Checkout
class SubscriptionSuccessScreen extends StatefulWidget {
  final String? sessionId;

  const SubscriptionSuccessScreen({super.key, this.sessionId});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends State<SubscriptionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().refreshSubscription();
    });
  }

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';

  @override
  Widget build(BuildContext context) {
    final isAm = _isAm;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAm ? 'የክፍያ ውጤት' : 'Subscription Status'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAm ? 'የክፍያ ሂደትዎ በተሳካ ሁኔታ ተጠናቋል!' : 'Subscription Successful!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isAm
                    ? 'አሁን ወደ ሁሉም የፕሪሚየም AI የምግብ እቅድ እና የጤና አገልግሎቶች መዳረሻ አለዎት።'
                    : 'Thank you for subscribing! You now have full access to all premium features.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.sessionId != null && widget.sessionId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  isAm
                      ? 'የክፍያ መለያ: ${widget.sessionId}'
                      : 'Session ID: ${widget.sessionId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: Text(
                  isAm ? 'ወደ ዋና ገጽ ተመለስ' : 'Return to Home',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
