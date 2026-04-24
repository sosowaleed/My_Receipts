import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/models/sim.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/providers/simulation_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_receipts/services/chart_data_adapter.dart';
import 'package:my_receipts/widgets/charts/monthly_overview_barchart.dart';
import 'package:my_receipts/widgets/charts/category_breakdown_piechart.dart';
import '../models/timeline_period.dart';
import '../models/transaction.dart';
import '../widgets/Charts/financial_timeline_chart.dart';

class ComparisonDashboardScreen extends StatefulWidget {
  final Sim simulationToCompare;
  const ComparisonDashboardScreen({super.key, required this.simulationToCompare});

  @override
  State<ComparisonDashboardScreen> createState() => _ComparisonDashboardScreenState();
}

class _ComparisonDashboardScreenState extends State<ComparisonDashboardScreen> {

  // Projection State
  TimelinePeriod _selectedPeriod = TimelinePeriod.year;
  DateTime _viewingDate = DateTime.now();

  // Chart Colors as constants or themed getters
  static const List<Color> _expenseColors = [
    Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
    Colors.amber, Colors.cyan
  ];

  final List<Color> _incomeColors = [
    Colors.green.shade700, Colors.lightGreen.shade500, Colors.teal.shade400,
    Colors.cyan.shade600, Colors.lime.shade700
  ];

  void _navigateTimeline(int amount) {
    setState(() {
      switch (_selectedPeriod) {
        case TimelinePeriod.day:
          _viewingDate = _viewingDate.add(Duration(days: amount));
          break;
        case TimelinePeriod.week:
          _viewingDate = _viewingDate.add(Duration(days: 7 * amount));
          break;
        case TimelinePeriod.month:
          _viewingDate = DateTime(_viewingDate.year, _viewingDate.month + amount, _viewingDate.day);
          break;
        case TimelinePeriod.year:
          _viewingDate = DateTime(_viewingDate.year + amount, _viewingDate.month, _viewingDate.day);
          break;
        case TimelinePeriod.all:
          break;
      }
    });
  }

  String _getFormattedDateTitle() {
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedPeriod) {
      case TimelinePeriod.day:
        return DateFormat.yMMMMd(l10n.localeName).format(_viewingDate);
      case TimelinePeriod.week:
        final startOfWeek = _viewingDate.subtract(Duration(days: _viewingDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return "${DateFormat.yMd(l10n.localeName).format(startOfWeek)} - ${DateFormat.yMd(l10n.localeName).format(endOfWeek)}";
      case TimelinePeriod.month:
        return DateFormat.yMMMM(l10n.localeName).format(_viewingDate);
      case TimelinePeriod.year:
        return DateFormat.y(l10n.localeName).format(_viewingDate);
      case TimelinePeriod.all:
        return l10n.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileProvider = context.watch<ProfileProvider>();
    final simProvider = context.watch<SimulationProvider>();

    // Prepare Data Adapters (used for static charts)
    final originalAdapter = ChartDataAdapter(transactions: profileProvider.transactions);
    final simulatedAdapter = ChartDataAdapter(transactions: simProvider.simulatedTransactions);

    // --- TIMELINE FILTERING LOGIC (Synchronized for both charts) ---
    final DateTime start, end;
    switch (_selectedPeriod) {
      case TimelinePeriod.day:
        start = DateTime(_viewingDate.year, _viewingDate.month, _viewingDate.day);
        end = start.add(const Duration(days: 1));
        break;
      case TimelinePeriod.week:
        final diff = _viewingDate.weekday - 1;
        start = DateTime(_viewingDate.year, _viewingDate.month, _viewingDate.day).subtract(Duration(days: diff));
        end = start.add(const Duration(days: 7));
        break;
      case TimelinePeriod.month:
        start = DateTime(_viewingDate.year, _viewingDate.month, 1);
        end = DateTime(_viewingDate.year, _viewingDate.month + 1, 1);
        break;
      case TimelinePeriod.year:
        start = DateTime(_viewingDate.year, 1, 1);
        end = DateTime(_viewingDate.year + 1, 1, 1);
        break;
      default: // all
        start = DateTime(1900);
        end = DateTime(2200);
    }

    // Filter transactions for the timeline
    final filteredOriginalTxs = profileProvider.transactions.where((tx) =>
    !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end)).toList();
    final filteredSimulatedTxs = simProvider.simulatedTransactions.where((tx) =>
    !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end)).toList();

    // Calculate initial balances for the start of the current viewing window
    double originalPeriodInitialBalance = profileProvider.currentProfile?.walletAmount ?? 0.0;
    for (final tx in profileProvider.transactions.where((t) => t.timestamp.isAfter(start))) {
      originalPeriodInitialBalance -= (tx.type == TransactionType.income ? tx.amount : -tx.amount);
    }

    double simulatedPeriodInitialBalance = profileProvider.currentProfile?.walletAmount ?? 0.0;
    for (final tx in simProvider.simulatedTransactions.where((t) => t.timestamp.isAfter(start))) {
      simulatedPeriodInitialBalance -= (tx.type == TransactionType.income ? tx.amount : -tx.amount);
    }

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
              // Monthly Overview (Stays same)
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.monthlyOverview,
                originalWidget: MonthlyOverviewBarChart(monthlyTotals: originalAdapter.getMonthlyTotals(6)),
                simulatedWidget: MonthlyOverviewBarChart(monthlyTotals: simulatedAdapter.getMonthlyTotals(6)),
              ),

              // Expense Breakdown (Stays same)
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

              // Earnings Breakdown (Stays same)
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

              // Financial Projection (This is what we are updating to match Dashboard)
              _buildComparisonCard(
                context: context,
                isWide: isWide,
                title: l10n.financialProjection,
                topControl: Column(
                  children: [
                    // SegmentedButton for period selection
                    SegmentedButton<TimelinePeriod>(
                      segments: [
                        ButtonSegment(value: TimelinePeriod.day, label: Text(l10n.day)),
                        ButtonSegment(value: TimelinePeriod.week, label: Text(l10n.week)),
                        ButtonSegment(value: TimelinePeriod.month, label: Text(l10n.months)),
                        ButtonSegment(value: TimelinePeriod.year, label: Text(l10n.year)),
                        ButtonSegment(value: TimelinePeriod.all, label: Text(l10n.all)),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedPeriod = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Navigation Controls
                    if (_selectedPeriod != TimelinePeriod.all)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _navigateTimeline(-1)),
                          Text(_getFormattedDateTitle(), style: Theme.of(context).textTheme.titleMedium),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _navigateTimeline(1)),
                        ],
                      ),
                  ],
                ),
                originalWidget: FinancialTimelineChart(
                  initialBalance: originalPeriodInitialBalance,
                  transactions: filteredOriginalTxs,
                  activeRecurrentTransactions: profileProvider.activeRecurrentTransactions,
                  period: _selectedPeriod,
                  viewingDate: _viewingDate,
                  isSimulation: false,
                ),
                simulatedWidget: FinancialTimelineChart(
                  initialBalance: simulatedPeriodInitialBalance,
                  transactions: filteredSimulatedTxs,
                  activeRecurrentTransactions: const [], // Sim has its own recurrent txs inside its list
                  period: _selectedPeriod,
                  viewingDate: _viewingDate,
                  isSimulation: true,
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
          SizedBox(height: 380, child: child), // Increased height to match Dashboard
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
