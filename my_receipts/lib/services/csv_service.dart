import 'dart:developer';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:my_receipts/models/category.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';

class CsvService {
  final dbService = DatabaseService.instance;

  /// This function handles platform differences for saving files.
  /// - On mobile (Android/iOS), it passes the file bytes directly to the file picker.
  /// - On desktop (Windows/macOS/Linux), it gets a save path and then writes the file.
  ///
  /// Returns the chosen file path on success, or `null` if the user cancels
  /// the operation or an error occurs.
  Future<String?> exportToCsv(
    List<Transaction> transactions,
    String profileName, {
    String? dialogTitle,
    String calendarType = 'gregorian',
  }) async {
    if (transactions.isEmpty) {
      // Nothing to export
      log("No transactions to export.");
      return null;
    }
    // --- Step 1: Prepare the CSV data ---
    List<List<dynamic>> rows = [];
    // Changed "Timestamp" to "Date" for clarity
    rows.add(["Date", "Type", "Amount", "Description", "Category", "Quantity"]);
    for (var tx in transactions) {
      String dateString;
      // Using the chosen calendar type to format the date
      if (calendarType == 'hijri') {
        final hijriDate = HijriCalendar.fromDate(tx.timestamp);
        // Using a clean, machine-readable format
        dateString = hijriDate.toFormat("yyyy-MM-dd");
      } else {
        // Using a clean Gregorian date format (without time)
        dateString = tx.timestamp.toIso8601String().split('T').first;
      }

      rows.add([
        dateString, // Use the formatted date string
        tx.type.toString().split('.').last,
        tx.amount,
        tx.description,
        tx.categoryName ?? 'N/A',
        tx.quantity
      ]);
    }

    // Convert the list of lists to a CSV formatted string
    String csvData = const ListToCsvConverter().convert(rows);

    // --- Step 2: Convert the string data to bytes (Uint8List) ---
    // This is necessary for the mobile save operation.
    final Uint8List fileBytes = utf8.encode(csvData);

    // --- Step 3: Use platform-specific save logic ---
    try {
      final String suggestedFileName =
          '${profileName}_receipts_${DateTime.now().millisecondsSinceEpoch}.csv';

      // The `saveFile` method returns the path where the file was saved on all platforms.
      // The key difference is the `bytes` parameter.
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? 'Please select where to save the file:',
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        // On mobile, we MUST provide the bytes. On desktop, this is optional but
        // providing it allows the picker to handle the writing, simplifying our code.
        // It's robust to provide it on all platforms if available.
        bytes: fileBytes,
      );

      if (outputPath == null) {
        // User canceled the picker
        log("Export cancelled by user.");
        return null;
      }

      // With the 'bytes' parameter provided, the file is already saved by the picker.
      // There is no need for a separate `File.write...` call.
      log("Export successful to: $outputPath");
      return outputPath;
    } catch (e) {
      log("Error during file export: $e");
      return null;
    }
  }

  Future<bool> importFromCsv(int profileId) async {
    // Pick a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return false;

    try {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.length < 2) {
        return false;
      } // Must have header and at least one data row

      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];

        // Basic validation
        if (row.length != 6) continue;

        DateTime timestamp =
            DateTime.tryParse(row[0].toString()) ?? DateTime.now();
        TransactionType type = row[1].toString().toLowerCase() == 'income'
            ? TransactionType.income
            : TransactionType.outgoing;
        double amount = double.tryParse(row[2].toString()) ?? 0.0;
        String description = row[3].toString();
        String categoryName = row[4].toString();
        int quantity = int.tryParse(row[5].toString()) ?? 1;

        if (amount <= 0) continue;

        // Find or create category
        Category? category = await dbService.readCategoryByName(categoryName);
        category ??=
            await dbService.createCategory(Category(name: categoryName));

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
