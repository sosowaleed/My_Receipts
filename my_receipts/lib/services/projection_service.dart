import 'package:fl_chart/fl_chart.dart';
import 'package:my_receipts/models/transaction.dart';

// Enum for time period selection
enum ProjectionPeriod { day, week, month, year }

// A new model to hold the rich projection data
class ProjectionData {
  final List<FlSpot> spots;
  final Map<int, DateTime> dateMap; // Maps spot index to its end date
  final Map<int, List<Transaction>> transactionMap; // Maps spot index to transactions in that period

  ProjectionData({
    required this.spots,
    required this.dateMap,
    required this.transactionMap,
  });
}

class ProjectionService {
  List<FlSpot> generateProjection({
    required double startingBalance,
    required double startingX, // The X-coordinate of the last historical point
    required List<Transaction> historicalTransactions,
    required List<Transaction> activeRecurrentTransactions,
    required ProjectionPeriod period,
  }) {
    final now = DateTime.now();
    final List<FlSpot> spots = [FlSpot(startingX, startingBalance)];

    double runningBalance = startingBalance;
    DateTime periodStart = now;

    int steps;
    Duration stepDuration;
    double avgNetPerStep;

    // --- Step 1: Calculate historical average net change PER DAY ---
    final cutoffDate = now.subtract(const Duration(days: 90));
    final recentDiscretionaryTxs = historicalTransactions.where((tx) =>
    !tx.isRecurrent && !tx.timestamp.isBefore(cutoffDate));
    double discretionaryNet90Days = recentDiscretionaryTxs.fold(0.0, (sum, tx) => sum + (tx.type == TransactionType.income ? tx.amount : -tx.amount));
    final avgNetPerDay = discretionaryNet90Days / 90.0;

    // --- Step 2: Configure loop based on selected period ---
    switch (period) {
      case ProjectionPeriod.day:
        steps = 30; // 30 days
        stepDuration = const Duration(days: 1);
        avgNetPerStep = avgNetPerDay;
        break;
      case ProjectionPeriod.week:
        steps = 12; // 12 weeks
        stepDuration = const Duration(days: 7);
        avgNetPerStep = avgNetPerDay * 7;
        break;
      case ProjectionPeriod.month:
        steps = 12; // 12 months
        // Duration is handled manually for months
        stepDuration = const Duration(days: 30); // Placeholder
        avgNetPerStep = avgNetPerDay * 30.4; // Average month length
        break;
      case ProjectionPeriod.year:
        steps = 5; // 5 years
        // Duration is handled manually for years
        stepDuration = const Duration(days: 365); // Placeholder
        avgNetPerStep = avgNetPerDay * 365.25;
        break;
    }

    // --- Step 3: Simulate future steps ---
    for (int i = 1; i <= steps; i++) {
      double stepNetChange = avgNetPerStep;

      DateTime periodEnd;
      if (period == ProjectionPeriod.month) {
        periodEnd = DateTime(now.year, now.month + i, now.day);
      } else if (period == ProjectionPeriod.year) {
        periodEnd = DateTime(now.year + i, now.month, now.day);
      } else {
        periodEnd = now.add(stepDuration * i);
      }

      // Add recurrent transactions that fall within this step
      for (var rTx in activeRecurrentTransactions) {
        bool isApplicable = false;

        switch (rTx.recurrenceType) {
          case 'daily':
            // Daily transactions apply to all projection granularities
            // We multiply by the number of days in this specific step
            int daysInStep = periodEnd.difference(periodStart).inDays;
            if (daysInStep > 0) {
              stepNetChange += (rTx.type == TransactionType.income ? rTx.amount : -rTx.amount) * daysInStep;
              isApplicable = true;
            }
            break;
          case 'weekly':
            if (period == ProjectionPeriod.week || period == ProjectionPeriod.month || period == ProjectionPeriod.year) {
              isApplicable = true;
            }
            break;
          case 'monthly':
            if (period == ProjectionPeriod.month || period == ProjectionPeriod.year) {
              isApplicable = true;
            }
            break;
          case 'yearly':
            if (period == ProjectionPeriod.year) {
              isApplicable = true;
            }
            break;
        }

        if (isApplicable) {
          // For non-daily (discrete) items, we add the amount once per relevant step
          // (e.g., one monthly bill added to a monthly step)
          if (rTx.recurrenceType != 'daily') {
            stepNetChange += (rTx.type == TransactionType.income ? rTx.amount : -rTx.amount);
          }
        }
      }

      runningBalance += stepNetChange;
      spots.add(FlSpot(i.toDouble(), runningBalance));
      periodStart = periodEnd;
    }

    return spots;
  }
}