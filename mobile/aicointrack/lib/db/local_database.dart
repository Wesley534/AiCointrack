import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for offline-first caching and sync queue.
///
/// Tables:
///   - transactions: cached/offline-created transactions
///   - budgets: cached budget categories
///   - shopping_lists: cached shopping lists
///   - shopping_items: items belonging to shopping lists
///   - savings_goals: cached savings goals
///   - dashboard_cache: key-value store for dashboard JSON blobs
///   - sync_queue: pending creates/updates to push to backend
class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cointrack_cache.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            description TEXT NOT NULL,
            emoji TEXT NOT NULL DEFAULT '💸',
            amount TEXT NOT NULL,
            amount_raw REAL NOT NULL DEFAULT 0,
            date TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT 'manual',
            category TEXT,
            transaction_type TEXT NOT NULL DEFAULT 'expense',
            synced INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            label TEXT NOT NULL,
            planned REAL NOT NULL DEFAULT 0,
            actual REAL NOT NULL DEFAULT 0,
            tag TEXT NOT NULL DEFAULT 'need',
            kind TEXT NOT NULL DEFAULT 'need',
            month TEXT,
            synced INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE shopping_lists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            name TEXT NOT NULL,
            budget REAL NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE shopping_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            list_id INTEGER NOT NULL,
            list_server_id INTEGER,
            name TEXT NOT NULL,
            qty INTEGER NOT NULL DEFAULT 1,
            price REAL NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE savings_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            name TEXT NOT NULL,
            saved REAL NOT NULL DEFAULT 0,
            target REAL NOT NULL DEFAULT 0,
            monthly REAL NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE dashboard_cache (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_local_id INTEGER NOT NULL,
            action TEXT NOT NULL DEFAULT 'create',
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT (datetime('now'))
          )
        ''');
      },
    );
  }

  /// Close the database (for testing or cleanup).
  static Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
