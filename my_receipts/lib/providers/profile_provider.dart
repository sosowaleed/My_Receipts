import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:my_receipts/models/category.dart';
import 'package:my_receipts/models/profile.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';
import 'package:my_receipts/services/recurrence_service.dart';
import 'package:collection/collection.dart';

class ProfileProvider with ChangeNotifier {
  Profile? _currentProfile;
  List<Profile> _allProfiles = [];
  List<Transaction> _transactions = [];
  List<Category> _incomeCategories = [];
  List<Category> _outgoingCategories = [];
  bool _isLoading = true;
  Locale _appLocale = const Locale('ar');

  Profile? get currentProfile => _currentProfile;
  List<Profile> get allProfiles => _allProfiles;
  List<Transaction> get transactions => _transactions;
  List<Category> get incomeCategories => _incomeCategories;
  List<Category> get outgoingCategories => _outgoingCategories;
  bool get isLoading => _isLoading;
  bool get hasProfiles => _allProfiles.isNotEmpty;
  Locale get appLocale => _appLocale;

  ProfileProvider() {
    _setHijriLocale(_appLocale);
    loadInitialData();
  }

  void setLocale(Locale locale) {
    if (_appLocale == locale) return;
    _appLocale = locale;
    _setHijriLocale(locale);
    notifyListeners();
  }

  void _setHijriLocale(Locale locale) {
    if (locale.languageCode == 'ar') {
      HijriCalendar.setLocal('ar');
    } else {
      HijriCalendar.setLocal('en');
    }
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _allProfiles = await DatabaseService.instance.readAllProfiles();

    if (_allProfiles.isNotEmpty) {
      // Make sure a profile is selected before loading its categories
      final profileToLoad = _currentProfile?.id ?? _allProfiles.first.id!;

      await RecurrenceService().processRecurrentTransactions(profileToLoad);

      await switchProfile(profileToLoad);
    } else {
      // Clear data if no profiles exist
      _currentProfile = null;
      _transactions = [];
      _incomeCategories = [];
      _outgoingCategories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchProfile(int profileId) async {
    _currentProfile = await DatabaseService.instance.readProfile(profileId);
    _transactions = await DatabaseService.instance.readTransactionsForProfile(profileId);

    // Fetch categories specific to this profile and type
    _incomeCategories = await DatabaseService.instance.readAllCategoriesForProfile(profileId, TransactionType.income);
    _outgoingCategories = await DatabaseService.instance.readAllCategoriesForProfile(profileId, TransactionType.outgoing);

    _allProfiles = await DatabaseService.instance.readAllProfiles();
    notifyListeners();
  }


  Future<void> updateProfileName(int profileId, String newName) async {
    await DatabaseService.instance.updateProfileName(profileId, newName);
    await loadInitialData(); // Easiest way to refresh all state
  }

  Future<void> addProfile(Profile profile) async {
    await DatabaseService.instance.createProfile(profile);
    await loadInitialData();
  }

  Future<void> deleteProfile(int profileId) async {
    await DatabaseService.instance.deleteProfile(profileId);
    if(_currentProfile?.id == profileId) {
      _currentProfile = null;
      _transactions = [];
    }
    await loadInitialData();
  }

  Future<void> refreshCurrentProfile() async {
    if (_currentProfile != null) {
      _currentProfile = await DatabaseService.instance.readProfile(_currentProfile!.id!);
      _transactions = await DatabaseService.instance.readTransactionsForProfile(_currentProfile!.id!);
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await DatabaseService.instance.createTransaction(transaction);
    await refreshCurrentProfile();
  }

  Future<void> addBatchTransactions(List<Transaction> transactions) async {
    for (var tx in transactions) {
      await DatabaseService.instance.createTransaction(tx);
    }
    await refreshCurrentProfile();
  }

  Future<void> updateTransaction(Transaction newTx, Transaction oldTx) async {
    await DatabaseService.instance.updateTransaction(newTx, oldTx);
    await refreshCurrentProfile();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await DatabaseService.instance.deleteTransaction(transaction);
    await refreshCurrentProfile();
  }

  Future<Category> addCategory(String name, TransactionType type) async {
    final category = await DatabaseService.instance.createCategory(
      Category(name: name),
      _currentProfile!.id!,
      type,
    );
    // Refresh the correct category list
    if (type == TransactionType.income) {
      _incomeCategories = await DatabaseService.instance.readAllCategoriesForProfile(_currentProfile!.id!, type);
    } else {
      _outgoingCategories = await DatabaseService.instance.readAllCategoriesForProfile(_currentProfile!.id!, type);
    }
    notifyListeners();
    return category;
  }

  Future<void> deleteMonthTransactions(int year, int month) async {
    if (_currentProfile == null) return;
    await DatabaseService.instance.deleteTransactionsForMonth(_currentProfile!.id!, year, month);
    await refreshCurrentProfile(); // Use existing method to refresh state
  }

  Future<void> deleteYearTransactions(int year) async {
    if (_currentProfile == null) return;
    await DatabaseService.instance.deleteTransactionsForYear(_currentProfile!.id!, year);
    await refreshCurrentProfile();
  }

  Future<void> deleteHijriMonthTransactions(int hYear, int hMonth) async {
    if (_currentProfile == null) return;
    await DatabaseService.instance.deleteTransactionsForHijriMonth(_currentProfile!.id!, hYear, hMonth);
    await refreshCurrentProfile();
  }

  Future<void> deleteHijriYearTransactions(int hYear) async {
    if (_currentProfile == null) return;
    await DatabaseService.instance.deleteTransactionsForHijriYear(_currentProfile!.id!, hYear);
    await refreshCurrentProfile();
  }

  /// Calculates summary data for transactions within a date range.
  Map<String, double> getSummaryForPeriod(DateTime start, DateTime end) {
    double income = 0;
    double expenses = 0;
    final relevantTxs = _transactions.where((tx) =>
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

  /// Groups expenses by category for the pie chart.
  Map<String, double> getExpenseByCategory(DateTime start, DateTime end) {
    final relevantTxs = _transactions.where((tx) =>
    tx.type == TransactionType.outgoing &&
        !tx.timestamp.isBefore(start) && tx.timestamp.isBefore(end));

    final grouped = groupBy(relevantTxs, (Transaction tx) => tx.categoryName ?? 'Uncategorized');

    return grouped.map((key, value) => MapEntry(key, value.fold(0.0, (sum, tx) => sum + tx.amount)));
  }

  /// Gets monthly income/expense totals for the bar chart.
  /// Returns a map where key is month (YYYY-MM) and value is another map {'income': X, 'expenses': Y}
  Map<String, Map<String, double>> getMonthlyTotals(int monthsToGoBack) {
    final now = DateTime.now();
    final data = <String, Map<String, double>>{};

    for (int i = monthsToGoBack - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = {'income': 0.0, 'expenses': 0.0};
    }

    final cutoffDate = DateTime(now.year, now.month - (monthsToGoBack - 1), 1);
    final relevantTxs = _transactions.where((tx) => !tx.timestamp.isBefore(cutoffDate));

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