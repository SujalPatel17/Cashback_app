import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Create the table
  Future _createDB(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        amount REAL,
        date TEXT,
        cashback REAL,
        cashbackChecked INTEGER
      )
    ''');

    // Optional: Add indexes for optimized querying
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cashbackChecked ON transactions (cashbackChecked)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_date ON transactions (date)',
    );
  }

  // Insert transaction into the database
  Future<int> insertTransaction(TransactionModel txn) async {
    try {
      final db = await database;
      return await db.insert('transactions', txn.toMap());
    } catch (e) {
      print('Error inserting transaction: $e');
      rethrow;
    }
  }

  // Get all transactions from the database
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final db = await database;
      final result = await db.query('transactions', orderBy: "date DESC");
      return result.map((e) => TransactionModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  // Get pending cashback checks (transactions not marked as checked and older than 90 days)
  Future<List<TransactionModel>> getPendingCashbackChecks() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(Duration(days: 90));

      // Query for transactions where cashbackChecked = 0 and date is older than 90 days
      final result = await db.query(
        'transactions',
        where: "cashbackChecked = 0 AND date <= ?",
        whereArgs: [ninetyDaysAgo.toIso8601String()],
      );

      return result.map((e) => TransactionModel.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching pending cashback checks: $e');
      return [];
    }
  }

  // Mark a transaction as cashback checked
  Future<void> markCashbackChecked(int id) async {
    try {
      final db = await database;
      await db.update(
        'transactions',
        {'cashbackChecked': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marking cashback as checked: $e');
    }
  }

  // Clear all transactions (for debugging or testing)
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('transactions');
    } catch (e) {
      print('Error clearing all transactions: $e');
    }
  }

  Future<List<TransactionModel>> getFilteredTransactions({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    final db = await database;
    await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<double> getMonthlyCashback(DateTime date) async {
    final db = await database;
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

    final result = await db.rawQuery(
      '''
    SELECT SUM(cashback) as total 
    FROM transactions 
    WHERE date >= ? AND date <= ?
    ''',
      [firstDayOfMonth.toIso8601String(), lastDayOfMonth.toIso8601String()],
    );

    return result.first['total'] != null
        ? (result.first['total'] as num).toDouble()
        : 0.0;
  }
}
