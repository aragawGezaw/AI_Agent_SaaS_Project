// Part 1: imports + state class up to _buildErrorState
const fs = require('fs');
const c = "import 'package:flutter/material.dart';\n" +
"import 'package:provider/provider.dart';\n" +
"import '../../../core/theme/app_theme.dart';\n" +
"import '../../../l10n/app_localizations.dart';\n" +
"import '../models/dashboard_summary.dart';\n" +
"import '../providers/dashboard_provider.dart';\n\n" +
"class DashboardScreen extends StatefulWidget {\n" +
"  const DashboardScreen({super.key});\n" +
"  @override\n" +
"  State<DashboardScreen> createState() => _DashboardScreenState();\n" +
"}\n\n" +
"class _DashboardScreenState extends State<DashboardScreen> {\n" +
"  @override\n" +
"  void initState() {\n" +
"    super.initState();\n" +
"    WidgetsBinding.instance.addPostFrameCallback(\n" +
"      (_) => context.read<DashboardProvider>().fetchSummary(),\n" +
"    );\n" +
"  }\n\n" +
"  @override\n" +
"  Widget build(BuildContext context) {\n" +
"    final l10n = AppLocalizations.of(context)!" + ";\n" +
"    final isAm = Localizations.localeOf(context).languageCode == 'am';\n" +
"    return Scaffold(\n" +
"      backgroundColor: AppTheme.scaffoldBackground,\n" +
"      appBar: AppBar(\n" +
"        title: Text(l10n.healthDashboard),\n" +
"        backgroundColor: AppTheme.primaryGreen,\n" +
"        foregroundColor: Colors.white,\n" +
"        elevation: 0,\n" +
"        actions: [\n" +
"          IconButton(\n" +
"            icon: const Icon(Icons.refresh),\n" +
"            tooltip: l10n.refresh,\n" +
"            onPressed: () => context.read<DashboardProvider>().fetchSummary(),\n" +
"          ),\n" +
"        ],\n" +
"      ),\n" +
"      body: Consumer<DashboardProvider>(\n" +
"        builder: (ctx, provider, _) {\n" +
"          if (provider.isLoading && provider.summaryData == null) {\n" +
"            return const Center(child: CircularProgressIndicator());\n" +
"          }\n" +
"          if (provider.error != null) {\n" +
"            return _buildErrorState(provider, l10n);\n" +
"          }\n" +
"          if (provider.summaryData == null) {\n" +
"            return _buildEmptyState(l10n);\n" +
"          }\n" +
"          return _buildContent(ctx, provider, l10n, isAm);\n" +
"        },\n" +
"      ),\n" +
"    );\n" +
"  }\n";
fs.writeFileSync('lib/features/analytics/screens/_p1.dart', c, 'utf8');
console.log('p1', c.length);
