import 'package:fl_chart/fl_chart.dart';
import 'package:my_receipts/models/transaction.dart';

class ProjectionService {
  /// Generates a list of data points for a financial projection chart.
  List<FlSpot> generateProjection({
    required double currentBalance,
    required List<Transaction> historicalTransactions,
    required List<Transaction> activeRecurrentTransactions,
    required int monthsToProject,
  }) {
    final now = DateTime.now();

    // --- Step 1: Calculate Baseline Discretionary Spending ---
    // Look at non-recurrent transactions from the last 90 days
    final cutoffDate = now.subtract(const Duration(days: 90));
    final recentDiscretionaryTxs = historicalTransactions.where((tx) =>
    !tx.isRecurrent && !tx.timestamp.isBefore(cutoffDate));

    double discretionaryNet = 0;
    for (var tx in recentDiscretionaryTxs) {
      discretionaryNet += (tx.type == TransactionType.income ? tx.amount : -tx.amount);
    }
    // Average it out per month (90 days ~ 3 months)
    final avgMonthlyDiscretionaryNet = discretionaryNet / 3.0;

    // --- Step 2: Simulate Future Months ---
    final List<FlSpot> spots = [FlSpot(0, currentBalance)];
    double runningBalance = currentBalance;

    for (int i = 1; i <= monthsToProject; i++) {
      // Start with the discretionary average for this month
      double thisMonthNetChange = avgMonthlyDiscretionaryNet;

      final monthToSimulate = DateTime(now.year, now.month + i, 1);
      final startOfThisMonth = DateTime(now.year, now.month + i - 1, 1);
      final endOfThisMonth = DateTime(now.year, now.month + i, 0); // Day 0 gives last day of prev month

      // --- Step 3: Add scheduled recurrent transactions for this month ---
      for (var rTx in activeRecurrentTransactions) {
        if (rTx.recurrenceType == 'monthly') {
          // If the transaction day is in this month, add it
          if (rTx.timestamp.day <= endOfThisMonth.day) {
            thisMonthNetChange += (rTx.type == TransactionType.income ? rTx.amount : -rTx.amount);
          }
        }
        if (rTx.recurrenceType == 'daily') {
          thisMonthNetChange += (rTx.type == TransactionType.income ? rTx.amount : -rTx.amount) * endOfThisMonth.day;
        }
        if (rTx.recurrenceType == 'weekly') {
          // Approximate to 4 weeks per month for simplicity
          thisMonthNetChange += (rTx.type == TransactionType.income ? rTx.amount : -rTx.amount) * 4;
        }
        // A full implementation would more precisely check day-of-week, etc.
      }

      // Update the running balance and add the data point
      runningBalance += thisMonthNetChange;
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }

    return spots;
  }
}