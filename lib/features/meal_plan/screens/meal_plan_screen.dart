import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../services/meal_plan_api_service.dart';
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
    final dateStr = _selectedDate != null ? _formatDate(_selectedDate!) : null;
    final provider = context.read<MealPlanProvider>();
    final result = await provider.generateMealPlan(
      planDate: dateStr, isFastingDay: _isFastingDay,
    );
    if (!mounted) return;
    if (result != null) {
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.mealPlanGeneratedSuccess),
          backgroundColor: const Color(0xFF2E7D32),
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
        SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.aiMealPlanner),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.todaysPlan),
            Tab(text: loc.planHistory),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGenerateTab(loc, isAm), _buildHistoryTab(loc, isAm)],
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
              _buildGenerateCard(loc, isAm, provider),
              if (provider.hasCurrentPlan) ...[
                const SizedBox(height: 20),
                _buildCurrentPlanSummary(loc, provider.currentPlan!),
                const SizedBox(height: 12),
                ...provider.currentPlan!.meals.map((m) => MealCard(
                  meal: m, showDeleteAction: true,
                  onDelete: () => provider.deleteMealPlan(m.id),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGenerateCard(AppLocalizations loc, bool isAm, MealPlanProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(loc.generateNewPlan, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(loc.aiWillCreatePersonalizedPlan, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(_selectedDate != null ? _formatDate(_selectedDate!) : loc.selectDate),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
              if (_selectedDate != null) IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => setState(() => _selectedDate = null),
                tooltip: loc.clear,
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _isFastingDay ? const Color(0xFFFFF8E1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isFastingDay ? const Color(0xFFFFB300) : Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: Row(children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFFF57F17), size: 20),
                  const SizedBox(width: 8),
                  Text(isAm ? 'የጾም ቀን' : loc.fastingDay, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                subtitle: Text(
                  isAm ? 'የኢትዮጵያ ኦርቶዶክስ ፍስት አማራጭ' : 'Ethiopian Orthodox fasting meals (vegan)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _isFastingDay,
                activeTrackColor: const Color(0xFFFFB300),
                onChanged: (v) => setState(() => _isFastingDay = v),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.isGenerating ? null : _generatePlan,
              icon: provider.isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                provider.isGenerating
                    ? (isAm ? 'በማራከር...' : loc.generating)
                    : (isAm ? 'እቅድ ማምረት' : loc.generatePlan),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCurrentPlanSummary(AppLocalizations loc, MealPlanResponse plan) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 6),
          Text(isAm ? 'የዛምሻው እቅድ' : 'Latest Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (plan.isFastingMeal) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: Text(isAm ? 'የጾም' : 'Fasting', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF57F17))),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _summaryItem(isAm ? 'ካሎሪ' : 'Calories', plan.summary.totalCalories.toStringAsFixed(0), 'kcal', const Color(0xFFF57C00)),
          _summaryItem(isAm ? 'ግላይሴሚክ ሸክላ' : 'Glycemic Load', plan.summary.totalGlycemicLoad.toStringAsFixed(1), 'GL', const Color(0xFF2E7D32)),
          _summaryItem(isAm ? 'ምግቦች' : 'Meals', plan.summary.mealCount.toString(), '', const Color(0xFF1976D2)),
        ]),
      ]),
    );
  }

  Widget _summaryItem(String label, String value, String unit, Color color) {
    return Column(children: [
      Text(unit.isNotEmpty ? '$value $unit' : value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ]);
  }

  Widget _buildHistoryTab(AppLocalizations loc, bool isAm) {
    return Consumer<MealPlanProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoadingSaved) return const Center(child: CircularProgressIndicator());
        if (!provider.hasSavedPlans) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(isAm ? 'ምንም የተማረኩ እቅዶች የሉም' : loc.noMealPlansFound, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(isAm ? 'አዲስ እቅድ ለማምረት ላይ ያመራሉ' : loc.generateFirstPlan, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ]),
          );
        }
        final grouped = provider.savedPlansByDate;
        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        return RefreshIndicator(
          onRefresh: () => provider.loadSavedPlans(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (ctx, i) => _buildDateSection(sortedDates[i], grouped[sortedDates[i]]!, loc, isAm, provider),
          ),
        );
      },
    );
  }

  Widget _buildDateSection(String dateKey, List<MealPlan> meals, AppLocalizations loc, bool isAm, MealPlanProvider provider) {
    final parts = dateKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final isToday = _isSameDay(date, DateTime.now());
    final isYesterday = _isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));
    final dateLabel = isToday ? (isAm ? 'ዛምሻው' : 'Today')
        : isYesterday ? (isAm ? 'ትናንት' : 'Yesterday')
        : '${date.month}/${date.day}/${date.year}';
    final totalCal = meals.fold<double>(0, (s, m) => s + m.calories);
    final totalGL = meals.fold<double>(0, (s, m) => s + m.glycemicLoad);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
        Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('${totalCal.toStringAsFixed(0)} kcal', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Text('GL ${totalGL.toStringAsFixed(1)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ])),
      ...meals.map((m) => MealCard(meal: m, showDeleteAction: true, onDelete: () => provider.deleteMealPlan(m.id))),
      const SizedBox(height: 12),
    ]);
  }

}
