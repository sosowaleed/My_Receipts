import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:my_receipts/providers/simulation_provider.dart';
import 'package:my_receipts/widgets/transaction_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/utils/snackbar_helper.dart';
import '../models/category.dart';
import '../screens/comparison_dashboard_screen.dart';

class SimulationWorkspaceScreen extends StatelessWidget {
  const SimulationWorkspaceScreen({super.key});

  void _showSimTransactionOverlay(BuildContext context, TransactionType type, {Transaction? tx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TransactionOverlay(
        type: type,
        existingTransaction: tx,
        isSimulation: true, // IMPORTANT: Set the simulation flag
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Transaction tx) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSimulatedTransaction),
        content: Text(l10n.confirmDeleteSimulatedTransaction),
        actions: [
          TextButton(child: Text(l10n.cancel), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<SimulationProvider>().deleteSimulatedTransaction(tx.id!);
              SnackbarHelper.show(context, "Simulated transaction deleted.");
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final simProvider = context.watch<SimulationProvider>();
    final profileProvider = context.watch<ProfileProvider>(); // Needed for categories
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
        locale: profileProvider.appLocale.toString(),
        symbol: profileProvider.appLocale.languageCode == 'ar' ? 'SAR' : '\$');
    final allCategories = profileProvider.incomeCategories + profileProvider.outgoingCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(simProvider.activeSimulation?.name ?? l10n.simulationWorkspace),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: "Exist without saving",
          onPressed: () {
            // Exit without saving
            context.read<SimulationProvider>().stopSimulation();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: "Analyze & Compare",
            onPressed: () {
              if (simProvider.activeSimulation != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ComparisonDashboardScreen(
                      simulationToCompare: simProvider.activeSimulation!,
                    ),
                  ),
                );
              }
            },
          ),
          TextButton(
            child: Text(l10n.saveSimulation, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            onPressed: () {
              // The state is already saved in the DB transaction-by-transaction.
              // We just need to stop the simulation mode and exit.
              context.read<SimulationProvider>().stopSimulation();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: simProvider.simulatedTransactions.isEmpty
                ? const Center(child: Text("No transactions in this simulation yet."))
                : ListView.builder(
              itemCount: simProvider.simulatedTransactions.length,
              itemBuilder: (ctx, index) {
                final tx = simProvider.simulatedTransactions[index];
                final isIncome = tx.type == TransactionType.income;
                // Note: For a full implementation, you would need to join category names
                // for simulated transactions as well. For now, we'll show ID.
                final category = allCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => Category(id:0, name:l10n.uncategorized));

                return ListTile(
                  leading: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(tx.description),
                  subtitle: Text("${DateFormat.yMd().format(tx.timestamp)} - ${category.name}"),
                  trailing: Text(
                    currencyFormat.format(tx.amount),
                    style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    _showSimTransactionOverlay(context, tx.type, tx: tx);
                  },
                  onLongPress: () {
                    _showDeleteConfirmDialog(context, tx);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddMenu(context),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.green),
            title: Text(l10n.addSimulatedIncome),
            onTap: () {
              Navigator.pop(ctx);
              _showSimTransactionOverlay(context, TransactionType.income);
            },
          ),
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.red),
            title: Text(l10n.addSimulatedExpense),
            onTap: () {
              Navigator.pop(ctx);
              _showSimTransactionOverlay(context, TransactionType.outgoing);
            },
          )
        ],
      ),
    );
  }
}