import 'package:flutter/material.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/screens/simulation_workspace_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/sim.dart';
import '../providers/simulation_provider.dart';
import '../services/database_service.dart';
import '../utils/snackbar_helper.dart';
import '../services/csv_service.dart';
import 'comparison_dashboard_screen.dart';
import 'package:my_receipts/widgets/charts/category_breakdown_piechart.dart';
import 'package:my_receipts/widgets/charts/monthly_overview_barchart.dart';
import 'package:my_receipts/widgets/charts/projection_linechart.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  // State for the projection
  double _projectionMonths = 12; // Default projection for 1 year
  // Define colors for the pie chart to be used by the chart and the legend
  //Expense colors
  final List<Color> _pieChartColors = [
    Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
    Colors.amber, Colors.cyan
  ];
  // Income colors
  final List<Color> _incomePieChartColors = [
    Colors.green.shade700, Colors.lightGreen.shade500, Colors.teal.shade400,
    Colors.cyan.shade600, Colors.lime.shade700
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
              child: MonthlyOverviewBarChart(monthlyTotals: provider.getMonthlyTotals(6)),
            ),
            const Divider(height: 32),

            // --- 3. EXPENSE BREAKDOWN PIE CHART ---
            Text(l10n.expenseBreakdown, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: CategoryBreakdownPieChart(
                categoryData: provider.getExpenseByCategory(last30DaysStart, now),
                colors: _pieChartColors,
                noDataText: l10n.noDataForPeriod(l10n.expenses),
              ),
            ),
            PieChartLegend(
              categoryData: provider.getExpenseByCategory(last30DaysStart, now),
              colors: _pieChartColors,
            ),
            const Divider(height: 32),
            // --- 4. EARNINGS BREAKDOWN PIE CHART ---
            Text(l10n.earningsBreakdown, style: Theme.of(context).textTheme.titleLarge), // Add to localization files
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: CategoryBreakdownPieChart(
                categoryData: provider.getIncomeByCategory(last30DaysStart, now),
                colors: _incomePieChartColors,
                noDataText: l10n.noDataForPeriod(l10n.income),
              ),
            ),
            PieChartLegend(
              categoryData: provider.getIncomeByCategory(last30DaysStart, now),
              colors: _incomePieChartColors,
            ),
            const Divider(height: 32),

            // --- 5. FINANCIAL PROJECTION ---
            Text(l10n.financialProjection, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ProjectionLineChart(
                currentBalance: provider.currentProfile?.walletAmount ?? 0.0,
                historicalTransactions: provider.transactions,
                activeRecurrentTransactions: provider.activeRecurrentTransactions,
                monthsToProject: _projectionMonths.round(),
              ),
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
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.science_outlined),
            label: Text(l10n.simulate),
            onPressed: () => _showSimulateOptions(context),
          ),
        ),
      ),
    );
  }

  void _showSimulateOptions(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final simProvider = Provider.of<SimulationProvider>(context, listen: false);
    final dbService = DatabaseService.instance;
    final l10n = AppLocalizations.of(context)!;
    final currentProfileId = profileProvider.currentProfile!.id!;
    final csvService = CsvService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to be taller
      builder: (ctx) {
        return StatefulBuilder( // Use StatefulBuilder for local state management
          builder: (modalContext, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.newSimulation, style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.history_edu),
                    label: Text(l10n.newFromHistory),
                    onPressed: () async {
                      Navigator.pop(ctx); // Close sheet
                      final sim = await dbService.createSimulation(
                          profileId: currentProfileId,
                          name: "Copy of ${DateFormat.yMd().format(DateTime.now())}");
                      await dbService.copyRealTransactionsToSimulation(sim.id, currentProfileId);
                      final txs = await dbService.readSimulatedTransactions(sim.id);
                      simProvider.startSimulation(sim, txs);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimulationWorkspaceScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newFromBlank),
                    onPressed: () async {
                      Navigator.pop(ctx); // Close sheet
                      final sim = await dbService.createSimulation(
                          profileId: currentProfileId,
                          name: "Blank Sim ${DateFormat.yMd().format(DateTime.now())}");
                      simProvider.startSimulation(sim, []);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimulationWorkspaceScreen()));
                    },
                  ),
                  const Divider(height: 24),
                  Text(l10n.simulations, style: Theme.of(ctx).textTheme.headlineSmall),

                  // Use a FutureBuilder to load and display saved simulations
                  FutureBuilder<List<Sim>>(
                    future: dbService.readSimulations(currentProfileId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text("No saved simulations yet."),
                        );
                      }
                      final sims = snapshot.data!;
                      return Flexible( // Allow list to scroll if it's long
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sims.length,
                          itemBuilder: (context, index) {
                            final sim = sims[index];
                            return ListTile(
                              title: Text(sim.name),
                              subtitle: Text("Created: ${DateFormat.yMd().format(sim.createdAt)}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () async {
                                  // Show confirmation dialog before deleting
                                  await dbService.deleteSimulation(sim.id);
                                  setState(() {}); // Rebuild the modal to refresh the list
                                },
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final txs = await dbService.readSimulatedTransactions(sim.id);
                                simProvider.startSimulation(sim, txs);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SimulationWorkspaceScreen()));
                              },
                              leading: IconButton(
                                icon: const Icon(Icons.analytics_outlined),
                                tooltip: "Compare",
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final txs = await dbService.readSimulatedTransactions(sim.id);
                                  simProvider.startSimulation(sim, txs);
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => ComparisonDashboardScreen(simulationToCompare: sim)
                                  )).then((_) => simProvider.stopSimulation());
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // --- NEW IMPORT/EXPORT SECTION ---
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: Text(l10n.importSimulation),
                          onPressed: () async {
                            Navigator.pop(ctx); // Close sheet first
                            final importedSim = await csvService.importSimulationFromCsv(currentProfileId);
                            if (importedSim != null) {
                              SnackbarHelper.show(context, "Simulation '${importedSim.name}' imported successfully.");
                              // Optionally, you could automatically open the imported sim
                            } else {
                              SnackbarHelper.show(context, "Simulation import failed.", isError: true);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: Text(l10n.exportSimulation),
                          onPressed: () async {
                            // First, ask which simulation to export
                            final simulations = await dbService.readSimulations(currentProfileId);
                            if (simulations.isEmpty) {
                              Navigator.pop(ctx);
                              SnackbarHelper.show(context, "No saved simulations to export.", isError: true);
                              return;
                            }

                            final simToExport = await showDialog<Sim>(
                              context: context,
                              builder: (dialogCtx) => SimpleDialog(
                                title: Text(l10n.selectSimulationToExport),
                                children: simulations.map((sim) => SimpleDialogOption(
                                  onPressed: () => Navigator.pop(dialogCtx, sim),
                                  child: Text(sim.name),
                                )).toList(),
                              ),
                            );

                            if (simToExport != null) {
                              Navigator.pop(ctx); // Close main sheet
                              final txs = await dbService.readSimulatedTransactions(simToExport.id);
                              final path = await csvService.exportSimulationToCsv(
                                simulation: simToExport,
                                transactions: txs,
                              );
                              if (path != null) {
                                SnackbarHelper.show(context, "Simulation exported to $path");
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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