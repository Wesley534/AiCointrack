import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  LocalDbService._();

  static final LocalDbService instance = LocalDbService._();

  static const _dbName = 'cointrack_local.db';
  static const _transactionsTable = 'transactions';
  static const _cacheTable = 'cache_entries';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_transactionsTable (
            local_id TEXT PRIMARY KEY,
            server_id TEXT NULL,
            amount REAL NOT NULL,
            transaction_type TEXT NOT NULL,
            description TEXT,
            category TEXT,
            source TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            deleted INTEGER DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_transactions_server_id ON $_transactionsTable(server_id)',
        );
        await db.execute('''
          CREATE TABLE $_cacheTable (
            cache_key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_synced_at TEXT
          )
        ''');
      },
    );
  }

  Future<Database> get _database async {
    await init();
    return _db!;
  }

  Future<void> upsertCache(String key, Object payload) async {
    final db = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(_cacheTable, {
      'cache_key': key,
      'payload': jsonEncode(payload),
      'updated_at': now,
      'last_synced_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCachedList(String key) async {
    final row = await _getCacheRow(key);
    if (row == null) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(row['payload'] as String);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getCachedMap(String key) async {
    final row = await _getCacheRow(key);
    if (row == null) return <String, dynamic>{};
    final decoded = jsonDecode(row['payload'] as String);
    if (decoded is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }

  Future<DateTime?> getLastSyncedAt(String key) async {
    final row = await _getCacheRow(key);
    final raw = row?['last_synced_at'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<bool> isCacheStale(
    String key, {
    Duration maxAge = const Duration(hours: 12),
  }) async {
    final ts = await getLastSyncedAt(key);
    if (ts == null) return true;
    return DateTime.now().toUtc().difference(ts.toUtc()) > maxAge;
  }

  Future<Map<String, Object?>?> _getCacheRow(String key) async {
    final db = await _database;
    final rows = await db.query(
      _cacheTable,
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>> insertPendingTransaction({
    required String localId,
    required double amount,
    required String transactionType,
    required String description,
    required String category,
    required String source,
    String syncStatus = 'pending',
  }) async {
    final db = await _database;
    final now = DateTime.now().toUtc().toIso8601String();
    final row = <String, Object?>{
      'local_id': localId,
      'server_id': null,
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'category': category,
      'source': source,
      'created_at': now,
      'updated_at': now,
      'sync_status': syncStatus,
      'deleted': 0,
    };
    await db.insert(
      _transactionsTable,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return _mapTransactionRow(row);
  }

  Future<void> upsertServerTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    final db = await _database;
    final batch = db.batch();

    for (final item in transactions) {
      final serverId = (item['id'] ?? item['server_id'])?.toString();
      final existing = serverId == null
          ? <Map<String, Object?>>[]
          : await db.query(
              _transactionsTable,
              where: 'server_id = ?',
              whereArgs: [serverId],
              limit: 1,
            );

      final localId = existing.isNotEmpty
          ? (existing.first['local_id'] as String)
          : 'server_$serverId';
      final createdAt =
          (item['created_at'] ??
                  item['createdAt'] ??
                  DateTime.now().toUtc().toIso8601String())
              .toString();
      final updatedAt = (item['updated_at'] ?? item['updatedAt'] ?? createdAt)
          .toString();

      batch.insert(_transactionsTable, {
        'local_id': localId,
        'server_id': serverId,
        'amount': _asDouble(item['amount']),
        'transaction_type': (item['transaction_type'] ?? 'expense').toString(),
        'description': (item['description'] ?? '').toString(),
        'category': (item['category'] ?? 'General').toString(),
        'source': (item['source'] ?? 'cash').toString(),
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_status': 'synced',
        'deleted': item['deleted'] == 1 ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> markTransactionSynced(
    String localId, {
    required String serverId,
    required Map<String, dynamic> serverPayload,
  }) async {
    final db = await _database;
    await db.update(
      _transactionsTable,
      {
        'server_id': serverId,
        'sync_status': 'synced',
        'amount': _asDouble(serverPayload['amount']),
        'transaction_type': (serverPayload['transaction_type'] ?? 'expense')
            .toString(),
        'description': (serverPayload['description'] ?? '').toString(),
        'category': (serverPayload['category'] ?? 'General').toString(),
        'source': (serverPayload['source'] ?? 'cash').toString(),
        'created_at':
            (serverPayload['created_at'] ??
                    DateTime.now().toUtc().toIso8601String())
                .toString(),
        'updated_at':
            (serverPayload['updated_at'] ??
                    DateTime.now().toUtc().toIso8601String())
                .toString(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markTransactionSyncStatus(String localId, String status) async {
    final db = await _database;
    await db.update(
      _transactionsTable,
      {
        'sync_status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int syncedLimit = 50,
    bool includeAllUnsynced = true,
    String? source,
    String? transactionType,
  }) async {
    final db = await _database;

    final filters = <String>['deleted = 0'];
    final args = <Object?>[];
    if (source != null && source.isNotEmpty) {
      filters.add('source = ?');
      args.add(source);
    }
    if (transactionType != null && transactionType.isNotEmpty) {
      filters.add('transaction_type = ?');
      args.add(transactionType);
    }

    final where = filters.join(' AND ');
    final syncedRows = await db.query(
      _transactionsTable,
      where: '$where AND sync_status = ?',
      whereArgs: [...args, 'synced'],
      orderBy: 'datetime(created_at) DESC',
      limit: syncedLimit,
    );

    final unsyncedRows = includeAllUnsynced
        ? await db.query(
            _transactionsTable,
            where: '$where AND sync_status != ?',
            whereArgs: [...args, 'synced'],
            orderBy: 'datetime(created_at) DESC',
          )
        : <Map<String, Object?>>[];

    final merged = <Map<String, dynamic>>[
      ...syncedRows.map(_mapTransactionRow),
      ...unsyncedRows.map(_mapTransactionRow),
    ];
    merged.sort((a, b) {
      final aDate =
          DateTime.tryParse((a['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse((b['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final deduped = <String, Map<String, dynamic>>{};
    for (final row in merged) {
      deduped[row['local_id'].toString()] = row;
    }
    return deduped.values.toList();
  }

  Future<List<Map<String, dynamic>>> getPendingTransactionsForSync() async {
    final db = await _database;
    final rows = await db.query(
      _transactionsTable,
      where: 'deleted = 0 AND sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'datetime(created_at) ASC',
    );
    return rows.map(_mapTransactionRow).toList();
  }

  Future<void> pruneSyncedTransactions({int keepLatest = 100}) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT local_id
      FROM $_transactionsTable
      WHERE deleted = 0 AND sync_status = ?
      ORDER BY datetime(created_at) DESC
      LIMIT -1 OFFSET ?
      ''',
      ['synced', keepLatest],
    );
    if (rows.isEmpty) return;

    final batch = db.batch();
    for (final row in rows) {
      batch.delete(
        _transactionsTable,
        where: 'local_id = ?',
        whereArgs: [row['local_id']],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getCachedCategories() async {
    final rows = await getCachedList('categories');
    return rows
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> cacheCategories(Iterable<String> categories) async {
    final normalized =
        categories
            .map((category) => category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .map((category) => {'name': category})
            .toList()
          ..sort((a, b) => a['name']!.compareTo(b['name']!));
    await upsertCache('categories', normalized);
  }

  Future<Map<String, dynamic>> getProfileBasics() => getCachedMap('profile');
  Future<List<Map<String, dynamic>>> getBudgetSummaries() =>
      getCachedList('budgets');
  Future<Map<String, dynamic>> getDashboardSummary() =>
      getCachedMap('dashboard_summary');
  Future<Map<String, dynamic>> getWalletBalance() =>
      getCachedMap('wallet_balance');

  Map<String, dynamic> _mapTransactionRow(Map<String, Object?> row) {
    return {
      'local_id': row['local_id'],
      'server_id': row['server_id'],
      'id': row['server_id'] != null
          ? int.tryParse(row['server_id'].toString())
          : null,
      'amount': _asDouble(row['amount']),
      'transaction_type': (row['transaction_type'] ?? 'expense').toString(),
      'description': (row['description'] ?? '').toString(),
      'category': (row['category'] ?? 'General').toString(),
      'source': (row['source'] ?? 'cash').toString(),
      'created_at': (row['created_at'] ?? '').toString(),
      'updated_at': (row['updated_at'] ?? '').toString(),
      'sync_status': (row['sync_status'] ?? 'pending').toString(),
      'deleted': (row['deleted'] as int? ?? 0),
    };
  }

  double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
