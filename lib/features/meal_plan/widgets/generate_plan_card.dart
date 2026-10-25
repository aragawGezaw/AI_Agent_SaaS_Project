import 'package:flutter/material.dart';

class GeneratePlanCard extends StatelessWidget {
  final DateTime? selectedDate;
  final bool isFastingDay;
  final bool isGenerating;
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<bool> onFastingChanged;
  final VoidCallback onGenerate;
  final VoidCallback onPickDate;

  const GeneratePlanCard({
    super.key,
    required this.selectedDate,
    required this.isFastingDay,
    required this.isGenerating,
    required this.onDateChanged,
    required this.onFastingChanged,
    required this.onGenerate,
    required this.onPickDate,
  });

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF2E7D32),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAm ? 'አዲስ እቅድ ማዘጋጀት' : 'Generate New Plan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isAm
                            ? 'AI ለእናንተ የተመቻቹ የምግብ እቅዶችን ይፈጥራል'
                            : 'AI will create personalized meal plans',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      selectedDate != null
                          ? _formatDate(selectedDate!)
                          : (isAm ? 'ቀን ይምረጡ' : 'Select Date'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => onDateChanged(null),
                    tooltip: isAm ? 'አጽዳ' : 'Clear',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isFastingDay
                    ? const Color(0xFFFFF8E1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFastingDay
                      ? const Color(0xFFFFB300)
                      : Colors.grey.shade300,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  tileColor: Colors.transparent,
                  title: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFF57F17),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAm ? 'የጾም ቀን' : 'Fasting Day',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    isAm
                        ? 'የኢትዮጵያ ኦርቶዶክስ የጾም ምግብ አማራጭ'
                        : 'Ethiopian Orthodox fasting meals (vegan)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  value: isFastingDay,
                  activeTrackColor: const Color(0xFFFFB300),
                  onChanged: onFastingChanged,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                isGenerating
                    ? (isAm ? 'እቅድ በማዘጋጀት ላይ...' : 'Generating...')
                    : (isAm ? 'እቅድ ማዘጋጀት' : 'Generate Plan'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
