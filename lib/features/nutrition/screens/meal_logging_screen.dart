import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/meal_analysis.dart';
import '../services/food_api_service.dart';
import '../services/meal_history_service.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/nutrition_summary_card.dart';
import '../../../l10n/app_localizations.dart';

class MealLoggingScreen extends StatefulWidget {
  const MealLoggingScreen({super.key});
  @override
  State<MealLoggingScreen> createState() => _MealState();
}

class _MealState extends State<MealLoggingScreen> {
  final _api = FoodApiService();
  final _historyService = MealHistoryService();
  final _search = TextEditingController();
  List<FoodItem> _results = [];
  bool _searching = false;
  Timer? _debounce;
  final List<Map<String, dynamic>> _items = [];
  MealAnalysis? _analysis;
  bool _analyzing = false;
  String _err = '';
  bool _saving = false;
  String _selectedMealType = 'lunch';

  @override
  void dispose() {
    _search.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _name(FoodItem f) {
    if (f.nameAm.isNotEmpty && f.nameEn.isNotEmpty) return '${f.nameEn} (${f.nameAm})';
    return f.nameEn.isNotEmpty ? f.nameEn : f.nameAm;
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) { setState(() { _results = []; _searching = false; }); return; }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await _api.searchFoods(q, lang: Localizations.localeOf(context).languageCode);
        if (mounted) setState(() { _results = res; _searching = false; });
      } catch (e) {
        if (mounted) setState(() { _searching = false; _err = '$e'; });
      }
    });
  }

  void _add(FoodItem f) {
    if (!_items.any((x) => (x['food'] as FoodItem).id == f.id)) {
      setState(() { _items.add({'food': f, 'portion_g': 100.0}); _results = []; _search.clear(); });
      _analyze();
    }
  }

  void _remove(int i) {
    setState(() { _items.removeAt(i); if (_items.isEmpty) _analysis = null; });
    if (_items.isNotEmpty) _analyze();
  }

  Future<void> _analyze() async {
    if (_items.isEmpty) return;
    setState(() { _analyzing = true; _err = ''; });
    try {
      final payload = _items.map((x) => {'food_id': (x['food'] as FoodItem).id, 'portion_g': x['portion_g']}).toList();
      final res = await _api.analyzeMeal(payload);
      if (mounted) setState(() { _analysis = res; _analyzing = false; });
    } catch (e) {
      if (mounted) setState(() { _analyzing = false; _err = '$e'; });
    }
  }

  Future<void> _saveMeal() async {
    if (_analysis == null || _items.isEmpty || _saving) return;

    final lang = Localizations.localeOf(context).languageCode;
    final isAm = lang == 'am';

    // Build a comma-separated name summary in the user's language.
    final foodName = _items
        .map((x) => (x['food'] as FoodItem).getName(lang))
        .where((n) => n.isNotEmpty)
        .join(', ');

    final totals = _analysis!.totals;
    final evalNote = _analysis!.evaluationNote;
    final foodIds = _items
        .map((x) => (x['food'] as FoodItem).id)
        .toList();

    final payload = <String, dynamic>{
      'meal_type': _selectedMealType,
      'food_name': foodName.isEmpty
          ? (isAm ? 'ያልተለየ ምግብ' : 'Unnamed meal')
          : foodName,
      'food_ids': foodIds,
      'calories': totals.calories,
      'macros': {
        'protein_g': totals.proteinG,
        'carbs_g': totals.carbsG,
        'fat_g': totals.fatG,
      },
      'total_glycemic_load': _analysis!.totalGlycemicLoad,
      'net_carbs_g': totals.netCarbsG,
      'gl_class': evalNote.glycemicLoadClass,
    };

    setState(() {
      _saving = true;
      _err = '';
    });

    try {
      await _historyService.saveMeal(payload);
      if (!mounted) return;

      // Clear local state for a fresh meal after a successful save.
      setState(() {
        _items.clear();
        _analysis = null;
        _results = [];
        _search.clear();
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAm ? 'ምግብ ተቆጥቧል!' : 'Meal saved successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to the meal history screen and replace this route so the
      // back button does not return to a now-empty logger.
      Navigator.pushReplacementNamed(context, '/meal-history');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _err = isAm
            ? 'ምግብ ለማስቀመጥ አልተቻለም: $e'
            : 'Failed to save meal: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAm
                ? 'ምግብ ለማስቀመጥ አልተቻለም'
                : 'Failed to save meal',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Builds the horizontal meal-type ChoiceChip row.
  Widget _buildMealTypeChips(AppLocalizations localizations) {
    final chips = <String, String>{
      'breakfast': localizations.filterBreakfast,
      'lunch':     localizations.filterLunch,
      'dinner':    localizations.filterDinner,
      'snack':     localizations.filterSnack,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: chips.entries.map((entry) {
          final selected = _selectedMealType == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => setState(() => _selectedMealType = entry.key),
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// True when there is enough data to attempt a save.
  bool get _canSave => _items.isNotEmpty && _analysis != null && !_saving;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAm = lang == 'am';
    final localizations = AppLocalizations.of(context)!;
    final saveInProgress = _saving;
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: Text(isAm ? 'የምግብ መመዝገቢያ & GL' : 'Meal Logger & GL Tracker', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: isAm ? 'የምግብ ታሪክ' : 'Meal History',
            onPressed: () => Navigator.pushNamed(context, '/meal-history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: isAm ? 'ውጣ' : 'Logout',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meal-type chips row.
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: _buildMealTypeChips(localizations),
          ),
          // Search bar.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: isAm
                    ? 'ምግብ ይፈልጉ (Injera, እንጀራ)...'
                    : 'Search food (Injera, እንጀራ)...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          // Main content area.
          Expanded(
            child: _searching
                ? const ShimmerSkeletonItem()
                : _results.isNotEmpty
                    ? ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) {
                          final f = _results[i];
                          return ListTile(
                            title: Text(_name(f),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${f.caloriesPer100g.toStringAsFixed(0)} kcal/100g • ${f.source}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _add(f),
                            ),
                          );
                        },
                      )
                    : ListView(
                        children: [
                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  isAm
                                      ? 'ምግብ አልተመረጠም - ለመጀመር ይፈልጉ'
                                      : 'No food selected — search above to begin',
                                ),
                              ),
                            )
                          else ...[
                            ...List.generate(_items.length, (i) {
                              final item = _items[i];
                              final f = item['food'] as FoodItem;
                              final p = item['portion_g'] as double;
                              return ListTile(
                                title: Text(_name(f),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${p.toStringAsFixed(0)}g'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _remove(i),
                                ),
                              );
                            }),
                            if (_analyzing)
                              const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator()))
                            else if (_analysis != null)
                              NutritionSummaryCard(analysis: _analysis!),
                          ],
                        ],
                      ),
          ),
          // Error banner.
          if (_err.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(_err, style: const TextStyle(color: Colors.red)),
            ),
          // Bottom spacer so the FAB doesn't obscure content.
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedScale(
        scale: _canSave ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: _canSave ? _saveMeal : null,
          backgroundColor:
              _canSave ? const Color(0xFF2E7D32) : Colors.grey.shade400,
          icon: const Icon(Icons.save_rounded, color: Colors.white),
          label: Text(
            isAm ? 'ምግብ አስቀምጥ' : 'Save Meal',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
        // Blocking overlay while save is in progress.
        if (saveInProgress)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(isAm ? 'ምግብ በማስቀመጥ ላይ...' : 'Saving meal...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

