import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_receipts/models/category.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';
import 'package:hijri/hijri_calendar.dart';

class CsvService {
  final dbService = DatabaseService.instance;

  Future<String?> exportToCsv(
      List<Transaction> transactions,
      String profileName, {
        String? dialogTitle,
        String calendarType = 'gregorian',
      }) async {
    if (transactions.isEmpty) {
      log("No transactions to export.");
      return null;
    }

    List<List<dynamic>> rows = [];

    // --- NEW HEADER ROW ---
    // Added "CategoryType" to distinguish between income/outgoing categories
    rows.add([
      "TransactionDate",
      "Type",
      "Amount",
      "Description",
      "Category",
      "CategoryType", // NEW COLUMN
      "Quantity"
    ]);

    for (var tx in transactions) {
      String dateString;
      if (calendarType == 'hijri') {
        final hijriDate = HijriCalendar.fromDate(tx.timestamp);
        dateString = hijriDate.toFormat("yyyy-MM-dd");
      } else {
        dateString = tx.timestamp.toIso8601String().split('T').first;
      }

      final typeString = tx.type.toString().split('.').last;

      rows.add([
        dateString,
        typeString,
        tx.amount,
        tx.description,
        tx.categoryName ?? 'N/A',
        typeString, // The CategoryType is the same as the Transaction Type
        tx.quantity
      ]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final Uint8List fileBytes = utf8.encode(csvData);

    try {
      final String suggestedFileName =
          '${profileName}_receipts_${DateTime.now().millisecondsSinceEpoch}.csv';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Please select where to save the file:',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: fileBytes,
      );

      if (outputPath == null) {
        log("Export cancelled by user.");
        return null;
      }

      log("Export successful to: $outputPath");
      return outputPath;

    } catch (e) {
      log("Error during file export: $e");
      return null;
    }
  }

  Future<bool> importFromCsv(int profileId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return false;

    try {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.length < 2) return false;

      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];

        if (row.length != 7) continue;

        DateTime timestamp = DateTime.tryParse(row[0].toString()) ?? DateTime.now();
        TransactionType type = row[1].toString().toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.outgoing;
        double amount = double.tryParse(row[2].toString()) ?? 0.0;
        String description = row[3].toString();
        String categoryName = row[4].toString();
        // The category's type is now explicitly read from the CSV
        TransactionType categoryType = row[5].toString().toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.outgoing;
        int quantity = int.tryParse(row[6].toString()) ?? 1;

        if (amount <= 0 || categoryName.isEmpty || categoryName == 'N/A') continue;

        // --- UPDATED CATEGORY LOOKUP LOGIC ---
        // Find or create the category using its name, profileId, AND type
        Category? category = await dbService.readCategoryByName(categoryName, profileId, categoryType);
        category ??= await dbService.createCategory(Category(name: categoryName), profileId, categoryType);

        final transaction = Transaction(
          profileId: profileId,
          timestamp: timestamp,
          type: type,
          amount: amount,
          description: description,
          categoryId: category.id!,
          quantity: quantity,
        );

        await dbService.createTransaction(transaction);
      }
      return true;
    } catch (e) {
      log("CSV Import Error: $e");
      return false;
    }
  }
}