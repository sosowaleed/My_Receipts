import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:my_receipts/models/category.dart';
import 'package:my_receipts/models/profile.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/services/database_service.dart';

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
}