import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/subscription_provider.dart';
import '../widgets/tier_comparison_card.dart';

/// Paywall screen showing subscription tiers, multi-currency support, and upgrade options
class PaywallScreen extends StatefulWidget {
  final String? featureRequested;
  final VoidCallback? onDismiss;

  const PaywallScreen({super.key, this.featureRequested, this.onDismiss});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedIndex = 1;
  String _selectedCurrency = 'ETB'; // Default to local Ethiopian Birr

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';

  @override
  Widget build(BuildContext context) {
    final isAm = _isAm;
    final provider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAm ? 'የፕሪሚየም እቅድ ይምረጡ' : 'Choose Your Plan'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (widget.onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onDismiss,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.featureRequested != null) ...[
              _buildFeatureLockedBanner(isAm),
              const SizedBox(height: 24),
            ],
            _buildHeader(isAm),
            const SizedBox(height: 16),
            _buildCurrencySelector(isAm),
            const SizedBox(height: 24),
            _buildTierCards(isAm, provider),
            const SizedBox(height: 24),
            _buildUpgradeButton(isAm, provider),
            const SizedBox(height: 16),
            _buildFAQ(isAm),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureLockedBanner(bool isAm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAm ? 'ይህ ባህሪ ተዘግቷል' : 'Feature Locked',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAm
                      ? 'AI የምግብ እቅድ ለማግኘት ወደ ፕሪሚየም ይሸፍኑ'
                      : 'Upgrade to Premium to unlock AI Meal Planning',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isAm) {
    return Column(
      children: [
        Text(
          isAm ? 'ጤናዎን ያሻሽሉ' : 'Upgrade Your Health',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          isAm
              ? 'ፕሪሚየም ባህሪያትን በቴሌብር ወይም በዓለም አቀፍ ካርዶች ይክፈቱ'
              : 'Unlock premium features via Telebirr or International Cards',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Currency Selector for Local Users (ETB) vs Diaspora (USD)
  Widget _buildCurrencySelector(bool isAm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isAm ? 'የክፍያ货币 ዓይነት: ' : 'Select Currency: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('ETB (99 ብር)'),
          selected: _selectedCurrency == 'ETB',
          selectedColor: Colors.green.shade100,
          onSelected: (selected) {
            if (selected) setState(() => _selectedCurrency = 'ETB');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('USD (\$9)'),
          selected: _selectedCurrency == 'USD',
          selectedColor: Colors.green.shade100,
          onSelected: (selected) {
            if (selected) setState(() => _selectedCurrency = 'USD');
          },
        ),
      ],
    );
  }

  Widget _buildTierCards(bool isAm, SubscriptionProvider provider) {
    final premiumPrice = _selectedCurrency == 'ETB' ? '99' : '\$9';
    final premiumPeriod = _selectedCurrency == 'ETB'
        ? (isAm ? '/ወር' : '/month')
        : '/month';

    return Column(
      children: [
        TierComparisonCard(
          title: isAm ? 'ነፃ' : 'Free',
          price: '0',
          period: isAm ? 'ሁልጊዜ' : '/month',
          features: [
            isAm ? 'የምግብ ምዝግብ' : 'Meal Logging',
            isAm ? 'ቀላል GL መከታተል' : 'Basic GL Tracking',
            isAm ? '5 የምግብ አማራጮች' : '5 Food Options',
          ],
          isSelected: _selectedIndex == 0,
          onTap: () => setState(() => _selectedIndex = 0),
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        TierComparisonCard(
          title: isAm ? 'ፕሪሚየም' : 'Premium',
          price: premiumPrice,
          period: premiumPeriod,
          features: [
            isAm ? 'AI የምግብ እቅድ' : 'AI Meal Planning',
            isAm ? 'ሙሉ የGL መከታተል' : 'Full GL Tracking',
            isAm ? 'ያለማቋረጥ' : 'Unlimited',
            isAm ? 'የጾም ወቅት' : 'Fasting Plans',
            isAm ? 'ልዩ አመጋገብ' : 'Custom Diet',
          ],
          isRecommended: true,
          isSelected: _selectedIndex == 1,
          onTap: () => setState(() => _selectedIndex = 1),
          color: const Color(0xFF2E7D32),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(bool isAm, SubscriptionProvider provider) {
    final isLoading = provider.isLoading;
    final buttonText = _selectedCurrency == 'ETB'
        ? (isAm ? 'ወደ ፕሪሚየም ይሸፍኑ (99 ብር)' : 'Upgrade to Premium (99 ETB)')
        : (isAm ? 'ወደ ፕሪሚየም ይሸፍኑ (\$9)' : 'Upgrade to Premium (\$9 USD)');

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () async {
              final amount = _selectedCurrency == 'ETB' ? '99' : '9';
              final url = await provider.createCheckoutSession(
                amount: amount,
                currency: _selectedCurrency,
              );

              if (url != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isAm
                          ? 'ወደ ደህንነቱ የተጠበቀ የክፍያ ገጽ እየወሰድንዎት ነው...'
                          : 'Redirecting to secure Chapa checkout...',
                    ),
                  ),
                );
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAm
                                ? 'የክፍያ ገጹን መክፈት አልተቻለም'
                                : 'Could not launch checkout URL',
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAm
                              ? 'ስህተት ተከስቷል: $e'
                              : 'Error launching checkout: $e',
                        ),
                      ),
                    );
                  }
                }
              } else if (provider.error != null && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(provider.error!)));
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              buttonText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildFAQ(bool isAm) {
    return ExpansionTile(
      title: Text(
        isAm ? 'ተደጋግሞ ለሚጠየቁ ጥያቄዎች' : 'FAQ',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        _buildFaqItem(
          isAm ? 'የክፍያ አማራጮች ምንድን ናቸው?' : 'What payment methods are supported?',
          isAm
              ? 'ቴሌብር፣ CBE Birr እና የዓለም አቀፍ ባንክ ካርዶች'
              : 'Telebirr, CBE Birr, and international cards via Chapa',
        ),
        _buildFaqItem(
          isAm ? 'ክፍያው ደህንነቱ የተጠበቀ ነው?' : 'Is payment secure?',
          isAm
              ? 'በኢትዮጵያ በለስላሳ የክፍያ ስርዓት የተጠበቀ'
              : 'Fully secure local and international gateway',
        ),
        _buildFaqItem(
          isAm ? 'መሰረዝ እችላለሁ?' : 'Can I cancel anytime?',
          isAm
              ? 'በማንኛውም ጊዜ መሰረዝ ይቻላል'
              : 'Yes, cancel anytime from your settings',
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
