import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../db/local_database.dart';
import '../services/api_service.dart';

/// Offline-first cache layer.
///
/// Pattern: **stale-while-revalidate**
///   1. Return cached data immediately (if available)
///   2. Fetch fresh data from network in background
///   3. Update cache + notify caller via callback
///
/// For creates (add transaction, add shopping item, etc.):
///   1. Write to local DB with `synced = 0`
///   2. Enqueue in sync_queue
///   3. SyncService pushes when online
class CacheService {
  // ─── DASHBOARD ─────────────────────────────────────────────────────────────

  /// Get cached dashboard JSON, or null if never fetched.
  static Future<Map<String, dynamic>?> getCachedDashboard() async {
    try {
      final db = await LocalDatabase.database;
      final rows = await db.query('dashboard_cache',
          where: 'key = ?', whereArgs: ['summary']);
      if (rows.isNotEmpty) {
        return jsonDecode(rows.first['value'] as String)
            as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('CacheService.getCachedDashboard error: $e');
    }
    return null;
  }

  /// Save dashboard JSON to cache.
  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    try {
      final db = await LocalDatabase.database;
      await db.insert(
        'dashboard_cache',
        {
          'key': 'summary',
          'value': jsonEncode(data),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('CacheService.cacheDashboard error: $e');
    }
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  /// Get cached transactions, optionally filtered by source.
  static Future<List<TransactionExample>> getCachedTransactions({
    int? limit,
    String? source,
  }) async {
    try {
      final db = await LocalDatabase.database;
      String? where;
      List<dynamic>? whereArgs;
      if (source != null) {
        where = 'source = ?';
        whereArgs = [source];
      }
      final rows = await db.query(
        'transactions',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows
          .map((r) => TransactionExample(
                description: r['description'] as String,
                emoji: r['emoji'] as String,
                amount: r['amount'] as String,
                date: r['date'] as String,
                source: r['source'] as String,
              ))
          .toList();
    } catch (e) {
      debugPrint('CacheService.getCachedTransactions error: $e');
    }
    return [];
  }

  /// Replace all cached transactions with fresh data from backend.
  static Future<void> cacheTransactions(
      List<TransactionExample> transactions) async {
    try {
      final db = await LocalDatabase.database;
      final batch = db.batch();
      // Only delete synced rows – keep unsynced (offline-created) ones
      batch.delete('transactions', where: 'synced = 1');
      for (final t in transactions) {
        batch.insert('transactions', {
          'description': t.description,
          'emoji': t.emoji,
          'amount': t.amount,
          'date': t.date,
          'source': t.source,
          'synced': 1,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.cacheTransactions error: $e');
    }
  }

  /// Create a transaction locally (offline-safe).
  /// Returns the local row id.
  static Future<int> createTransactionLocally({
    required double amount,
    required String description,
    required String source,
    String? category,
    String transactionType = 'expense',
  }) async {
    final db = await LocalDatabase.database;
    final formattedAmt = transactionType == 'income'
        ? '+${amount.toStringAsFixed(0)}'
        : '-${amount.toStringAsFixed(0)}';

    final localId = await db.insert('transactions', {
      'description': description,
      'emoji': _categoryEmoji(category),
      'amount': formattedAmt,
      'amount_raw': amount,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'source': source,
      'category': category,
      'transaction_type': transactionType,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Enqueue for sync
    await db.insert('sync_queue', {
      'entity_type': 'transaction',
      'entity_local_id': localId,
      'action': 'create',
      'payload': jsonEncode({
        'amount': amount,
        'description': description,
        'source': source,
        'category': category,
        'transaction_type': transactionType,
        'currency': 'KES',
      }),
      'created_at': DateTime.now().toIso8601String(),
    });

    return localId;
  }

  // ─── BUDGETS ───────────────────────────────────────────────────────────────

  /// Get cached budgets.
  static Future<List<BudgetCategoryExample>> getCachedBudgets() async {
    try {
      final db = await LocalDatabase.database;
      final rows =
          await db.query('budgets', orderBy: 'created_at DESC');
      return rows
          .map((r) => BudgetCategoryExample(
                id: r['server_id'] as int?,
                label: r['label'] as String,
                planned: (r['planned'] as num).toDouble(),
                actual: (r['actual'] as num).toDouble(),
                tag: r['tag'] as String,
                kind: r['kind'] as String,
              ))
          .toList();
    } catch (e) {
      debugPrint('CacheService.getCachedBudgets error: $e');
    }
    return [];
  }

  /// Replace cached budgets with fresh data.
  static Future<void> cacheBudgets(List<BudgetCategoryExample> budgets) async {
    try {
      final db = await LocalDatabase.database;
      final batch = db.batch();
      batch.delete('budgets', where: 'synced = 1');
      for (final b in budgets) {
        batch.insert('budgets', {
          'server_id': b.id,
          'label': b.label,
          'planned': b.planned,
          'actual': b.actual,
          'tag': b.tag,
          'kind': b.kind,
          'synced': 1,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.cacheBudgets error: $e');
    }
  }

  /// Create a budget locally (offline-safe).
  static Future<int> createBudgetLocally({
    required String label,
    required double planned,
    required String tag,
    required String kind,
    required String month,
  }) async {
    final db = await LocalDatabase.database;
    final localId = await db.insert('budgets', {
      'label': label,
      'planned': planned,
      'actual': 0,
      'tag': tag,
      'kind': kind,
      'month': month,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('sync_queue', {
      'entity_type': 'budget',
      'entity_local_id': localId,
      'action': 'create',
      'payload': jsonEncode({
        'label': label,
        'planned': planned,
        'tag': tag,
        'kind': kind,
        'month': month,
      }),
      'created_at': DateTime.now().toIso8601String(),
    });

    return localId;
  }

  // ─── SHOPPING LISTS ────────────────────────────────────────────────────────

  /// Get cached shopping lists.
  static Future<List<ShoppingListExample>> getCachedShoppingLists() async {
    try {
      final db = await LocalDatabase.database;
      final rows =
          await db.query('shopping_lists', orderBy: 'created_at DESC');
      final lists = <ShoppingListExample>[];

      for (final r in rows) {
        final localId = r['id'] as int;
        final serverId = r['server_id'] as int?;

        // Count items and sum total from shopping_items table
        final itemRows = await db.query('shopping_items',
            where: 'list_id = ?', whereArgs: [localId]);
        double total = 0;
        for (final item in itemRows) {
          total += (item['price'] as num).toDouble() *
              (item['qty'] as num).toInt();
        }
        final budget = (r['budget'] as num).toDouble();
        final status = (budget > 0 && total > budget)
            ? 'red'
            : ((budget > 0 && total > budget * 0.8) ? 'yellow' : 'green');

        lists.add(ShoppingListExample(
          id: serverId ?? localId,
          name: r['name'] as String,
          total: total,
          budget: budget,
          items: itemRows.length,
          status: status,
        ));
      }
      return lists;
    } catch (e) {
      debugPrint('CacheService.getCachedShoppingLists error: $e');
    }
    return [];
  }

  /// Replace cached shopping lists + items with fresh data.
  static Future<void> cacheShoppingLists(
    List<ShoppingListExample> lists,
  ) async {
    try {
      final db = await LocalDatabase.database;
      final batch = db.batch();
      batch.delete('shopping_items', where: 'synced = 1');
      batch.delete('shopping_lists', where: 'synced = 1');
      for (final l in lists) {
        batch.insert('shopping_lists', {
          'server_id': l.id,
          'name': l.name,
          'budget': l.budget,
          'synced': 1,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.cacheShoppingLists error: $e');
    }
  }

  /// Cache a shopping list detail (items).
  static Future<void> cacheShoppingDetail(
      int serverId, ShoppingDetailExample detail) async {
    try {
      final db = await LocalDatabase.database;
      // Find local list row
      final listRows = await db.query('shopping_lists',
          where: 'server_id = ?', whereArgs: [serverId]);
      if (listRows.isEmpty) return;
      final localListId = listRows.first['id'] as int;

      final batch = db.batch();
      batch.delete('shopping_items',
          where: 'list_id = ? AND synced = 1', whereArgs: [localListId]);
      for (final item in detail.items) {
        batch.insert('shopping_items', {
          'list_id': localListId,
          'list_server_id': serverId,
          'name': item.name,
          'qty': item.qty,
          'price': item.price,
          'synced': 1,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.cacheShoppingDetail error: $e');
    }
  }

  /// Get cached shopping list detail (items) by server ID.
  static Future<ShoppingDetailExample?> getCachedShoppingDetail(
      int serverId) async {
    try {
      final db = await LocalDatabase.database;
      // Find the local list row
      final listRows = await db.query('shopping_lists',
          where: 'server_id = ?', whereArgs: [serverId]);
      if (listRows.isEmpty) {
        // Also try matching by local id (for locally-created lists)
        final localRows = await db.query('shopping_lists',
            where: 'id = ?', whereArgs: [serverId]);
        if (localRows.isEmpty) return null;
        return _buildShoppingDetail(db, localRows.first);
      }
      return _buildShoppingDetail(db, listRows.first);
    } catch (e) {
      debugPrint('CacheService.getCachedShoppingDetail error: $e');
    }
    return null;
  }

  /// Build a ShoppingDetailExample from a list row + its items.
  static Future<ShoppingDetailExample> _buildShoppingDetail(
      dynamic db, Map<String, dynamic> listRow) async {
    final localListId = listRow['id'] as int;
    final budget = (listRow['budget'] as num).toDouble();

    final itemRows = await db.query('shopping_items',
        where: 'list_id = ?', whereArgs: [localListId]);

    double total = 0;
    final items = (itemRows as List<Map<String, dynamic>>).map((r) {
      final price = (r['price'] as num).toDouble();
      final qty = (r['qty'] as num).toInt();
      total += price * qty;
      return ShoppingItemExample(
        name: r['name'] as String,
        qty: qty,
        price: price,
      );
    }).toList();

    return ShoppingDetailExample(
      title: listRow['name'] as String,
      total: total,
      remaining: budget - total,
      items: items,
    );
  }

  /// Create a shopping list locally (offline-safe).
  static Future<int> createShoppingListLocally({
    required String name,
    required double budget,
  }) async {
    final db = await LocalDatabase.database;
    final localId = await db.insert('shopping_lists', {
      'name': name,
      'budget': budget,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('sync_queue', {
      'entity_type': 'shopping_list',
      'entity_local_id': localId,
      'action': 'create',
      'payload': jsonEncode({'name': name, 'budget': budget}),
      'created_at': DateTime.now().toIso8601String(),
    });

    return localId;
  }

  /// Add a shopping item locally (offline-safe).
  static Future<int> addShoppingItemLocally(int listLocalId, {
    required String name,
    required int qty,
    required double price,
    int? listServerId,
  }) async {
    final db = await LocalDatabase.database;
    final localId = await db.insert('shopping_items', {
      'list_id': listLocalId,
      'list_server_id': listServerId,
      'name': name,
      'qty': qty,
      'price': price,
      'synced': 0,
    });

    await db.insert('sync_queue', {
      'entity_type': 'shopping_item',
      'entity_local_id': localId,
      'action': 'create',
      'payload': jsonEncode({
        'list_server_id': listServerId,
        'name': name,
        'qty': qty,
        'price': price,
      }),
      'created_at': DateTime.now().toIso8601String(),
    });

    return localId;
  }

  // ─── SAVINGS GOALS ─────────────────────────────────────────────────────────

  /// Get cached savings goals.
  static Future<List<SavingsGoalExample>> getCachedSavingsGoals() async {
    try {
      final db = await LocalDatabase.database;
      final rows =
          await db.query('savings_goals', orderBy: 'created_at DESC');
      return rows
          .map((r) => SavingsGoalExample(
                id: (r['server_id'] as int?)?.toString(),
                name: r['name'] as String,
                saved: (r['saved'] as num).toDouble(),
                target: (r['target'] as num).toDouble(),
                monthly: (r['monthly'] as num).toDouble(),
              ))
          .toList();
    } catch (e) {
      debugPrint('CacheService.getCachedSavingsGoals error: $e');
    }
    return [];
  }

  /// Replace cached savings goals with fresh data.
  static Future<void> cacheSavingsGoals(
      List<SavingsGoalExample> goals) async {
    try {
      final db = await LocalDatabase.database;
      final batch = db.batch();
      batch.delete('savings_goals', where: 'synced = 1');
      for (final g in goals) {
        batch.insert('savings_goals', {
          'server_id': g.id != null ? int.tryParse(g.id!) : null,
          'name': g.name,
          'saved': g.saved,
          'target': g.target,
          'monthly': g.monthly,
          'synced': 1,
        });
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.cacheSavingsGoals error: $e');
    }
  }

  /// Create a savings goal locally (offline-safe).
  static Future<int> createSavingsGoalLocally({
    required String name,
    required double target,
    required double monthly,
  }) async {
    final db = await LocalDatabase.database;
    final localId = await db.insert('savings_goals', {
      'name': name,
      'saved': 0,
      'target': target,
      'monthly': monthly,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('sync_queue', {
      'entity_type': 'savings_goal',
      'entity_local_id': localId,
      'action': 'create',
      'payload': jsonEncode({
        'name': name,
        'saved': 0,
        'target': target,
        'monthly': monthly,
      }),
      'created_at': DateTime.now().toIso8601String(),
    });

    return localId;
  }

  // ─── SYNC QUEUE ────────────────────────────────────────────────────────────

  /// Get all pending sync queue entries.
  static Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await LocalDatabase.database;
    return db.query('sync_queue', orderBy: 'created_at ASC');
  }

  /// Remove a sync queue entry after successful push.
  static Future<void> removeSyncItem(int id) async {
    final db = await LocalDatabase.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Mark a local entity as synced after push succeeds.
  static Future<void> markSynced(String table, int localId,
      {int? serverId}) async {
    final db = await LocalDatabase.database;
    final values = <String, dynamic>{'synced': 1};
    if (serverId != null) values['server_id'] = serverId;
    await db.update(table, values, where: 'id = ?', whereArgs: [localId]);
  }

  /// Clear all cached data (e.g. on logout).
  static Future<void> clearAll() async {
    try {
      final db = await LocalDatabase.database;
      final batch = db.batch();
      batch.delete('transactions');
      batch.delete('budgets');
      batch.delete('shopping_items');
      batch.delete('shopping_lists');
      batch.delete('savings_goals');
      batch.delete('dashboard_cache');
      batch.delete('sync_queue');
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('CacheService.clearAll error: $e');
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  static String _categoryEmoji(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return '🍔';
      case 'transport':
        return '🚗';
      case 'rent':
      case 'housing':
        return '🏠';
      case 'shopping':
        return '🛒';
      case 'entertainment':
        return '🎬';
      case 'utilities':
        return '💡';
      case 'health':
        return '🏥';
      case 'income':
        return '💰';
      default:
        return '💸';
    }
  }
}
