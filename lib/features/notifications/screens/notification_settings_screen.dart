import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationPreferences _prefs;
  bool _isSaving = false;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _prefs = context.read<NotificationProvider>().prefs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadUpcomingFasts();
    });
  }

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await context.read<NotificationProvider>().updatePreferences(_prefs);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (_isAm ? 'ተስተካክለዋል' : 'Settings saved')
            : (_isAm ? 'ማስተካከያ አልተሳካም' : 'Failed to save settings')),
        backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  Future<void> _sendTest() async {
    setState(() => _isSendingTest = true);
    final ok = await context.read<NotificationProvider>().sendTestNotification();
    if (!mounted) return;
    setState(() => _isSendingTest = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (_isAm ? 'ሙከራ ተልኳል' : 'Test notification sent')
            : (_isAm ? 'ሙከራ አልተሳካም' : 'Failed to send test notification')),
        backgroundColor: ok ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final fasts = provider.upcomingFasts;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAm ? 'ማስታወሻ ቅንብሮች' : 'Notification Settings'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
              tooltip: _isAm ? 'አስቀምጥ' : 'Save',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Fasting reminders section
          _buildSectionHeader(_isAm ? 'የጾም ማስታወሻ' : 'Fasting Reminders'),
          _buildSwitch(
            title: _isAm ? 'የጾም ማስታወሻ አብራ' : 'Enable Fasting Reminders',
            subtitle: _isAm
                ? 'ከማግኘትዎ በፊት የጾም ቀናትን ይደውሉ'
                : 'Get reminded before fasting days',
            value: _prefs.fastingReminders,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(fastingReminders: v)),
          ),
          _buildSwitch(
            title: _isAm ? 'የጾም ማስታወሻ (ሰዓት)' : 'Fasting Notice Period',
            subtitle: _isAm
                ? 'ከ${_prefs.fastingDayNoticeHours} ሰዓታት በፊት ማስታወሻ'
                : 'Notify ${_prefs.fastingDayNoticeHours} hours before',
            value: _prefs.fastingReminderEnabled,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(fastingReminderEnabled: v)),
          ),
          if (fasts.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildFastingDaysList(fasts, _isAm),
          ],

          const Divider(height: 32),

          // Meal reminders section
          _buildSectionHeader(_isAm ? 'የምግብ ማስታወሻ' : 'Meal Reminders'),
          _buildSwitch(
            title: _isAm ? 'የምግብ ማስታወሻ አብራ' : 'Enable Meal Reminders',
            subtitle: _isAm ? 'የቀን ምግብ ማስታወሻ' : 'Daily meal logging reminder',
            value: _prefs.mealReminders,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(mealReminders: v)),
          ),
          _buildTimePicker(context),

          const Divider(height: 32),

          // Other notifications
          _buildSectionHeader(_isAm ? 'ሌሎች' : 'Other'),
          _buildSwitch(
            title: _isAm ? 'ሳምንታዊ ማጠቃለያ' : 'Weekly Summary',
            subtitle: _isAm ? 'ሳምንታዊ የጤና ማጠቃለያ' : 'Weekly health summary',
            value: _prefs.weeklySummary,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(weeklySummary: v)),
          ),
          _buildSwitch(
            title: _isAm ? 'የትምህርት ምክሮች' : 'Educational Tips',
            subtitle: _isAm ? 'የጤና ምክሮችና መረጃ' : 'Health tips and insights',
            value: _prefs.educationalTips,
            onChanged: (v) => setState(() => _prefs = _prefs.copyWith(educationalTips: v)),
          ),

          const SizedBox(height: 24),

          // Test notification
          OutlinedButton.icon(
            onPressed: _isSendingTest ? null : _sendTest,
            icon: _isSendingTest
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.notifications_active),
            label: Text(_isAm ? 'ሙከራ ማስታወሻ ላክ' : 'Send Test Notification'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
    ),
  );

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(title),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    value: value,
    onChanged: onChanged,
    activeThumbColor: const Color(0xFF2E7D32),
    contentPadding: EdgeInsets.zero,
  );

  Widget _buildTimePicker(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(_isAm ? 'የማስታወሻ ሰዓት' : 'Reminder Time'),
    subtitle: Text(_prefs.reminderTime, style: const TextStyle(fontSize: 14)),
    trailing: const Icon(Icons.access_time),
    onTap: () async {
      final parts = _prefs.reminderTime.split(':');
      final initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 7,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
      final picked = await showTimePicker(context: context, initialTime: initial);
      if (picked != null) {
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        setState(() => _prefs = _prefs.copyWith(reminderTime: '$hh:$mm'));
      }
    },
  );

  Widget _buildFastingDaysList(List<FastingDay> fasts, bool isAm) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAm ? 'ቀጣይ የጾም ቀናት (60 ቀናት)' : 'Upcoming Fasting Days (60 days)',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade900),
          ),
          const SizedBox(height: 8),
          ...fasts.take(5).map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.event, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Expanded(child: Text(f.name, style: const TextStyle(fontSize: 12))),
                Text(f.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          )),
          if (fasts.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                isAm ? '+${fasts.length - 5} ተጨማሪ' : '+${fasts.length - 5} more',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}
