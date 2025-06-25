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
  List<Category> _categories = [];
  bool _isLoading = true;
  Locale _appLocale = const Locale('en');

  Profile? get currentProfile => _currentProfile;
  List<Profile> get allProfiles => _allProfiles;
  List<Transaction> get transactions => _transactions;
  List<Category> get categories => _categories;
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
    _categories = await DatabaseService.instance.readAllCategories();

    if (_allProfiles.isNotEmpty) {
      await switchProfile(_currentProfile?.id ?? _allProfiles.first.id!);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchProfile(int profileId) async {
    _currentProfile = await DatabaseService.instance.readProfile(profileId);
    _transactions = await DatabaseService.instance.readTransactionsForProfile(profileId);
    _allProfiles = await DatabaseService.instance.readAllProfiles(); // Refresh all profiles list too
    notifyListeners();
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

  Future<Category> addCategory(String name) async {
    final category = await DatabaseService.instance.createCategory(Category(name: name));
    _categories = await DatabaseService.instance.readAllCategories();
    notifyListeners();
    return category;
  }
}