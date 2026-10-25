import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/user_goals_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../services/mifflin_st_jeor_service.dart';
import '../widgets/activity_info_card.dart';
import '../widgets/settings_form_field.dart';

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
  bool _isCalculating = false;
  String? _calcError;

  // Biometric inputs
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';

  final Map<String, String> _activityDescriptions = {
    'sedentary': 'Little or no exercise, desk job (Multiplier: 1.2)',
    'light': 'Light exercise or sports 1–3 days/week (Multiplier: 1.375)',
    'moderate': 'Moderate exercise or sports 3–5 days/week (Multiplier: 1.55)',
    'active': 'Hard exercise or sports 6–7 days a week (Multiplier: 1.725)',
    'very_active':
        'Very hard exercise, physical job, or 2x training (Multiplier: 1.9)',
  };

  static const List<String> _validGoalFocuses = [
    'maintenance',
    'weight_loss',
    'muscle_gain',
    'fasting_support',
    'diabetes_management',
  ];
  static const List<String> _validLanguages = ['en', 'am'];

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
        _goalFocus = _validGoalFocuses.contains(g.goalFocus)
            ? g.goalFocus
            : 'maintenance';
        _language = _validLanguages.contains(g.preferredLanguage)
            ? g.preferredLanguage
            : 'en';
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
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  num? _parseNum(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    try {
      final locale = Localizations.localeOf(context).toString();
      final format = NumberFormat.decimalPattern(locale);
      return format.parse(text);
    } catch (_) {
      return double.tryParse(text);
    }
  }

  Future<void> _calculateTargets() async {
    setState(() {
      _isCalculating = true;
      _calcError = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    final weightKg = _parseNum(_weightCtrl.text)?.toDouble();
    final heightCm = _parseNum(_heightCtrl.text)?.toDouble();
    final age = _parseNum(_ageCtrl.text)?.toInt();

    final error = MifflinStJeorService.validateInputs(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: _gender.isEmpty ? null : _gender,
      activityLevel: _activityLevel,
      goalFocus: _goalFocus,
    );

    if (error != null) {
      setState(() {
        _isCalculating = false;
        _calcError = error;
      });
      return;
    }

    final results = MifflinStJeorService.calculateAll(
      weightKg: weightKg!,
      heightCm: heightCm!,
      age: age!,
      isMale: _gender == 'male',
      activityLevel: _activityLevel,
      goalFocus: _goalFocus,
    );

    if (mounted) {
      setState(() {
        _dailyCalorieCtrl.text = results['daily_calorie_target'].toString();
        _proteinCtrl.text = results['daily_protein_target_g'].toStringAsFixed(
          0,
        );
        _carbsCtrl.text = results['daily_carbs_target_g'].toStringAsFixed(0);
        _fatCtrl.text = results['daily_fat_target_g'].toStringAsFixed(0);
        _glLowCtrl.text = results['glycemic_load_low_threshold']
            .toStringAsFixed(0);
        _glMediumCtrl.text = results['glycemic_load_medium_threshold']
            .toStringAsFixed(0);
        _glLimitCtrl.text = results['daily_glycemic_load_limit']
            .toStringAsFixed(0);
        _isCalculating = false;
      });
    }
  }

  Future<void> _saveGoals() async {
    setState(() => _isSaving = true);
    final updates = <String, dynamic>{};

    final dailyCalorie = _parseNum(_dailyCalorieCtrl.text);
    if (dailyCalorie != null) updates['daily_calorie_target'] = dailyCalorie;

    final protein = _parseNum(_proteinCtrl.text);
    if (protein != null) updates['daily_protein_target_g'] = protein;

    final carbs = _parseNum(_carbsCtrl.text);
    if (carbs != null) updates['daily_carbs_target_g'] = carbs;

    final fat = _parseNum(_fatCtrl.text);
    if (fat != null) updates['daily_fat_target_g'] = fat;

    final weight = _parseNum(_weightCtrl.text);
    if (weight != null) updates['weight_kg'] = weight;

    final height = _parseNum(_heightCtrl.text);
    if (height != null) updates['height_cm'] = height;

    final age = _parseNum(_ageCtrl.text);
    if (age != null) updates['age'] = age;

    final glLow = _parseNum(_glLowCtrl.text);
    final glMedium = _parseNum(_glMediumCtrl.text);

    if (glLow != null) updates['glycemic_load_low_threshold'] = glLow;
    if (glMedium != null) updates['glycemic_load_medium_threshold'] = glMedium;

    if (glLow != null && glMedium != null && glMedium < glLow) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GL medium threshold must be >= low threshold'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final glLimit = _parseNum(_glLimitCtrl.text);
    if (glLimit != null) updates['daily_glycemic_load_limit'] = glLimit;

    if (_goalFocus.isNotEmpty) updates['goal_focus'] = _goalFocus;
    if (_language.isNotEmpty) updates['preferred_language'] = _language;

    await _provider.save(updates);
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _provider.error == null
                ? 'Settings saved!'
                : 'Save failed: ${_provider.error}',
          ),
          backgroundColor: _provider.error == null
              ? const Color(0xFF2E7D32)
              : Colors.red,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGoalFocusSection(loc),
              const SizedBox(height: 16),
              _buildBiometricsAndTargetsSection(loc),
              const SizedBox(height: 16),
              _buildGlThresholdsSection(loc),
              const SizedBox(height: 16),
              _buildLanguageSection(loc),
              const SizedBox(height: 24),
              _buildSaveButton(isAm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalFocusSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(loc.goalFocusTitle),
        SettingsDropdownField(
          label: loc.goalFocusLabel,
          value: _goalFocus,
          items: const [
            DropdownMenuItem(
              value: 'maintenance',
              child: Text('Metabolic Maintenance'),
            ),
            DropdownMenuItem(
              value: 'weight_loss',
              child: Text('Weight Management & Fat Reduction'),
            ),
            DropdownMenuItem(
              value: 'muscle_gain',
              child: Text('Muscle Hypertrophy & Protein Optimization'),
            ),
            DropdownMenuItem(
              value: 'fasting_support',
              child: Text('Orthodox Fasting & Glycemic Control'),
            ),
            DropdownMenuItem(
              value: 'diabetes_management',
              child: Text('Glycemic Control & Insulin Sensitivity'),
            ),
          ],
          onChanged: (v) => setState(() => _goalFocus = v!),
        ),
      ],
    );
  }

  Widget _buildBiometricsAndTargetsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(loc.dailyTargetsTitle),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN: Biometrics
            Expanded(
              child: Column(
                children: [
                  SettingsTextField(
                    controller: _weightCtrl,
                    label: loc.weightLabel,
                  ),
                  SettingsTextField(
                    controller: _heightCtrl,
                    label: loc.heightLabel,
                  ),
                  SettingsTextField(controller: _ageCtrl, label: loc.ageLabel),
                  SettingsDropdownField(
                    label: loc.genderLabel,
                    value: _gender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                  SettingsDropdownField(
                    label: loc.activityLevelLabel,
                    value: _activityLevel,
                    items: const [
                      DropdownMenuItem(
                        value: 'sedentary',
                        child: Text('Sedentary'),
                      ),
                      DropdownMenuItem(
                        value: 'light',
                        child: Text('Lightly Active'),
                      ),
                      DropdownMenuItem(
                        value: 'moderate',
                        child: Text('Moderately Active'),
                      ),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'very_active',
                        child: Text('Very Active'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _activityLevel = v!),
                  ),
                  ActivityInfoCard(
                    activityLevel: _activityLevel,
                    descriptions: _activityDescriptions,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // RIGHT COLUMN: Calculated Targets
            Expanded(
              child: Column(
                children: [
                  SettingsTextField(
                    controller: _dailyCalorieCtrl,
                    label: loc.dailyCalorieTarget,
                  ),
                  SettingsTextField(
                    controller: _proteinCtrl,
                    label: loc.dailyProteinTarget,
                  ),
                  SettingsTextField(
                    controller: _carbsCtrl,
                    label: loc.dailyCarbsTarget,
                  ),
                  SettingsTextField(
                    controller: _fatCtrl,
                    label: loc.dailyFatTarget,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCalculating ? null : _calculateTargets,
                icon: _isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate),
                label: Text(
                  _isCalculating ? loc.calculating : loc.autoCalculate,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (_calcError != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _calcError!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGlThresholdsSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Glycemic Load (GL) Thresholds & Limits'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Configure per-meal classification thresholds and total daily glycemic load limits to prevent blood sugar spikes.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        SettingsTextField(
          controller: _glLowCtrl,
          label: 'Per-Meal Low GL Threshold (Optimal <= 10)',
        ),
        SettingsTextField(
          controller: _glMediumCtrl,
          label: 'Per-Meal Medium GL Threshold (Moderate <= 19)',
        ),
        SettingsTextField(
          controller: _glLimitCtrl,
          label: 'Daily Cumulative Glycemic Load Limit',
        ),
      ],
    );
  }

  Widget _buildLanguageSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(loc.languageTitle),
        SettingsDropdownField(
          label: loc.languageLabel,
          value: _language,
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'am', child: Text('Amharic (አማርኛ)')),
          ],
          onChanged: (v) => setState(() => _language = v!),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isAm) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveGoals,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving
              ? (isAm ? 'በማስቀመጥ ላይ...' : 'Saving...')
              : (isAm ? 'አስቀምጥ' : 'Save Changes'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
