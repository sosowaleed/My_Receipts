import 'package:flutter/material.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:collection/collection.dart';
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
                _currentCalendar =
                _currentCalendar == 'gregorian' ? 'hijri' : 'gregorian';
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

          // Group transactions by Year based on the current calendar selection
          final groupedByYear = provider.transactions.groupListsBy((tx) {
            return _currentCalendar == 'hijri'
                ? HijriCalendar.fromDate(tx.timestamp).hYear
                : tx.timestamp.year;
          });

          // Get a sorted list of years
          final sortedYears = groupedByYear.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

          return ListView.builder(
            itemCount: sortedYears.length,
            itemBuilder: (ctx, yearIndex) {
              final year = sortedYears[yearIndex];
              final transactionsForYear = groupedByYear[year]!;

              // Now, group the year's transactions by a composite month key
              final groupedByMonth = transactionsForYear.groupListsBy((tx) {
                final hijri = HijriCalendar.fromDate(tx.timestamp);
                return DateKey(
                  gYear: tx.timestamp.year,
                  gMonth: tx.timestamp.month,
                  hYear: hijri.hYear,
                  hMonth: hijri.hMonth,
                );
              });

              // Get a sorted list of month keys
              final sortedMonthKeys = groupedByMonth.keys.toList()
                ..sort((a, b) {
                  // Sort by Gregorian month descending for consistent ordering
                  if (a.gYear != b.gYear) return b.gYear.compareTo(a.gYear);
                  return b.gMonth.compareTo(a.gMonth);
                });

              return GestureDetector(
                onLongPress: () {
                  _showDeleteConfirmationDialog(
                    context: context,
                    title: "Delete Year Data",
                    content:
                    "Are you sure you want to delete all transaction data for the year $year? This action cannot be undone.",
                    onConfirm: () {
                      if (_currentCalendar == 'hijri') {
                        provider.deleteHijriYearTransactions(year);
                      } else {
                        provider.deleteYearTransactions(year);
                      }
                    },
                  );
                },
                child: ExpansionTile(
                  title: Text(year.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  initiallyExpanded: true,
                  children: sortedMonthKeys.map((dateKey) {
                    final transactionsForMonth = groupedByMonth[dateKey]!;

                    // Calculate monthly totals
                    double monthlyIncome = 0;
                    double monthlyExpenses = 0;
                    for (var tx in transactionsForMonth) {
                      if (tx.type == TransactionType.income) {
                        monthlyIncome += tx.amount;
                      } else {
                        monthlyExpenses += tx.amount;
                      }
                    }
                    double netChange = monthlyIncome - monthlyExpenses;

                    return GestureDetector(
                      onLongPress: () {
                        _showDeleteConfirmationDialog(
                          context: context,
                          title: "Delete Month Data",
                          content:
                          "Are you sure you want to delete all transaction data for ${_formatMonthYear(transactionsForMonth.first.timestamp)}? This action cannot be undone.",
                          onConfirm: () {
                            if (_currentCalendar == 'hijri') {
                              provider.deleteHijriMonthTransactions(
                                  dateKey.hYear, dateKey.hMonth);
                            } else {
                              provider.deleteMonthTransactions(
                                  dateKey.gYear, dateKey.gMonth);
                            }
                          },
                        );
                      },
                      child: ExpansionTile(
                        title: Text(
                            _formatMonthYear(transactionsForMonth.first.timestamp)),
                        children: [
                          // List of transactions for the month
                          ...transactionsForMonth.map((tx) {
                            final isIncome = tx.type == TransactionType.income;
                            final currencyFormat = NumberFormat.currency(
                              locale: provider.appLocale.toString(),
                              symbol: provider.appLocale.languageCode == 'ar'
                                  ? 'SAR'
                                  : '\$',
                            );

                            return GestureDetector(
                              onTap: () => _showEditTransactionOptions(context, tx),
                              child: ListTile(
                                leading: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                                title: Text(tx.description),
                                subtitle: Text(
                                    "${_formatDate(tx.timestamp)} - ${tx.categoryName ?? 'N/A'}"),
                                trailing: Text(
                                  currencyFormat.format(tx.amount),
                                  style: TextStyle(
                                      color: isIncome ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }),
                          // Add the monthly summary widget
                          _MonthlySummary(
                            income: monthlyIncome,
                            expenses: monthlyExpenses,
                            net: netChange,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
              SnackbarHelper.show(context, "Data deleted successfully.");
            },
          ),
        ],
      ),
    );
  }
}
class _MonthlySummary extends StatelessWidget {
  final double income;
  final double expenses;
  final double net;

  const _MonthlySummary({
    required this.income,
    required this.expenses,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: Provider.of<ProfileProvider>(context, listen: false).appLocale.toString(),
      symbol: Provider.of<ProfileProvider>(context, listen: false).appLocale.languageCode == 'ar' ? 'SAR' : '\$',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _SummaryRow(
                label: "Total Income",
                value: currencyFormat.format(income),
                color: Colors.green,
              ),
              const SizedBox(height: 4),
              _SummaryRow(
                label: "Total Expenses",
                value: currencyFormat.format(expenses),
                color: Colors.red,
              ),
              const Divider(height: 16),
              _SummaryRow(
                label: net >= 0 ? "Net Profit" : "Net Loss",
                value: currencyFormat.format(net),
                color: net >= 0 ? Colors.blue.shade700 : Colors.orange.shade800,
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Helper widget for a row in the summary card
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class DateKey {
  final int gYear;
  final int gMonth;
  final int hYear;
  final int hMonth;

  DateKey({
    required this.gYear,
    required this.gMonth,
    required this.hYear,
    required this.hMonth,
  });


  // Need to implement hashCode and == for Map keys to work correctly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DateKey &&
              runtimeType == other.runtimeType &&
              gYear == other.gYear &&
              gMonth == other.gMonth;

  @override
  int get hashCode => gYear.hashCode ^ gMonth.hashCode;
}