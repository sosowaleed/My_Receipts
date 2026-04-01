import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';

class RecurrenceService {
  final dbService = DatabaseService.instance;

  Future<void> processRecurrentTransactions(int profileId) async {
    final recurrentTxs = await dbService.readActiveRecurrentTransactions(profileId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in recurrentTxs) {
      // Deactivate if end date is passed
      if (tx.recurrenceEndDate != null && tx.recurrenceEndDate!.isBefore(today)) {
        final disabledTx = Transaction(
          // copy all fields and set isRecurrent to false
          id: tx.id,
          profileId: tx.profileId,
          type: tx.type,
          amount: tx.amount,
          description: tx.description,
          categoryId: tx.categoryId,
          quantity: tx.quantity,
          timestamp: tx.timestamp,
          isRecurrent: false, // Deactivate
        );
        await dbService.updateRecurrentTransaction(disabledTx);
        continue;
      }

      DateTime nextDate = tx.lastAppliedDate ?? tx.timestamp;
      while (nextDate.isBefore(today)) {
        // Calculate the next occurrence date
        switch (tx.recurrenceType) {
          case 'daily':
            nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 1);
            break;
          case 'weekly':
            nextDate = DateTime(nextDate.year, nextDate.month, nextDate.day + 7);
            break;
          case 'monthly':
          // Robustly handle month additions
            var newMonth = nextDate.month + 1;
            var newYear = nextDate.year;
            if (newMonth > 12) {
              newMonth = 1;
              newYear += 1;
            }
            nextDate = DateTime(newYear, newMonth, nextDate.day);
            break;
        }

        // If the calculated next date is still in the past or today, create an instance
        if (!nextDate.isAfter(today)) {
          final newInstance = Transaction(
            profileId: tx.profileId,
            type: tx.type,
            amount: tx.amount,
            description: tx.description,
            categoryId: tx.categoryId,
            quantity: tx.quantity,
            timestamp: nextDate, // The new instance is for this date
            isRecurrent: false, // Instances are not recurrent
          );
          await dbService.createTransaction(newInstance);
        }
      }

      // Update the original recurrent transaction's last applied date
      final updatedTx = Transaction(
        id: tx.id,
        profileId: tx.profileId,
        type: tx.type,
        amount: tx.amount,
        description: tx.description,
        categoryId: tx.categoryId,
        quantity: tx.quantity,
        timestamp: tx.timestamp,
        isRecurrent: tx.isRecurrent,
        recurrenceType: tx.recurrenceType,
        recurrenceEndDate: tx.recurrenceEndDate,
        lastAppliedDate: today, // Update to today
      );
      await dbService.updateRecurrentTransaction(updatedTx);
    }
  }
}