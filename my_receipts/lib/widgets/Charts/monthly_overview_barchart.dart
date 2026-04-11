import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MonthlyOverviewBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> monthlyTotals;

  const MonthlyOverviewBarChart({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (monthlyTotals.values.every((e) => e['income'] == 0 && e['expenses'] == 0)) {
      return Center(child: Text(l10n.noDataForPeriod('')));
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
            final monthText = DateFormat('MMM', l10n.localeName).format(DateFormat('yyyy-MM').parse(keys[value.toInt()]));
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
                '${rodIndex == 0 ? l10n.income : l10n.expenses}\n',
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
}