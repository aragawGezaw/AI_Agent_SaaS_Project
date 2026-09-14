/// Notification log entry as returned by the backend.
class NotificationLogEntry {
  final String id;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic> dataPayload;
  final String status; // 'sent' | 'failed' | 'opened' | 'pending'
  final DateTime sentAt;
  final DateTime? openedAt;

  const NotificationLogEntry({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.dataPayload,
    required this.status,
    required this.sentAt,
    this.openedAt,
  });

  factory NotificationLogEntry.fromJson(Map<String, dynamic> json) {
    return NotificationLogEntry(
      id: json['id']?.toString() ?? '',
      notificationType: json['notification_type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      dataPayload: (json['data_payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      status: json['status'] as String? ?? 'sent',
      sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      openedAt: json['opened_at'] != null
          ? DateTime.tryParse(json['opened_at'].toString())
          : null,
    );
  }
}

/// Upcoming Ethiopian Orthodox fasting day.
class FastingDay {
  final String date; // YYYY-MM-DD
  final String name;

  const FastingDay({required this.date, required this.name});

  factory FastingDay.fromJson(Map<String, dynamic> json) {
    return FastingDay(
      date: json['date'] as String? ?? '',
      name: json['name'] as String? ?? 'Ethiopian Orthodox Fast',
    );
  }
}

/// User notification preferences.
class NotificationPreferences {
  final bool fastingReminders;
  final bool mealReminders;
  final bool weeklySummary;
  final bool educationalTips;
  final String reminderTime; // HH:mm
  final bool fastingReminderEnabled;
  final int fastingDayNoticeHours;

  const NotificationPreferences({
    this.fastingReminders = true,
    this.mealReminders = true,
    this.weeklySummary = true,
    this.educationalTips = true,
    this.reminderTime = '07:00',
    this.fastingReminderEnabled = true,
    this.fastingDayNoticeHours = 18,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      fastingReminders: json['fasting_reminders'] as bool? ?? true,
      mealReminders: json['meal_reminders'] as bool? ?? true,
      weeklySummary: json['weekly_summary'] as bool? ?? true,
      educationalTips: json['educational_tips'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? '07:00',
      fastingReminderEnabled: json['fasting_reminder_enabled'] as bool? ?? true,
      fastingDayNoticeHours: (json['fasting_day_notice_hours'] as num?)?.toInt() ?? 18,
    );
  }

  Map<String, dynamic> toJson() => {
        'fasting_reminders': fastingReminders,
        'meal_reminders': mealReminders,
        'weekly_summary': weeklySummary,
        'educational_tips': educationalTips,
        'reminder_time': reminderTime,
        'fasting_reminder_enabled': fastingReminderEnabled,
        'fasting_day_notice_hours': fastingDayNoticeHours,
      };

  NotificationPreferences copyWith({
    bool? fastingReminders,
    bool? mealReminders,
    bool? weeklySummary,
    bool? educationalTips,
    String? reminderTime,
    bool? fastingReminderEnabled,
    int? fastingDayNoticeHours,
  }) {
    return NotificationPreferences(
      fastingReminders: fastingReminders ?? this.fastingReminders,
      mealReminders: mealReminders ?? this.mealReminders,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      educationalTips: educationalTips ?? this.educationalTips,
      reminderTime: reminderTime ?? this.reminderTime,
      fastingReminderEnabled: fastingReminderEnabled ?? this.fastingReminderEnabled,
      fastingDayNoticeHours: fastingDayNoticeHours ?? this.fastingDayNoticeHours,
    );
  }
}
