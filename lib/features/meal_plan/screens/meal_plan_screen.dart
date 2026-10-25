import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../widgets/generate_plan_card.dart';
import '../widgets/meal_plan_summary_card.dart';
import '../widgets/meal_card.dart';
import '../../subscription/screens/paywall_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime? _selectedDate;
  bool _isFastingDay = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlanProvider>().loadSavedPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _generatePlan() async {
    final dateStr = _formatDate(_selectedDate ?? DateTime.now());
    final provider = context.read<MealPlanProvider>();

    // Detect active app locale dynamically ('am' or 'en')
    final langCode = Localizations.localeOf(context).languageCode;

    final result = await provider.generateMealPlan(
      planDate: dateStr,
      isFastingDay: _isFastingDay,
      languageCode: langCode, // Pass active language code to provider
    );

    if (!mounted) return;
    if (result != null) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mealPlanGeneratedSuccess),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (provider.subscriptionError != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      provider.clearSubscriptionError();
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.aiMealPlanner),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: isAm ? 'የዛሬው እቅድ' : loc.todaysPlan),
            Tab(text: isAm ? 'የእቅድ ታሪክ' : loc.planHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResponsiveWrapper(_buildGenerateTab(loc, isAm)),
          _buildResponsiveWrapper(_buildHistoryTab(loc, isAm)),
        ],
      ),
    );
  }

  Widget _buildResponsiveWrapper(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: child,
      ),
    );
  }

  Widget _buildGenerateTab(AppLocalizations loc, bool isAm) {
    return Consumer<MealPlanProvider>(
      builder: (ctx, provider, _) => RefreshIndicator(
        onRefresh: () => provider.loadSavedPlans(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GeneratePlanCard(
                selectedDate: _selectedDate,
                isFastingDay: _isFastingDay,
                isGenerating: provider.isGenerating,
                onDateChanged: (d) => setState(() => _selectedDate = d),
                onFastingChanged: (v) => setState(() => _isFastingDay = v),
                onGenerate: _generatePlan,
                onPickDate: _pickDate,
              ),
              if (provider.isGenerating) ...[
                const SizedBox(height: 24),
                _buildAIGenerationLoadingState(isAm),
              ] else if (provider.hasCurrentPlan) ...[
                const SizedBox(height: 20),
                MealPlanSummaryCard(plan: provider.currentPlan!),
                const SizedBox(height: 12),
                ...provider.currentPlan!.meals.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: MealCard(
                      meal: m,
                      showDeleteAction: true,
                      onDelete: () => provider.deleteMealPlan(m.id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Displays clear loading feedback while Gemini AI processes the meal plan
  Widget _buildAIGenerationLoadingState(bool isAm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          Text(
            isAm
                ? 'የእርስዎን የሜታቦሊክ አመጋገብ እቅድ በማዘጋጀት ላይ...'
                : 'Crafting your personalized metabolic meal plan...',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isAm
                ? 'እባክዎ ትንሽ ይጠብቁ (ከ3 እስከ 7 ሰከንድ ሊወስድ ይችላል)'
                : 'Please wait a moment (takes about 3 to 7 seconds)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AppLocalizations loc, bool isAm) {
    return Consumer<MealPlanProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoadingSaved) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!provider.hasSavedPlans) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAm ? 'ምንም የተቀመጡ እቅዶች የሉም' : loc.noMealPlansFound,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAm ? 'አዲስ እቅድ ለማዘጋጀት ከላይ ይጠቀሙ' : loc.generateFirstPlan,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final grouped = provider.savedPlansByDate;
        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return RefreshIndicator(
          onRefresh: () => provider.loadSavedPlans(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (ctx, i) => _buildDateSection(
              sortedDates[i],
              grouped[sortedDates[i]]!,
              loc,
              isAm,
              provider,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSection(
    String dateKey,
    List<MealPlan> meals,
    AppLocalizations loc,
    bool isAm,
    MealPlanProvider provider,
  ) {
    final todayStr = _formatDate(DateTime.now());
    final yesterdayStr = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    final isToday = dateKey == todayStr;
    final isYesterday = dateKey == yesterdayStr;

    final dateLabel = isToday
        ? (isAm ? 'ዛሬ' : 'Today')
        : isYesterday
        ? (isAm ? 'ትናንት' : 'Yesterday')
        : dateKey;

    final totalCal = meals.fold<double>(0, (s, m) => s + m.calories);
    final totalGL = meals.fold<double>(0, (s, m) => s + m.glycemicLoad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${totalCal.toStringAsFixed(0)} kcal',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Text(
                'GL ${totalGL.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        ...meals.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: MealCard(
              meal: m,
              showDeleteAction: true,
              onDelete: () => provider.deleteMealPlan(m.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
