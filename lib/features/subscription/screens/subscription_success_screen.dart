import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_agent_saas_project/features/subscription/providers/subscription_provider.dart';

/// Screen displayed upon successful subscription completion via Chapa or Stripe Checkout
class SubscriptionSuccessScreen extends StatefulWidget {
  final String? txRef;
  final String?
  sessionId; // Preserved for backwards compatibility with main.dart navigation

  const SubscriptionSuccessScreen({super.key, this.txRef, this.sessionId});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool _isVerifying = true;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Use txRef if available, otherwise fallback to sessionId
      final reference = widget.txRef ?? widget.sessionId;

      if (reference != null && reference.isNotEmpty) {
        // Verify transaction with backend and payment API
        final success = await context
            .read<SubscriptionProvider>()
            .verifyAndCompletePayment(reference);

        if (mounted) {
          setState(() {
            _isVerifying = false;
            if (!success) {
              _verificationError =
                  Localizations.localeOf(context).languageCode == 'am'
                  ? 'የክፍያ ማረጋገጫ አልተሳካም። እባክዎ ድጋፍ ያግኙ።'
                  : 'Payment verification failed. Please contact support.';
            }
          });
        }
      } else {
        // Fallback: just refresh subscription status if no reference is present
        await context.read<SubscriptionProvider>().refreshSubscription();
        if (mounted) {
          setState(() => _isVerifying = false);
        }
      }
    });
  }

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';

  @override
  Widget build(BuildContext context) {
    final isAm = _isAm;
    final referenceDisplay = widget.txRef ?? widget.sessionId;

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
          child: _isVerifying
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    const SizedBox(height: 24),
                    Text(
                      isAm ? 'ክፍያዎ እየረጋገጠ ነው...' : 'Verifying your payment...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _verificationError != null
                            ? Colors.red.shade50
                            : const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _verificationError != null
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_rounded,
                        color: _verificationError != null
                            ? Colors.red.shade700
                            : const Color(0xFF2E7D32),
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _verificationError != null
                          ? (isAm ? 'የክፍያ ስህተት' : 'Verification Issue')
                          : (isAm
                                ? 'የክፍያ ሂደትዎ በተሳካ ሁኔታ ተጠናቋል!'
                                : 'Subscription Successful!'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _verificationError != null
                            ? Colors.red.shade700
                            : const Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _verificationError ??
                          (isAm
                              ? 'አሁን ወደ ሁሉም የፕሪሚየም AI የምግብ እቅድ እና የጤና አገልግሎቶች መዳረሻ አለዎት።'
                              : 'Thank you for subscribing! You now have full access to all premium features.'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (referenceDisplay != null &&
                        referenceDisplay.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        isAm
                            ? 'የክፍያ ማጣቀሻ: $referenceDisplay'
                            : 'Reference ID: $referenceDisplay',
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
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
