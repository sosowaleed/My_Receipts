import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  // State for the projection
  double _projectionMonths = 12; // Default projection for 1 year
  // Define colors for the pie chart to be used by the chart and the legend
  final List<Color> _pieChartColors = [
    Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
    Colors.amber, Colors.cyan
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
        locale: provider.appLocale.toString(),
        symbol: provider.appLocale.languageCode == 'ar' ? 'SAR' : '\$');

    final now = DateTime.now();
    final last30DaysStart = now.subtract(const Duration(days: 30));
    final summary30Days = provider.getSummaryForPeriod(last30DaysStart, now);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.financialDashboard),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. SUMMARY CARDS ---
            Text(l10n.last30DaysSummary, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _SummaryCard(title: l10n.income, value: currencyFormat.format(summary30Days['income']), color: Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(title: l10n.expenses, value: currencyFormat.format(summary30Days['expenses']), color: Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _SummaryCard(title: l10n.netSavings, value: currencyFormat.format(summary30Days['net']), color: summary30Days['net']! >= 0 ? Colors.blue : Colors.orange)),
              ],
            ),
            const Divider(height: 32),

            // --- 2. INCOME VS EXPENSE BAR CHART ---
            Text(l10n.monthlyOverview, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildBarChart(context, provider.getMonthlyTotals(6)),
            ),
            const Divider(height: 32),

            // --- 3. EXPENSE BREAKDOWN PIE CHART ---
            Text(l10n.expenseBreakdown, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildPieChart(context, provider.getExpenseByCategory(last30DaysStart, now)),
            ),
            _buildPieChartLegend(context, provider.getExpenseByCategory(last30DaysStart, now)),
            const Divider(height: 32),

            // --- 4. FINANCIAL PROJECTION ---
            Text(l10n.financialProjection, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildProjectionChart(context, provider),
            ),
            Slider(
              value: _projectionMonths,
              min: 1,
              max: 60,
              divisions: 59,
              label: "${_projectionMonths.round()} ${l10n.months}",
              onChanged: (value) {
                setState(() {
                  _projectionMonths = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CHART BUILDER METHODS ---

  Widget _buildBarChart(BuildContext context, Map<String, Map<String, double>> monthlyTotals) {
    final l10n = AppLocalizations.of(context)!;
    if (monthlyTotals.values.every((e) => e['income'] == 0 && e['expenses'] == 0)) {
      return Center(child: Text(l10n.noDataForPeriod('monthly')));
    }

    final barGroups = <BarChartGroupData>[];
    final keys = monthlyTotals.keys.toList();

    for (int i = 0; i < keys.length; i++) {
      final monthKey = keys[i];
      final totals = monthlyTotals[monthKey]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: totals['income']!, color: Colors.green, width: 16, borderRadius: BorderRadius.zero),
            BarChartRodData(toY: totals['expenses']!, color: Colors.red, width: 16, borderRadius: BorderRadius.zero),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            final monthText = DateFormat('MMM', AppLocalizations.of(context)!.localeName).format(DateFormat('yyyy-MM').parse(keys[value.toInt()]));
            return SideTitleWidget(axisSide: meta.axisSide, child: Text(monthText));
          })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final currencyFormat = NumberFormat.currency(locale: Provider.of<ProfileProvider>(context, listen: false).appLocale.toString(), symbol: '');
              return BarTooltipItem(
                '${rodIndex == 0 ? "Income" : "Expense"}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: currencyFormat.format(rod.toY),
                    style: TextStyle(color: rod.color),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> expenseData) {
    final l10n = AppLocalizations.of(context)!;
    if (expenseData.isEmpty) {
      return Center(child: Text(l10n.noDataForPeriod('expense')));
    }
    final totalExpenses = expenseData.values.fold(0.0, (sum, item) => sum + item);
    if (totalExpenses == 0) {
      return Center(child: Text(l10n.noDataForPeriod('expense')));
    }

    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    expenseData.forEach((category, amount) {
      final percentage = (amount / totalExpenses) * 100;
      sections.add(
        PieChartSectionData(
          color: _pieChartColors[colorIndex % _pieChartColors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPieChartLegend(BuildContext context, Map<String, double> expenseData) {
    if (expenseData.isEmpty) return const SizedBox.shrink();

    int colorIndex = 0;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: expenseData.keys.map((category) {
        final widget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, color: _pieChartColors[colorIndex % _pieChartColors.length]),
            const SizedBox(width: 4),
            Text(category == 'Uncategorized' ? l10n.uncategorized : category),
          ],
        );
        colorIndex++;
        return widget;
      }).toList(),
    );
  }

  Widget _buildProjectionChart(BuildContext context, ProfileProvider provider) {
    final now = DateTime.now();
    final currentBalance = provider.currentProfile?.walletAmount ?? 0.0;
    //final l10n = AppLocalizations.of(context)!;

    // Projection Logic
    final last3MonthsStart = DateTime(now.year, now.month - 3, now.day);
    final summary3Months = provider.getSummaryForPeriod(last3MonthsStart, now);
    final avgMonthlySavings = (summary3Months['net'] ?? 0.0) / 3.0;

    // In a full implementation, you'd calculate the net monthly change of active recurrent transactions.
    // We'll assume it's part of the historical average for this version.
    final totalMonthlyChange = avgMonthlySavings;

    final List<FlSpot> spots = [FlSpot(0, currentBalance)];
    for (int i = 1; i <= _projectionMonths.round(); i++) {
      final projectedBalance = currentBalance + (totalMonthlyChange * i);
      spots.add(FlSpot(i.toDouble(), projectedBalance));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() % 6 == 0) { // Show label every 6 months
              return SideTitleWidget(axisSide: meta.axisSide, child: Text("${value.toInt()}m"));
            }
            return const SizedBox.shrink();
          }, reservedSize: 30)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}

// Helper widget for summary cards
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}