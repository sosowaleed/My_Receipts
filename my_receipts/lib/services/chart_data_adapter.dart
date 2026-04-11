import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/models/transaction.dart';

/// A non-notifying class to process a list of transactions into formats needed by charts.
class ChartDataAdapter {
  final List<Transaction> transactions;
  final double initialWalletAmount;

  ChartDataAdapter({required this.transactions, this.initialWalletAmount = 0.0});

  /// Calculates the final balance after all transactions are applied.
  double get finalBalance {
    double balance = initialWalletAmount;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }

  Map<String, double> getSummaryForPeriod(DateTime start, DateTime end) {
    double income = 0;
    double expenses = 0;
    final relevantTxs = transactions.where((tx) =>
    !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end));

    for (var tx in relevantTxs) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expenses += tx.amount;
      }
    }
    return {'income': income, 'expenses': expenses, 'net': income - expenses};
  }

  Map<String, double> getExpenseByCategory(DateTime start, DateTime end) {
    final relevantTxs = transactions.where((tx) =>
    tx.type == TransactionType.outgoing &&
        !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end));

    final grouped = groupBy(relevantTxs, (Transaction tx) => tx.categoryName ?? 'Uncategorized');

    return grouped.map((key, value) => MapEntry(key, value.fold(0.0, (sum, tx) => sum + tx.amount)));
  }

  Map<String, double> getIncomeByCategory(DateTime start, DateTime end) {
    final relevantTxs = transactions.where((tx) =>
    tx.type == TransactionType.income && // The only change is filtering for income
        !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end));

    final grouped = groupBy(relevantTxs, (Transaction tx) => tx.categoryName ?? 'Uncategorized');

    return grouped.map((key, value) => MapEntry(key, value.fold(0.0, (sum, tx) => sum + tx.amount)));
  }

  Map<String, Map<String, double>> getMonthlyTotals(int monthsToGoBack) {
    final now = DateTime.now();
    final data = <String, Map<String, double>>{};

    for (int i = monthsToGoBack - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = {'income': 0.0, 'expenses': 0.0};
    }

    final cutoffDate = DateTime(now.year, now.month - (monthsToGoBack - 1), 1);
    final relevantTxs = transactions.where((tx) => !tx.timestamp.isBefore(cutoffDate));

    for (var tx in relevantTxs) {
      final monthKey = DateFormat('yyyy-MM').format(tx.timestamp);
      if (data.containsKey(monthKey)) {
        if (tx.type == TransactionType.income) {
          data[monthKey]!['income'] = (data[monthKey]!['income'] ?? 0) + tx.amount;
        } else {
          data[monthKey]!['expenses'] = (data[monthKey]!['expenses'] ?? 0) + tx.amount;
        }
      }
    }
    return data;
  }
}