import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_goals_provider.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserGoalsNotifier _provider;
  final _dailyCalorieCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _glLowCtrl = TextEditingController();
  final _glMediumCtrl = TextEditingController();
  final _glLimitCtrl = TextEditingController();
  String _goalFocus = 'maintenance';
  String _language = 'en';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<UserGoalsNotifier>();
      _loadGoals();
    });
  }

  Future<void> _loadGoals() async {
    await _provider.ensureLoaded();
    if (mounted && _provider.goals != null) {
      final g = _provider.goals!;
      setState(() {
        _dailyCalorieCtrl.text = g.dailyCalorieTarget?.toString() ?? '';
        _proteinCtrl.text = g.dailyProteinTargetG?.toStringAsFixed(0) ?? '';
        _carbsCtrl.text = g.dailyCarbsTargetG?.toStringAsFixed(0) ?? '';
        _fatCtrl.text = g.dailyFatTargetG?.toStringAsFixed(0) ?? '';
        _glLowCtrl.text = g.glycemicLoadLowThreshold.toStringAsFixed(0);
        _glMediumCtrl.text = g.glycemicLoadMediumThreshold.toStringAsFixed(0);
        _glLimitCtrl.text = g.dailyGlycemicLoadLimit?.toStringAsFixed(0) ?? '';
        _goalFocus = g.goalFocus;
        _language = g.preferredLanguage;
      });
    }
  }

  @override
  void dispose() {
    _dailyCalorieCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _glLowCtrl.dispose();
    _glMediumCtrl.dispose();
    _glLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGoals() async {
    setState(() => _isSaving = true);
    final updates = <String, dynamic>{};
    if (_dailyCalorieCtrl.text.isNotEmpty) {
      updates['daily_calorie_target'] = int.tryParse(_dailyCalorieCtrl.text);
    }
    if (_proteinCtrl.text.isNotEmpty) {
      updates['daily_protein_target_g'] = double.tryParse(_proteinCtrl.text);
    }
    if (_carbsCtrl.text.isNotEmpty) {
      updates['daily_carbs_target_g'] = double.tryParse(_carbsCtrl.text);
    }
    if (_fatCtrl.text.isNotEmpty) {
      updates['daily_fat_target_g'] = double.tryParse(_fatCtrl.text);
    }
    updates['glycemic_load_low_threshold'] = double.tryParse(_glLowCtrl.text) ?? 10.0;
    updates['glycemic_load_medium_threshold'] = double.tryParse(_glMediumCtrl.text) ?? 19.0;
    if (_glLimitCtrl.text.isNotEmpty) {
      updates['daily_glycemic_load_limit'] = double.tryParse(_glLimitCtrl.text);
    }
    updates['goal_focus'] = _goalFocus;
    updates['preferred_language'] = _language;
    await _provider.save(updates);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.error == null ? 'Settings saved!' : 'Save failed'),
          backgroundColor: _provider.error == null ? const Color(0xFF2E7D32) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(loc.goalFocusTitle),
          _dropdown(loc.goalFocusLabel, _goalFocus, [
            DropdownMenuItem(value: 'maintenance', child: Text(loc.goalMaintenance)),
            DropdownMenuItem(value: 'weight_loss', child: Text(loc.goalWeightLoss)),
            DropdownMenuItem(value: 'muscle_gain', child: Text(loc.goalMuscleGain)),
            DropdownMenuItem(value: 'fasting_support', child: Text(loc.goalFasting)),
            DropdownMenuItem(value: 'diabetes_management', child: Text(loc.goalDiabetes)),
          ], (v) => setState(() => _goalFocus = v!)),
          const SizedBox(height: 16),
          _sectionTitle(loc.dailyTargetsTitle),
          _textField(_dailyCalorieCtrl, loc.dailyCalorieTarget),
          _textField(_proteinCtrl, loc.dailyProteinTarget),
          _textField(_carbsCtrl, loc.dailyCarbsTarget),
          _textField(_fatCtrl, loc.dailyFatTarget),
          const SizedBox(height: 16),
          _sectionTitle(loc.glThresholdsTitle),
          _textField(_glLowCtrl, loc.glLowThreshold),
          _textField(_glMediumCtrl, loc.glMediumThreshold),
          _textField(_glLimitCtrl, loc.dailyGlycemicLoadLimit),
          const SizedBox(height: 16),
          _sectionTitle(loc.languageTitle),
          _dropdown(loc.languageLabel, _language, [
            DropdownMenuItem(value: 'en', child: Text(loc.languageEnglish)),
            DropdownMenuItem(value: 'am', child: Text(loc.languageAmharic)),
          ], (v) => setState(() => _language = v!)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveGoals,
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? (isAm ? 'በማስቀመጥ ላይ...' : 'Saving...') : (isAm ? 'አስቀምጥ' : 'Save Changes')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
    );
  }

  Widget _textField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}