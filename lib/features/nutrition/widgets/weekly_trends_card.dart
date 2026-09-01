import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../l10n/app_localizations.dart';
import '../models/weekly_trend_data.dart';

/// A compact 7-day bar chart card showing calories and glycemic load trends.
class WeeklyTrendsCard extends StatelessWidget {
  final WeeklyTrendResponse? trendsData;
  final bool isLoading;
  final String? error;

  const WeeklyTrendsCard({
    super.key,
    required this.trendsData,
    required this.isLoading,
    this.error,
  });

  Color _glThresholdColor(double glycemicLoad) {
    if (glycemicLoad <= 10) return const Color(0xFF2E7D32);
    if (glycemicLoad <= 20) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  String _getMonthAbbreviation(int month, AppLocalizations localizations) {
    switch (month) {
      case 1: return localizations.jan;
      case 2: return localizations.feb;
      case 3: return localizations.mar;
      case 4: return localizations.apr;
      case 5: return localizations.may;
      case 6: return localizations.jun;
      case 7: return localizations.jul;
      case 8: return localizations.aug;
      case 9: return localizations.sep;
      case 10: return localizations.oct;
      case 11: return localizations.nov;
      case 12: return localizations.dec;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final isAm = langCode == 'am';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.weeklyTrends,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (error != null)
              Center(
                child: Text(
                  localizations.errorOccurred,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              )
            else if (trendsData == null || trendsData!.trends.isEmpty)
              Center(
                child: Text(
                  localizations.noDataAvailable,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              )
            else
              _buildBarChart(localizations, isAm, trendsData!.trends),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(
    AppLocalizations localizations,
    bool isAm,
    List<DailyTrend> trends,
  ) {
    final reversed = List<DailyTrend>.from(trends).reversed.toList();
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _computeMaxY(reversed),
          minY: 0,
          titlesData: _buildTitlesData(reversed, localizations, isAm),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
          ),
          barGroups: _buildBarGroups(reversed),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData(
    List<DailyTrend> trends,
    AppLocalizations localizations,
    bool isAm,
  ) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, _) => Text(
            value.toInt().toString(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, _) {
            if (value.toInt() >= 0 && value.toInt() < trends.length) {
              final day = trends[value.toInt()].day;
              final parts = day.split('-');
              final month = int.tryParse(parts[1]) ?? 1;
              final dayNum = int.parse(parts[2]);
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_getMonthAbbreviation(month, localizations)} $dayNum',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<DailyTrend> trends) {
    return trends.asMap().entries.map((entry) {
      final idx = entry.key;
      final trend = entry.value;
      final glColor = _glThresholdColor(trend.totalGlycemicLoad);
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: trend.totalCalories.toDouble(),
            color: glColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _computeMaxY(List<DailyTrend> trends) {
    if (trends.isEmpty) return 100.0;
    final maxCalories =
        trends.map((t) => t.totalCalories.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
    final maxGL =
        trends.map((t) => t.totalGlycemicLoad).reduce((a, b) => a > b ? a : b) * 1.2;
    return maxCalories > maxGL ? maxCalories.ceilToDouble() : maxGL.ceilToDouble();
  }
}
