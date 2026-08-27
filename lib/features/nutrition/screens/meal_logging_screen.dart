import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/meal_analysis.dart';
import '../services/food_api_service.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/nutrition_summary_card.dart';

class MealLoggingScreen extends StatefulWidget {
  const MealLoggingScreen({super.key});
  @override
  State<MealLoggingScreen> createState() => _MealState();
}

class _MealState extends State<MealLoggingScreen> {
  final _api = FoodApiService();
  final _search = TextEditingController();
  List<FoodItem> _results = [];
  bool _searching = false;
  Timer? _debounce;
  final List<Map<String, dynamic>> _items = [];
  MealAnalysis? _analysis;
  bool _analyzing = false;
  String _err = '';

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

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isAm = lang == 'am';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAm ? 'የምግብ መመዝገቢያ & GL' : 'Meal Logger & GL Tracker', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: isAm ? 'ውጣ' : 'Logout',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: isAm ? 'ምግብ ይፈልጉ (Injera, እንጀራ)...' : 'Search food (Injera, እንጀራ)...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (_searching)
            const Expanded(child: ShimmerSkeletonItem())
          else if (_results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final f = _results[i];
                  return ListTile(
                    title: Text(_name(f), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${f.caloriesPer100g.toStringAsFixed(0)} kcal/100g • Source: ${f.source}'),
                    trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _add(f)),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(isAm ? 'ምግብ አልተመረጠም - ለመጀመር ይፈልጉ' : 'No food selected - search above to begin'),
                      ),
                    )
                  else ...[
                    ...List.generate(_items.length, (i) {
                      final item = _items[i];
                      final f = item['food'] as FoodItem;
                      final p = item['portion_g'] as double;
                      return ListTile(
                        title: Text(_name(f), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Portion: ${p.toStringAsFixed(0)}g'),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _remove(i)),
                      );
                    }),
                    if (_analyzing)
                      const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                    else if (_analysis != null)
                      NutritionSummaryCard(analysis: _analysis!),
                  ],
                ],
              ),
            ),
          if (_err.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_err, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

