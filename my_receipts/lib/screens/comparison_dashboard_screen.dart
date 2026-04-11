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


class ComparisonDashboardScreen extends StatelessWidget {
  final Sim simulationToCompare;
  const ComparisonDashboardScreen({super.key, required this.simulationToCompare});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // We get the real data from ProfileProvider
    final profileProvider = context.watch<ProfileProvider>();
    // We get the simulated data from SimulationProvider
    final simProvider = context.watch<SimulationProvider>();

    // Create Chart Data Adapters for both original and simulated data
    final originalDataAdapter = ChartDataAdapter(transactions: profileProvider.transactions);
    final simulatedDataAdapter = ChartDataAdapter(transactions: simProvider.simulatedTransactions);

    // Calculate the "current" balance of the simulation.
    // This is a conceptual calculation: what would the balance be today if we
    // applied all simulated transactions to the original profile's starting balance.
    // We'll use the final balance of the real provider as the base.
    final realFinalBalance = profileProvider.currentProfile?.walletAmount ?? 0.0;
    // We can't easily know the "initial" balance, so for comparison, we'll
    // calculate the *difference* in net income between the two sets of transactions
    // and apply that difference to the real current balance.
    final realNet = originalDataAdapter.transactions.fold(0.0, (sum, tx) => sum + (tx.type == TransactionType.income ? tx.amount : -tx.amount));
    final simNet = simulatedDataAdapter.transactions.fold(0.0, (sum, tx) => sum + (tx.type == TransactionType.income ? tx.amount : -tx.amount));
    final netDifference = simNet - realNet;
    final simulatedCurrentBalance = realFinalBalance + netDifference;

    final List<Color> pieChartColors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
      Colors.amber, Colors.cyan
    ];
    // Income colors
    final List<Color> incomePieChartColors = [
      Colors.green.shade700, Colors.lightGreen.shade500, Colors.teal.shade400,
      Colors.cyan.shade600, Colors.lime.shade700
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("${l10n.original} vs. ${simulationToCompare.name}"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 720; // A common breakpoint

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              // Here you would build each comparison section
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.monthlyOverview,
                originalWidget: MonthlyOverviewBarChart(monthlyTotals: originalDataAdapter.getMonthlyTotals(6)),
                simulatedWidget: MonthlyOverviewBarChart(monthlyTotals: simulatedDataAdapter.getMonthlyTotals(6)),
              ),
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.expenseBreakdown,
                originalWidget: Column(
                  children: [
                    SizedBox(
                      height: 250, // Adjust height for comparison view
                      child: CategoryBreakdownPieChart(
                        categoryData: originalDataAdapter.getExpenseByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                        colors: pieChartColors, // Define colors
                        noDataText: l10n.noDataForPeriod(l10n.expenses),
                      ),
                    ),
                    PieChartLegend(
                      categoryData: originalDataAdapter.getExpenseByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                      colors: pieChartColors,
                    )
                  ],
                ),
                simulatedWidget: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: CategoryBreakdownPieChart(
                        categoryData: simulatedDataAdapter.getExpenseByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                        colors: pieChartColors,
                        noDataText: l10n.noDataForPeriod(l10n.expenses),
                      ),
                    ),
                    PieChartLegend(
                      categoryData: simulatedDataAdapter.getExpenseByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                      colors: pieChartColors,
                    )
                  ],
                ),
              ),
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.earningsBreakdown,
                originalWidget: Column(
                  children: [
                    SizedBox(
                      height: 250, // Adjust height for comparison view
                      child: CategoryBreakdownPieChart(
                        categoryData: originalDataAdapter.getIncomeByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                        colors: incomePieChartColors, // Define colors
                        noDataText: l10n.noDataForPeriod(l10n.income),
                      ),
                    ),
                    PieChartLegend(
                      categoryData: originalDataAdapter.getIncomeByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                      colors: incomePieChartColors,
                    )
                  ],
                ),
                simulatedWidget: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: CategoryBreakdownPieChart(
                        categoryData: simulatedDataAdapter.getIncomeByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                        colors: incomePieChartColors,
                        noDataText: l10n.noDataForPeriod(l10n.income),
                      ),
                    ),
                    PieChartLegend(
                      categoryData: simulatedDataAdapter.getIncomeByCategory(DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                      colors: incomePieChartColors,
                    ),
                  ],
                ),
              ),
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.financialProjection,
                originalWidget: SizedBox( // Give it a fixed height
                  height: 300,
                  child: ProjectionLineChart(
                    currentBalance: realFinalBalance,
                    historicalTransactions: profileProvider.transactions,
                    // Pass the real active recurrent transactions
                    activeRecurrentTransactions: profileProvider.activeRecurrentTransactions,
                    // Let's use a fixed 12-month projection for comparison
                    monthsToProject: 12,
                  ),
                ),
                simulatedWidget: SizedBox(
                  height: 300,
                  child: ProjectionLineChart(
                    currentBalance: simulatedCurrentBalance,
                    historicalTransactions: simProvider.simulatedTransactions,
                    // Simulations don't have recurrent transactions in our current model, so pass an empty list.
                    activeRecurrentTransactions: const [],
                    monthsToProject: 12,
                  ),
                ),
              ),
            ],
          );
        }

      ),
    );
  }


  Widget _buildComparisonCard({
    required BuildContext context,
    required bool isWide,
    required String title,
    required Widget originalWidget,
    required Widget simulatedWidget,
    Widget? originalLegend, // Optional legend
    Widget? simulatedLegend, // Optional legend
  }) {
    final l10n = AppLocalizations.of(context)!;

    final originalSection = Column(
      children: [
        Text(l10n.original, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 300, child: originalWidget), // Reduced height
        if (originalLegend != null) originalLegend,
      ],
    );

    final simulatedSection = Column(
      children: [
        Text(l10n.simulation, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 300, child: simulatedWidget), // Reduced height
        if (simulatedLegend != null) simulatedLegend,
      ],
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          // This Column should not be constrained in height
          mainAxisSize: MainAxisSize.min, // Allow it to be as tall as its children
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            isWide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: originalSection),
                const SizedBox(width: 16),
                Expanded(child: simulatedSection),
              ],
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                originalSection,
                const SizedBox(height: 24),
                simulatedSection,
              ],
            ),
          ],
        ),
      ),
    );
  }
}