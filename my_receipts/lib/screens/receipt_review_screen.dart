import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

import '../utils/snackbar_helper.dart';
import '../widgets/transaction_overlay.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({super.key});

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  // We'll manage the calendar type locally for this screen
  late String _currentCalendar;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize with the profile's preference
    _currentCalendar = Provider.of<ProfileProvider>(context, listen: false).currentProfile?.calendarPreference ?? 'gregorian';
  }

  String _formatDate(DateTime dt) {
    if (_currentCalendar == 'hijri') {
      final hijriDate = HijriCalendar.fromDate(dt);
      return hijriDate.toFormat("dd MMMM yyyy");
    } else {
      return DateFormat.yMMMMd(Provider.of<ProfileProvider>(context, listen: false).appLocale.toString()).format(dt);
    }
  }

  String _formatMonthYear(DateTime dt) {
    if (_currentCalendar == 'hijri') {
      final hijriDate = HijriCalendar.fromDate(dt);
      return hijriDate.toFormat("MMMM yyyy");
    } else {
      return DateFormat.yMMMM(Provider.of<ProfileProvider>(context, listen: false).appLocale.toString()).format(dt);
    }
  }


  // Helper method to show edit options
  void _showEditTransactionOptions(BuildContext context, Transaction tx) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.edit),
            onTap: () {
              Navigator.of(ctx).pop(); // Close the options sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => TransactionOverlay(type: tx.type, existingTransaction: tx),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red.shade700),
            title: Text(l10n.delete, style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              Navigator.of(ctx).pop(); // Close the options sheet
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: Text(l10n.delete),
                  content: Text(l10n.confirmDeleteTransaction),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: Text(l10n.cancel)),
                    TextButton(
                      child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop();
                        await provider.deleteTransaction(tx);
                        if (context.mounted) {
                          SnackbarHelper.show(context, l10n.transactionDeleted);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptReviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: l10n.switchCalendar,
            onPressed: () {
              setState(() {
                _currentCalendar = _currentCalendar == 'gregorian' ? 'hijri' : 'gregorian';
              });
            },
          )
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.transactions.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }

          // Group transactions by Year -> Month
          final grouped = <String, Map<String, List<Transaction>>>{};
          for (var tx in provider.transactions) {
            final yearKey = _currentCalendar == 'hijri' ? HijriCalendar.fromDate(tx.timestamp).hYear.toString() : tx.timestamp.year.toString();
            final monthKey = _formatMonthYear(tx.timestamp);

            grouped.putIfAbsent(yearKey, () => {});
            grouped[yearKey]!.putIfAbsent(monthKey, () => []);
            grouped[yearKey]![monthKey]!.add(tx);
          }

          return ListView.builder(
            itemCount: grouped.keys.length,
            itemBuilder: (ctx, yearIndex) {
              final year = grouped.keys.elementAt(yearIndex);
              final months = grouped[year]!;

              return ExpansionTile(
                title: Text(year, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                initiallyExpanded: true,
                children: months.keys.map((month) {
                  final transactionsForMonth = months[month]!;
                  return ExpansionTile(
                    title: Text(month),
                    children: transactionsForMonth.map((tx) {
                      final isIncome = tx.type == TransactionType.income;
                      final currencyFormat = NumberFormat.currency(
                        locale: provider.appLocale.toString(),
                        symbol: provider.appLocale.languageCode == 'ar' ? 'SAR' : '\$',
                      );

                      return GestureDetector(
                          onTap: () => _showEditTransactionOptions(context, tx),
                      child: ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(tx.description),
                        subtitle: Text("${_formatDate(tx.timestamp)} - ${tx.categoryName}"),
                        trailing: Text(
                          currencyFormat.format(tx.amount),
                          style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                        ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}