import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().fetchSummary(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(l10n.healthDashboard),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () => context.read<DashboardProvider>().fetchSummary(),
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.summaryData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _buildErrorState(provider, l10n);
          }
          if (provider.summaryData == null) {
            return _buildEmptyState(l10n);
          }
          return _buildContent(ctx, provider, l10n, isAm);
        },
      ),
    );
  }

  Widget _buildErrorState(DashboardProvider provider, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(l10n.errorOccurred, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(provider.error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.fetchSummary,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.noAnalyticsData, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(l10n.startTrackingMeals, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, DashboardProvider provider, AppLocalizations l10n, bool isAm) {
    final data = provider.summaryData!;
    final comp = data.comparisons;
    final summary = data.summary;
    return RefreshIndicator(onRefresh: provider.fetchSummary, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _QuickNavCard(icon: Icons.restaurant_menu, label: l10n.viewTodaysMealPlan, color: AppTheme.primaryGreen, onTap: () => Navigator.pushNamed(ctx, '/meal-plan'))), const SizedBox(width: 12), Expanded(child: _QuickNavCard(icon: Icons.book, label: l10n.viewFoodLog, color: AppTheme.accentOrange, onTap: () => Navigator.pushNamed(ctx, '/meal-history')))]),
      const SizedBox(height: 24), Text(l10n.todaysProgress, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildTodayMetrics(summary.today, comp, l10n),
      const SizedBox(height: 24), Text(l10n.metabolicHealth, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildMetabolicGauge(summary.today.glycemicLoad, comp.glycemicLoadLimit, comp.glycemicStatus, l10n),
      const SizedBox(height: 24), Text(l10n.weeklyOverview, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildWeeklySummaryCard(data.dailyTrends, summary, l10n, isAm),
      const SizedBox(height: 24), Text(l10n.nutrientBreakdown, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildNutrientBreakdown(summary.today.macros, comp, l10n),
      const SizedBox(height: 24), Text(l10n.macrosDistribution, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), _buildMacroDistribution(summary.today.macros, l10n),
      const SizedBox(height: 32),
    ])));
  }

  Widget _buildTodayMetrics(TodaySummary today, ComparisonSection comp, AppLocalizations l10n) {
    return Row(children: [Expanded(child: _MetricTile(label: l10n.calories, value: '${today.calories.round()}', subtitle: '${comp.caloriePercentage}% ${l10n.target}', color: AppTheme.primaryGreen)), const SizedBox(width: 8), Expanded(child: _MetricTile(label: l10n.glycemicLoad, value: today.glycemicLoad.toStringAsFixed(1), subtitle: '${comp.glycemicLoadPercentage}% ${l10n.target}', color: _glColor(comp.glycemicStatus))), const SizedBox(width: 8), Expanded(child: _MetricTile(label: l10n.mealsLogged, value: '${today.mealCount}', subtitle: l10n.todaysProgress, color: Colors.indigo))]);
  }

  Widget _buildMetabolicGauge(double currentGL, double limit, String status, AppLocalizations l10n) {
    final pct = limit > 0 ? (currentGL / limit).clamp(0.0, 1.5) : 0.0;
    final displayPct = (pct * 100).round();
    final statusColor = _glColor(status);
    String statusLabel; switch (status) { case 'exceeded': statusLabel = l10n.glycemicLoadExceeded; break; case 'moderate': statusLabel = l10n.glycemicLoadModerate; break; default: statusLabel = l10n.glycemicLoadLow; }
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w600, color: statusColor, fontSize: 15)), Text('${currentGL.toStringAsFixed(1)} / ${limit.toStringAsFixed(0)} ${l10n.g}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]), const SizedBox(height: 14), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 10, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(statusColor))), const SizedBox(height: 8), Text('$displayPct% of ${l10n.target} (${limit.toStringAsFixed(0)} ${l10n.g})', style: TextStyle(color: Colors.grey[600], fontSize: 13))])));
  }

  Widget _buildWeeklySummaryCard(List<DailyTrend> trends, SummarySection summary, AppLocalizations l10n, bool isAm) {
    final maxCal = trends.fold<double>(0.0, (m, t) => t.calories > m ? t.calories : m);
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: _WeeklyStat(label: l10n.avgDaily, value: '${summary.avgDailyCalories.round()}', unit: l10n.kcal, color: AppTheme.primaryGreen)), Container(width: 1, height: 40, color: Colors.grey[300]), Expanded(child: _WeeklyStat(label: l10n.total, value: '${summary.totalCalories.round()}', unit: l10n.kcal, color: AppTheme.accentOrange)), Container(width: 1, height: 40, color: Colors.grey[300]), Expanded(child: _WeeklyStat(label: l10n.glycemicLoad, value: summary.avgDailyGlycemicLoad.toStringAsFixed(1), unit: l10n.g, color: AppTheme.glLow))]),
      const SizedBox(height: 16),
      SizedBox(height: 60, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: trends.map((t) { final barH = maxCal > 0 ? (t.calories / maxCal) * 50 : 0.0; final today = _isToday(t.date); return Expanded(child: Tooltip(message: '${_formatDate(t.date, isAm)}\n${t.calories.round()} ${l10n.kcal}', child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: barH.clamp(4, 50), decoration: BoxDecoration(color: today ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4))))); }).toList())),
      const SizedBox(height: 8),
      Row(children: trends.map((t) { final today = _isToday(t.date); return Expanded(child: Text(_formatDayLabel(t.date, isAm), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: today ? FontWeight.bold : FontWeight.normal, color: today ? AppTheme.primaryGreen : Colors.grey[600]))); }).toList()),
    ])));
  }

  Widget _buildNutrientBreakdown(MacroSet macros, ComparisonSection comp, AppLocalizations l10n) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      _MacroRow(label: l10n.protein, current: macros.proteinG, target: comp.proteinTargetG, percentage: comp.proteinPercentage, unit: l10n.g, color: AppTheme.macroProtein),
      const SizedBox(height: 14),
      _MacroRow(label: l10n.carbs, current: macros.carbsG, target: comp.carbsTargetG, percentage: comp.carbsPercentage, unit: l10n.g, color: AppTheme.macroCarbs),
      const SizedBox(height: 14),
      _MacroRow(label: l10n.fat, current: macros.fatG, target: comp.fatTargetG, percentage: comp.fatPercentage, unit: l10n.g, color: AppTheme.macroFat),
    ])));
  }

  Widget _buildMacroDistribution(MacroSet macros, AppLocalizations l10n) {
    final total = macros.proteinG + macros.carbsG + macros.fatG;
    if (total == 0) { return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l10n.noAnalyticsData, style: const TextStyle(color: Colors.grey))))); }
    final protPct = (macros.proteinG / total * 100).round();
    final carbPct = (macros.carbsG  / total * 100).round();
    final fatPct  = (macros.fatG    / total * 100).round();
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      SizedBox(width: 80, height: 80, child: CustomPaint(size: const Size(80, 80), painter: _MacroPiePainter(protPct: protPct, carbPct: carbPct, fatPct: fatPct))),
      const SizedBox(width: 24),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_LegendItem(color: AppTheme.macroProtein, label: '${l10n.protein} $protPct%'), const SizedBox(height: 8), _LegendItem(color: AppTheme.macroCarbs, label: '${l10n.carbs} $carbPct%'), const SizedBox(height: 8), _LegendItem(color: AppTheme.macroFat, label: '${l10n.fat} $fatPct%')]),
    ])));
  }

  Color _glColor(String status) { switch (status) { case 'exceeded': return AppTheme.glExceeded; case 'moderate': return AppTheme.glModerate; default: return AppTheme.glLow; } }

  String _formatDate(String date, bool isAm) { try { final p = date.split('-'); return '${p[2]}/${p[1]}/${p[0]}'; } catch (_) { return date; } }

  String _formatDayLabel(String date, bool isAm) { try { return date.split('-')[2]; } catch (_) { return ''; } }

  bool _isToday(String date) { final now = DateTime.now(); final ymd = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}'; return ymd == date; }
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickNavCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext context) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 10), Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 2, overflow: TextOverflow.ellipsis))]))));
  }
}

class _MetricTile extends StatelessWidget {
  final String label; final String value; final String subtitle; final Color color;
  const _MetricTile({required this.label, required this.value, required this.subtitle, required this.color});
  @override Widget build(BuildContext context) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600]))])));
  }
}

class _WeeklyStat extends StatelessWidget {
  final String label; final String value; final String unit; final Color color;
  const _WeeklyStat({required this.label, required this.value, required this.unit, required this.color});
  @override Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 4), RichText(text: TextSpan(children: [TextSpan(text: value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)), TextSpan(text: ' $unit', style: TextStyle(fontSize: 10, color: Colors.grey[600]))]))]));
  }
}

class _MacroRow extends StatelessWidget {
  final String label; final double current; final double target; final int percentage; final String unit; final Color color;
  const _MacroRow({required this.label, required this.current, required this.target, required this.percentage, required this.unit, required this.color});
  @override Widget build(BuildContext context) {
    final pct = (percentage / 100).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$label: ${current.toStringAsFixed(1)}$unit / ${target.toStringAsFixed(0)}$unit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)), Text('$percentage%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color)))]);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color; final String label;
  const _LegendItem({required this.color, required this.label});
  @override Widget build(BuildContext context) { return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 13))]); }
}

class _MacroPiePainter extends CustomPainter {
  final int protPct; final int carbPct; final int fatPct;
  const _MacroPiePainter({required this.protPct, required this.carbPct, required this.fatPct});
  @override void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2); final radius = size.width / 2 - 4;
    double angle = -1.5708;
    void drawSegment(Color color, int pct) { if (pct <= 0) return; final sweep = pct / 100 * 2 * 3.14159265359; final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.butt; canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, sweep, false, paint); angle += sweep; }
    drawSegment(AppTheme.macroProtein, protPct); drawSegment(AppTheme.macroCarbs, carbPct); drawSegment(AppTheme.macroFat, fatPct);
  }
  @override bool shouldRepaint(_MacroPiePainter old) => protPct != old.protPct || carbPct != old.carbPct || fatPct != old.fatPct;
}
