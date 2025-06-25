import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:my_receipts/models/profile.dart';
import 'package:my_receipts/models/transaction.dart';
import 'package:my_receipts/models/category.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static sql.Database? _database;

  DatabaseService._init();

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('receipts_v2.db');
    return _database!;
  }

  Future<sql.Database> _initDB(String filePath) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, filePath);
    return await sql.openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(sql.Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE profiles (
        id $idType,
        name $textType,
        walletAmount $realType,
        calendarPreference $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        profileId $integerType,
        type $textType,
        amount $realType,
        description $textType,
        categoryId $integerType,
        quantity $integerType,
        timestamp $textType,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Create a default "General" category
    await db.insert('categories', {'name': 'General'});
  }

  // This handles schema changes between versions.
  // NOTE: In a real production app, this would be a non-destructive migration.
  // For this project, we drop and recreate for simplicity.
  Future _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Simple migration: Recreate everything.
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS profiles');
      await _createDB(db, newVersion);
    }
  }


  // Profile Methods
  Future<Profile> createProfile(Profile profile) async {
    final db = await instance.database;
    final id = await db.insert('profiles', profile.toMap());
    return Profile(id: id, name: profile.name, walletAmount: profile.walletAmount, calendarPreference: profile.calendarPreference);
  }

  Future<List<Profile>> readAllProfiles() async {
    final db = await instance.database;
    final result = await db.query('profiles', orderBy: 'name ASC');
    return result.map((json) => Profile.fromMap(json)).toList();
  }

  Future<int> updateProfile(Profile profile) async {
    final db = await instance.database;
    return db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<int> deleteProfile(int id) async {
    final db = await instance.database;
    // The ON DELETE CASCADE will handle deleting associated transactions
    return db.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  Future<Profile> readProfile(int id) async {
    final db = await instance.database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Profile.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  // Category Methods
  Future<Category> createCategory(Category category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap(), conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return Category(id: id, name: category.name);
  }

  Future<Category?> readCategoryByName(String name) async {
    final db = await instance.database;
    final maps = await db.query('categories', where: 'name = ?', whereArgs: [name], limit: 1);
    if(maps.isNotEmpty) return Category.fromMap(maps.first);
    return null;
  }

  Future<List<Category>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  // Transaction Methods
  Future<Transaction> createTransaction(Transaction transaction) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final profile = (await txn.query('profiles', where: 'id = ?', whereArgs: [transaction.profileId])).first;
      double currentWallet = profile['walletAmount'] as double;
      double newWallet = transaction.type == TransactionType.income
          ? currentWallet + transaction.amount
          : currentWallet - transaction.amount;
      await txn.update('profiles', {'walletAmount': newWallet}, where: 'id = ?', whereArgs: [transaction.profileId]);

      final id = await txn.insert('transactions', transaction.toMap());
      return transaction;
    });
  }

  Future<void> updateTransaction(Transaction newTx, Transaction oldTx) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final profile = (await txn.query('profiles', where: 'id = ?', whereArgs: [newTx.profileId])).first;
      double currentWallet = profile['walletAmount'] as double;

      // 1. Reverse the old transaction's effect
      double walletAfterReversal = oldTx.type == TransactionType.income
          ? currentWallet - oldTx.amount
          : currentWallet + oldTx.amount;

      // 2. Apply the new transaction's effect
      double finalWallet = newTx.type == TransactionType.income
          ? walletAfterReversal + newTx.amount
          : walletAfterReversal - newTx.amount;

      await txn.update('profiles', {'walletAmount': finalWallet}, where: 'id = ?', whereArgs: [newTx.profileId]);
      await txn.update('transactions', newTx.toMap(), where: 'id = ?', whereArgs: [newTx.id]);
    });
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final profile = (await txn.query('profiles', where: 'id = ?', whereArgs: [transaction.profileId])).first;
      double currentWallet = profile['walletAmount'] as double;

      double newWallet = transaction.type == TransactionType.income
          ? currentWallet - transaction.amount
          : currentWallet + transaction.amount;

      await txn.update('profiles', {'walletAmount': newWallet}, where: 'id = ?', whereArgs: [transaction.profileId]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transaction.id]);
    });
  }


  Future<List<Transaction>> readTransactionsForProfile(int profileId) async {
    final db = await instance.database;
    // Use a LEFT JOIN to get the category name along with the transaction
    final result = await db.rawQuery('''
      SELECT t.*, c.name as categoryName 
      FROM transactions t
      LEFT JOIN categories c ON t.categoryId = c.id
      WHERE t.profileId = ? 
      ORDER BY t.timestamp DESC
    ''', [profileId]);

    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}