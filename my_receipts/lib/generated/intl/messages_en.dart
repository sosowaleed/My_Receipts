// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(categoryName) => "Category \'${categoryName}\' added!";

  static String m1(profileName) =>
      "Are you sure you want to delete profile \'${profileName}\'? All its data will be lost forever.";

  static String m2(simName) =>
      "Are you sure you want to delete the simulation \'${simName}\'?";

  static String m3(path) => "Data exported successfully to ${path}";

  static String m4(dataType) => "No ${dataType} data for this period.";

  static String m5(original, simulation) => "${original} vs. ${simulation}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addAnother": MessageLookupByLibrary.simpleMessage("Add Another Receipt"),
    "addNewCategory": MessageLookupByLibrary.simpleMessage(
      "Add New Category...",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add Profile"),
    "addSimulatedExpense": MessageLookupByLibrary.simpleMessage(
      "Add Simulated Expense",
    ),
    "addSimulatedIncome": MessageLookupByLibrary.simpleMessage(
      "Add Simulated Income",
    ),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "appName": MessageLookupByLibrary.simpleMessage("My Receipts"),
    "calendarPreference": MessageLookupByLibrary.simpleMessage(
      "Calendar Preference",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "category": MessageLookupByLibrary.simpleMessage("Category"),
    "categoryAdded": m0,
    "categoryName": MessageLookupByLibrary.simpleMessage("Category Name"),
    "comparisonDashboard": MessageLookupByLibrary.simpleMessage(
      "Comparison Dashboard",
    ),
    "confirmDeleteProfile": m1,
    "confirmDeleteSimulatedTransaction": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this simulated transaction?",
    ),
    "confirmDeleteSimulation": m2,
    "confirmDeleteTransaction": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this transaction?",
    ),
    "daily": MessageLookupByLibrary.simpleMessage("Daily"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteProfile": MessageLookupByLibrary.simpleMessage("Delete Profile"),
    "deleteSimulatedTransaction": MessageLookupByLibrary.simpleMessage(
      "Delete Simulated Transaction",
    ),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "earningsBreakdown": MessageLookupByLibrary.simpleMessage(
      "Earnings Breakdown (Last 30 Days)",
    ),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editSimulatedTransaction": MessageLookupByLibrary.simpleMessage(
      "Edit Simulated Transaction",
    ),
    "editTransaction": MessageLookupByLibrary.simpleMessage("Edit Transaction"),
    "endDateOptional": MessageLookupByLibrary.simpleMessage(
      "End Date (Optional)",
    ),
    "enterCategoryName": MessageLookupByLibrary.simpleMessage(
      "Enter Category Name",
    ),
    "enterSimulationName": MessageLookupByLibrary.simpleMessage(
      "Enter Simulation Name",
    ),
    "errorFieldRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required.",
    ),
    "errorInvalidNumber": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid number.",
    ),
    "expenseBreakdown": MessageLookupByLibrary.simpleMessage(
      "Expense Breakdown (Last 30 Days)",
    ),
    "expenses": MessageLookupByLibrary.simpleMessage("Expenses"),
    "exportAction": MessageLookupByLibrary.simpleMessage("Export to CSV"),
    "exportSuccess": m3,
    "financialDashboard": MessageLookupByLibrary.simpleMessage(
      "Financial Dashboard",
    ),
    "financialProjection": MessageLookupByLibrary.simpleMessage(
      "Financial Projection",
    ),
    "frequency": MessageLookupByLibrary.simpleMessage("Frequency"),
    "gregorian": MessageLookupByLibrary.simpleMessage("Gregorian"),
    "hijri": MessageLookupByLibrary.simpleMessage("Hijri"),
    "homeImportExport": MessageLookupByLibrary.simpleMessage("Import/Export"),
    "homeIncoming": MessageLookupByLibrary.simpleMessage("Incoming"),
    "homeOutgoing": MessageLookupByLibrary.simpleMessage("Outgoing"),
    "homeReview": MessageLookupByLibrary.simpleMessage("Review History"),
    "importAction": MessageLookupByLibrary.simpleMessage("Import from CSV"),
    "importError": MessageLookupByLibrary.simpleMessage(
      "Import failed. Please check the file format for compatibility.",
    ),
    "importExportTitle": MessageLookupByLibrary.simpleMessage(
      "Import / Export Data",
    ),
    "importFailedCheckFormat": MessageLookupByLibrary.simpleMessage(
      "Import Failed. Check file format and content.",
    ),
    "importSuccess": MessageLookupByLibrary.simpleMessage(
      "Data imported successfully!",
    ),
    "income": MessageLookupByLibrary.simpleMessage("Income"),
    "incomeOverlayTitle": MessageLookupByLibrary.simpleMessage("New Income"),
    "initialWallet": MessageLookupByLibrary.simpleMessage(
      "Initial Wallet Amount",
    ),
    "last30DaysSummary": MessageLookupByLibrary.simpleMessage(
      "Last 30 Days Summary",
    ),
    "loadSimulation": MessageLookupByLibrary.simpleMessage("Load Simulation"),
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "monthlyOverview": MessageLookupByLibrary.simpleMessage(
      "Monthly Overview (Last 6 Months)",
    ),
    "months": MessageLookupByLibrary.simpleMessage("months"),
    "netSavings": MessageLookupByLibrary.simpleMessage("Net Savings"),
    "newFromBlank": MessageLookupByLibrary.simpleMessage(
      "Start with a Blank Slate",
    ),
    "newFromHistory": MessageLookupByLibrary.simpleMessage(
      "Copy Current History",
    ),
    "newSimulation": MessageLookupByLibrary.simpleMessage("New Simulation"),
    "noDataForPeriod": m4,
    "noEndDate": MessageLookupByLibrary.simpleMessage("No End Date"),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "once": MessageLookupByLibrary.simpleMessage("Once"),
    "original": MessageLookupByLibrary.simpleMessage("Original"),
    "originalVsSimulation": m5,
    "outgoingOverlayTitle": MessageLookupByLibrary.simpleMessage(
      "New Outgoing",
    ),
    "profileName": MessageLookupByLibrary.simpleMessage("Profile Name"),
    "profiles": MessageLookupByLibrary.simpleMessage("Profiles"),
    "promptScreenTitle": MessageLookupByLibrary.simpleMessage(
      "Create Your Profile",
    ),
    "quantity": MessageLookupByLibrary.simpleMessage("Quantity"),
    "receiptReviewTitle": MessageLookupByLibrary.simpleMessage(
      "Receipt History",
    ),
    "recurrent": MessageLookupByLibrary.simpleMessage("Recurrent"),
    "recurrentTransaction": MessageLookupByLibrary.simpleMessage(
      "Recurrent Transaction",
    ),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveSimulation": MessageLookupByLibrary.simpleMessage("Save Simulation"),
    "selectExportLocation": MessageLookupByLibrary.simpleMessage(
      "Select Export Location",
    ),
    "selectImportFile": MessageLookupByLibrary.simpleMessage(
      "Select Import File",
    ),
    "simulate": MessageLookupByLibrary.simpleMessage("Simulate"),
    "simulation": MessageLookupByLibrary.simpleMessage("Simulation"),
    "simulationWorkspace": MessageLookupByLibrary.simpleMessage(
      "Simulation Workspace",
    ),
    "simulations": MessageLookupByLibrary.simpleMessage("Simulations"),
    "switchCalendar": MessageLookupByLibrary.simpleMessage("Switch Calendar"),
    "transactionDeleted": MessageLookupByLibrary.simpleMessage(
      "Transaction deleted!",
    ),
    "transactionSaved": MessageLookupByLibrary.simpleMessage(
      "Transaction saved!",
    ),
    "transactionUpdated": MessageLookupByLibrary.simpleMessage(
      "Transaction updated!",
    ),
    "uncategorized": MessageLookupByLibrary.simpleMessage("Uncategorized"),
    "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
  };
}
