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
    _database = await _initDB('receipts_v3.db');
    return _database!;
  }

  Future<sql.Database> _initDB(String filePath) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, filePath);
    return await sql.openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profileId INTEGER NOT NULL,
        type TEXT NOT NULL, -- 'income' or 'outgoing'
        name TEXT NOT NULL,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE,
        UNIQUE (profileId, type, name)
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

  }

  // This handles schema changes between versions.
  Future _onUpgrade(sql.Database db, int oldVersion, int newVersion) async {
    // This logic handles upgrades from both v1 and v2 to v3
    if (oldVersion < 3) {
      // For simplicity in this project, we drop and recreate.
      // In a production app with user data, a more careful migration
      // (creating a new table, moving data, dropping old table) would be needed.
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS categories');
      // Re-create the tables with the new schema
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profileId INTEGER NOT NULL,
          type TEXT NOT NULL, -- 'income' or 'outgoing'
          name TEXT NOT NULL,
          FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE,
          UNIQUE (profileId, type, name)
        )
      ''');
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profileId INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          categoryId INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE,
          FOREIGN KEY (categoryId) REFERENCES categories (id)
        )
      ''');
    }
  }


  // When creating a new profile, also create its default categories
  Future<Profile> createProfile(Profile profile) async {
    final db = await instance.database;
    final id = await db.insert('profiles', profile.toMap());

    // Create default "General" categories for both types for the new profile
    await createCategory(Category(name: 'General'), id, TransactionType.income);
    await createCategory(Category(name: 'General'), id, TransactionType.outgoing);

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

  Future<int> updateProfileName(int profileId, String newName) async {
    final db = await instance.database;
    return await db.update('profiles', {'name': newName}, where: 'id = ?', whereArgs: [profileId]);
  }

  // Category Methods
  // --- Category Methods (Updated to be profile and type specific) ---
  Future<Category> createCategory(Category category, int profileId, TransactionType type) async {
    final db = await instance.database;
    final map = category.toMap();
    map['profileId'] = profileId;
    map['type'] = type.toString().split('.').last;

    final id = await db.insert('categories', map, conflictAlgorithm: sql.ConflictAlgorithm.ignore);
    // If insert was ignored due to UNIQUE constraint, read the existing one
    if (id == 0) {
      final existing = await readCategoryByName(category.name, profileId, type);
      return existing!;
    }
    return Category(id: id, name: category.name);
  }


  Future<Category?> readCategoryByName(String name, int profileId, TransactionType type) async {
    final db = await instance.database;
    final typeString = type.toString().split('.').last;
    final maps = await db.query(
      'categories',
      where: 'name = ? AND profileId = ? AND type = ?',
      whereArgs: [name, profileId, typeString],
      limit: 1,
    );
    if (maps.isNotEmpty) return Category.fromMap(maps.first);
    return null;
  }

  Future<List<Category>> readAllCategoriesForProfile(int profileId, TransactionType type) async {
    final db = await instance.database;
    final typeString = type.toString().split('.').last;
    final result = await db.query(
      'categories',
      where: 'profileId = ? AND type = ?',
      whereArgs: [profileId, typeString],
      orderBy: 'name ASC',
    );
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