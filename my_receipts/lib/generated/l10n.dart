// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `My Receipts`
  String get appName {
    return Intl.message('My Receipts', name: 'appName', desc: '', args: []);
  }

  /// `Create Your Profile`
  String get promptScreenTitle {
    return Intl.message(
      'Create Your Profile',
      name: 'promptScreenTitle',
      desc: '',
      args: [],
    );
  }

  /// `Profile Name`
  String get profileName {
    return Intl.message(
      'Profile Name',
      name: 'profileName',
      desc: '',
      args: [],
    );
  }

  /// `Initial Wallet Amount`
  String get initialWallet {
    return Intl.message(
      'Initial Wallet Amount',
      name: 'initialWallet',
      desc: '',
      args: [],
    );
  }

  /// `Calendar Preference`
  String get calendarPreference {
    return Intl.message(
      'Calendar Preference',
      name: 'calendarPreference',
      desc: '',
      args: [],
    );
  }

  /// `Gregorian`
  String get gregorian {
    return Intl.message('Gregorian', name: 'gregorian', desc: '', args: []);
  }

  /// `Hijri`
  String get hijri {
    return Intl.message('Hijri', name: 'hijri', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Incoming`
  String get homeIncoming {
    return Intl.message('Incoming', name: 'homeIncoming', desc: '', args: []);
  }

  /// `Outgoing`
  String get homeOutgoing {
    return Intl.message('Outgoing', name: 'homeOutgoing', desc: '', args: []);
  }

  /// `Review History`
  String get homeReview {
    return Intl.message(
      'Review History',
      name: 'homeReview',
      desc: '',
      args: [],
    );
  }

  /// `Import/Export`
  String get homeImportExport {
    return Intl.message(
      'Import/Export',
      name: 'homeImportExport',
      desc: '',
      args: [],
    );
  }

  /// `Profiles`
  String get profiles {
    return Intl.message('Profiles', name: 'profiles', desc: '', args: []);
  }

  /// `Add Profile`
  String get addProfile {
    return Intl.message('Add Profile', name: 'addProfile', desc: '', args: []);
  }

  /// `Delete Profile`
  String get deleteProfile {
    return Intl.message(
      'Delete Profile',
      name: 'deleteProfile',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete profile '{profileName}'? All its data will be lost forever.`
  String confirmDeleteProfile(Object profileName) {
    return Intl.message(
      'Are you sure you want to delete profile \'$profileName\'? All its data will be lost forever.',
      name: 'confirmDeleteProfile',
      desc: '',
      args: [profileName],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message('OK', name: 'ok', desc: '', args: []);
  }

  /// `Amount`
  String get amount {
    return Intl.message('Amount', name: 'amount', desc: '', args: []);
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Category`
  String get category {
    return Intl.message('Category', name: 'category', desc: '', args: []);
  }

  /// `Quantity`
  String get quantity {
    return Intl.message('Quantity', name: 'quantity', desc: '', args: []);
  }

  /// `New Income`
  String get incomeOverlayTitle {
    return Intl.message(
      'New Income',
      name: 'incomeOverlayTitle',
      desc: '',
      args: [],
    );
  }

  /// `New Outgoing`
  String get outgoingOverlayTitle {
    return Intl.message(
      'New Outgoing',
      name: 'outgoingOverlayTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add Another Receipt`
  String get addAnother {
    return Intl.message(
      'Add Another Receipt',
      name: 'addAnother',
      desc: '',
      args: [],
    );
  }

  /// `Import / Export Data`
  String get importExportTitle {
    return Intl.message(
      'Import / Export Data',
      name: 'importExportTitle',
      desc: '',
      args: [],
    );
  }

  /// `Import from CSV`
  String get importAction {
    return Intl.message(
      'Import from CSV',
      name: 'importAction',
      desc: '',
      args: [],
    );
  }

  /// `Export to CSV`
  String get exportAction {
    return Intl.message(
      'Export to CSV',
      name: 'exportAction',
      desc: '',
      args: [],
    );
  }

  /// `Data exported successfully to {path}`
  String exportSuccess(Object path) {
    return Intl.message(
      'Data exported successfully to $path',
      name: 'exportSuccess',
      desc: '',
      args: [path],
    );
  }

  /// `Data imported successfully!`
  String get importSuccess {
    return Intl.message(
      'Data imported successfully!',
      name: 'importSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Import failed. Please check the file format for compatibility.`
  String get importError {
    return Intl.message(
      'Import failed. Please check the file format for compatibility.',
      name: 'importError',
      desc: '',
      args: [],
    );
  }

  /// `Receipt History`
  String get receiptReviewTitle {
    return Intl.message(
      'Receipt History',
      name: 'receiptReviewTitle',
      desc: '',
      args: [],
    );
  }

  /// `Switch Calendar`
  String get switchCalendar {
    return Intl.message(
      'Switch Calendar',
      name: 'switchCalendar',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid number.`
  String get errorInvalidNumber {
    return Intl.message(
      'Please enter a valid number.',
      name: 'errorInvalidNumber',
      desc: '',
      args: [],
    );
  }

  /// `This field is required.`
  String get errorFieldRequired {
    return Intl.message(
      'This field is required.',
      name: 'errorFieldRequired',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Edit Transaction`
  String get editTransaction {
    return Intl.message(
      'Edit Transaction',
      name: 'editTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this transaction?`
  String get confirmDeleteTransaction {
    return Intl.message(
      'Are you sure you want to delete this transaction?',
      name: 'confirmDeleteTransaction',
      desc: '',
      args: [],
    );
  }

  /// `Add New Category...`
  String get addNewCategory {
    return Intl.message(
      'Add New Category...',
      name: 'addNewCategory',
      desc: '',
      args: [],
    );
  }

  /// `Enter Category Name`
  String get enterCategoryName {
    return Intl.message(
      'Enter Category Name',
      name: 'enterCategoryName',
      desc: '',
      args: [],
    );
  }

  /// `Category Name`
  String get categoryName {
    return Intl.message(
      'Category Name',
      name: 'categoryName',
      desc: '',
      args: [],
    );
  }

  /// `Transaction saved!`
  String get transactionSaved {
    return Intl.message(
      'Transaction saved!',
      name: 'transactionSaved',
      desc: '',
      args: [],
    );
  }

  /// `Transaction updated!`
  String get transactionUpdated {
    return Intl.message(
      'Transaction updated!',
      name: 'transactionUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Transaction deleted!`
  String get transactionDeleted {
    return Intl.message(
      'Transaction deleted!',
      name: 'transactionDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Category '{categoryName}' added!`
  String categoryAdded(Object categoryName) {
    return Intl.message(
      'Category \'$categoryName\' added!',
      name: 'categoryAdded',
      desc: '',
      args: [categoryName],
    );
  }

  /// `Import Failed. Check file format and content.`
  String get importFailedCheckFormat {
    return Intl.message(
      'Import Failed. Check file format and content.',
      name: 'importFailedCheckFormat',
      desc: '',
      args: [],
    );
  }

  /// `Select Import File`
  String get selectImportFile {
    return Intl.message(
      'Select Import File',
      name: 'selectImportFile',
      desc: '',
      args: [],
    );
  }

  /// `Select Export Location`
  String get selectExportLocation {
    return Intl.message(
      'Select Export Location',
      name: 'selectExportLocation',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
