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

  static String m2(path) => "Data exported successfully to ${path}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addAnother": MessageLookupByLibrary.simpleMessage("Add Another Receipt"),
    "addNewCategory": MessageLookupByLibrary.simpleMessage(
      "Add New Category...",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add Profile"),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "appName": MessageLookupByLibrary.simpleMessage("My Receipts"),
    "calendarPreference": MessageLookupByLibrary.simpleMessage(
      "Calendar Preference",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "category": MessageLookupByLibrary.simpleMessage("Category"),
    "categoryAdded": m0,
    "categoryName": MessageLookupByLibrary.simpleMessage("Category Name"),
    "confirmDeleteProfile": m1,
    "confirmDeleteTransaction": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this transaction?",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteProfile": MessageLookupByLibrary.simpleMessage("Delete Profile"),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editTransaction": MessageLookupByLibrary.simpleMessage("Edit Transaction"),
    "enterCategoryName": MessageLookupByLibrary.simpleMessage(
      "Enter Category Name",
    ),
    "errorFieldRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required.",
    ),
    "errorInvalidNumber": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid number.",
    ),
    "exportAction": MessageLookupByLibrary.simpleMessage("Export to CSV"),
    "exportSuccess": m2,
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
    "incomeOverlayTitle": MessageLookupByLibrary.simpleMessage("New Income"),
    "initialWallet": MessageLookupByLibrary.simpleMessage(
      "Initial Wallet Amount",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
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
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "selectExportLocation": MessageLookupByLibrary.simpleMessage(
      "Select Export Location",
    ),
    "selectImportFile": MessageLookupByLibrary.simpleMessage(
      "Select Import File",
    ),
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
  };
}
