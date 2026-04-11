import 'package:flutter/material.dart';
import 'package:my_receipts/models/sim.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/providers/simulation_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_receipts/services/chart_data_adapter.dart';
import 'package:my_receipts/widgets/charts/monthly_overview_barchart.dart';
import 'package:my_receipts/widgets/charts/category_breakdown_piechart.dart';
import '../models/transaction.dart';
import '../widgets/Charts/projection_linechart.dart';

class ComparisonDashboardScreen extends StatefulWidget {
  final Sim simulationToCompare;
  const ComparisonDashboardScreen({super.key, required this.simulationToCompare});

  @override
  State<ComparisonDashboardScreen> createState() => _ComparisonDashboardScreenState();
}

class _ComparisonDashboardScreenState extends State<ComparisonDashboardScreen> {
  double _projectionMonths = 12.0;

  // Chart Colors as constants or themed getters
  static const List<Color> _expenseColors = [
    Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
    Colors.amber, Colors.cyan
  ];

  final List<Color> _incomeColors = [
    Colors.green.shade700, Colors.lightGreen.shade500, Colors.teal.shade400,
    Colors.cyan.shade600, Colors.lime.shade700
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileProvider = context.watch<ProfileProvider>();
    final simProvider = context.watch<SimulationProvider>();

    // 1. Prepare Data Adapters
    final originalAdapter = ChartDataAdapter(transactions: profileProvider.transactions);
    final simulatedAdapter = ChartDataAdapter(transactions: simProvider.simulatedTransactions);

    // 2. Calculate Balances
    final realFinalBalance = profileProvider.currentProfile?.walletAmount ?? 0.0;

    // Efficiency: Calculate nets once per build
    double calculateNet(List<Transaction> txs) => txs.fold(0.0, (sum, tx) =>
    sum + (tx.type == TransactionType.income ? tx.amount : -tx.amount));

    final realNet = calculateNet(originalAdapter.transactions);
    final simNet = calculateNet(simulatedAdapter.transactions);
    final simulatedCurrentBalance = realFinalBalance + (simNet - realNet);

    final simActiveRecurrentTxs = simProvider.simulatedTransactions.where((tx) =>
    tx.isRecurrent && (tx.recurrenceEndDate == null || tx.recurrenceEndDate!.isAfter(DateTime.now()))
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.original} vs. ${widget.simulationToCompare.name}"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 720;

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              // Monthly Overview
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.monthlyOverview,
                originalWidget: MonthlyOverviewBarChart(monthlyTotals: originalAdapter.getMonthlyTotals(6)),
                simulatedWidget: MonthlyOverviewBarChart(monthlyTotals: simulatedAdapter.getMonthlyTotals(6)),
              ),

              // Expense Breakdown
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.expenseBreakdown,
                originalWidget: _BreakdownSection(
                  adapter: originalAdapter,
                  isIncome: false,
                  colors: _expenseColors,
                  l10n: l10n,
                ),
                simulatedWidget: _BreakdownSection(
                  adapter: simulatedAdapter,
                  isIncome: false,
                  colors: _expenseColors,
                  l10n: l10n,
                ),
              ),

              // Earnings Breakdown
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.earningsBreakdown,
                originalWidget: _BreakdownSection(
                  adapter: originalAdapter,
                  isIncome: true,
                  colors: _incomeColors,
                  l10n: l10n,
                ),
                simulatedWidget: _BreakdownSection(
                  adapter: simulatedAdapter,
                  isIncome: true,
                  colors: _incomeColors,
                  l10n: l10n,
                ),
              ),

              // Financial Projection
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.financialProjection,
                // Move Slider here so it's above both charts and affects both
                topControl: Column(
                  children: [
                    Text("${l10n.projectionPeriod}: ${_projectionMonths.round()} ${l10n.months}"),
                    Slider(
                      value: _projectionMonths,
                      min: 1, max: 60, divisions: 59,
                      onChanged: (val) => setState(() => _projectionMonths = val),
                    ),
                  ],
                ),
                originalWidget: ProjectionLineChart(
                  currentBalance: realFinalBalance,
                  historicalTransactions: profileProvider.transactions,
                  activeRecurrentTransactions: profileProvider.activeRecurrentTransactions,
                  monthsToProject: _projectionMonths.toInt(),
                ),
                simulatedWidget: ProjectionLineChart(
                  currentBalance: simulatedCurrentBalance,
                  historicalTransactions: simProvider.simulatedTransactions,
                  activeRecurrentTransactions: simActiveRecurrentTxs,
                  monthsToProject: _projectionMonths.toInt(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComparisonCard({
    required BuildContext context,
    required bool isWide,
    required String title,
    required Widget originalWidget,
    required Widget simulatedWidget,
    Widget? topControl,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    Widget buildSubSection(String label, Widget child) {
      return Column(
        children: [
          Text(label, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 300, child: child),
        ],
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: textTheme.titleLarge),
            if (topControl != null) ...[
              const SizedBox(height: 8),
              topControl,
            ],
            const SizedBox(height: 16),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: buildSubSection(l10n.original, originalWidget)),
                  const SizedBox(width: 24),
                  Expanded(child: buildSubSection(l10n.simulation, simulatedWidget)),
                ],
              )
            else
              Column(
                children: [
                  buildSubSection(l10n.original, originalWidget),
                  const Divider(height: 48),
                  buildSubSection(l10n.simulation, simulatedWidget),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget to reduce duplication in Pie Chart sections
class _BreakdownSection extends StatelessWidget {
  final ChartDataAdapter adapter;
  final bool isIncome;
  final List<Color> colors;
  final AppLocalizations l10n;

  const _BreakdownSection({
    required this.adapter,
    required this.isIncome,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final categoryData = isIncome
        ? adapter.getIncomeByCategory(lastMonth, now)
        : adapter.getExpenseByCategory(lastMonth, now);

    return Column(
      children: [
        Expanded(
          child: CategoryBreakdownPieChart(
            categoryData: categoryData,
            colors: colors,
            noDataText: l10n.noDataForPeriod(isIncome ? l10n.income : l10n.expenses),
          ),
        ),
        PieChartLegend(categoryData: categoryData, colors: colors),
      ],
    );
  }
}