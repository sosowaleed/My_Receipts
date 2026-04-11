import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/projection_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProjectionLineChart extends StatelessWidget {
  final double currentBalance;
  final List<Transaction> historicalTransactions;
  final List<Transaction> activeRecurrentTransactions;
  final int monthsToProject;

  const ProjectionLineChart({
    super.key,
    required this.currentBalance,
    required this.historicalTransactions,
    required this.activeRecurrentTransactions,
    required this.monthsToProject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectionService = ProjectionService();
    final List<FlSpot> spots = projectionService.generateProjection(
      currentBalance: currentBalance,
      historicalTransactions: historicalTransactions,
      activeRecurrentTransactions: activeRecurrentTransactions,
      monthsToProject: monthsToProject,
    );

    if (spots.length < 2) {
      return Center(child: Text(l10n.noDataForPeriod('')));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 6 == 0) { // Show label every 6 months
                  return SideTitleWidget(
                      axisSide: meta.axisSide, child: Text("${value.toInt()}m"));
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 60)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}