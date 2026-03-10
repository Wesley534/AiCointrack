import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import 'api_service.dart';

/// Background sync service.
///
/// Responsibilities:
///   1. Listen for connectivity changes
///   2. When online: push all sync_queue entries to backend
///   3. After push: pull fresh data from backend into cache
///   4. Provide a manual [syncNow] for pull-to-refresh
class SyncService {
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static bool _isSyncing = false;
  static final _syncController = StreamController<SyncStatus>.broadcast();

  /// Stream that UI can listen to for sync progress.
  static Stream<SyncStatus> get statusStream => _syncController.stream;

  /// Start listening for connectivity changes.
  static void init() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        syncNow();
      }
    });
  }

  /// Stop listening (call on app dispose / logout).
  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Check if the device currently has network.
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Run a full sync cycle: push pending → pull fresh.
  static Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncController.add(SyncStatus.syncing);

    try {
      await _pushPending();
      await _pullFresh();
      _syncController.add(SyncStatus.done);
    } catch (e) {
      debugPrint('SyncService error: $e');
      _syncController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  // ─── PUSH: send unsynced local records to backend ─────────────────────────

  static Future<void> _pushPending() async {
    final items = await CacheService.getPendingSyncItems();
    if (items.isEmpty) return;

    debugPrint('SyncService: pushing ${items.length} pending items');

    for (final item in items) {
      try {
        final type = item['entity_type'] as String;
        final localId = item['entity_local_id'] as int;
        final payload =
            jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        int? serverId;

        switch (type) {
          case 'transaction':
            await ApiService.pushTransactionToNetwork(
              amount: (payload['amount'] as num).toDouble(),
              description: payload['description'] as String,
              source: payload['source'] as String,
              category: payload['category'] as String?,
              transactionType:
                  payload['transaction_type'] as String? ?? 'expense',
            );
            await CacheService.markSynced('transactions', localId);
            break;

          case 'budget':
            await ApiService.pushBudgetToNetwork(
              label: payload['label'] as String,
              planned: (payload['planned'] as num).toDouble(),
              tag: payload['tag'] as String,
              kind: payload['kind'] as String,
              month: payload['month'] as String,
            );
            await CacheService.markSynced('budgets', localId);
            break;

          case 'shopping_list':
            await ApiService.pushShoppingListToNetwork(
              name: payload['name'] as String,
              budget: (payload['budget'] as num).toDouble(),
            );
            await CacheService.markSynced('shopping_lists', localId);
            break;

          case 'shopping_item':
            final listServerId = payload['list_server_id'] as int?;
            if (listServerId != null) {
              await ApiService.pushShoppingItemToNetwork(
                listServerId,
                name: payload['name'] as String,
                qty: payload['qty'] as int,
                price: (payload['price'] as num).toDouble(),
              );
              await CacheService.markSynced('shopping_items', localId);
            }
            break;

          case 'savings_goal':
            await ApiService.pushSavingsGoalToNetwork(
              name: payload['name'] as String,
              saved: (payload['saved'] as num).toDouble(),
              target: (payload['target'] as num).toDouble(),
              monthly: (payload['monthly'] as num).toDouble(),
            );
            await CacheService.markSynced('savings_goals', localId);
            break;
        }

        // Remove from queue after successful push
        await CacheService.removeSyncItem(item['id'] as int);
        debugPrint('SyncService: pushed $type #$localId (server: $serverId)');
      } catch (e) {
        // Leave in queue for retry next time
        debugPrint('SyncService: failed to push ${item['entity_type']}: $e');
      }
    }
  }

  // ─── PULL: fetch fresh data from backend into cache ────────────────────────

  static Future<void> _pullFresh() async {
    debugPrint('SyncService: pulling fresh data from backend');

    // Run all pulls in parallel for speed
    await Future.wait([
      _pullDashboard(),
      _pullTransactions(),
      _pullBudgets(),
      _pullShoppingLists(),
      _pullSavingsGoals(),
    ]);
  }

  static Future<void> _pullDashboard() async {
    try {
      final data = await ApiService.fetchDashboardFromNetwork();
      if (data.isNotEmpty) {
        await CacheService.cacheDashboard(data);
      }
    } catch (e) {
      debugPrint('SyncService: pull dashboard failed: $e');
    }
  }

  static Future<void> _pullTransactions() async {
    try {
      final txns = await ApiService.fetchTransactionsFromNetwork();
      if (txns.isNotEmpty) {
        await CacheService.cacheTransactions(txns);
      }
    } catch (e) {
      debugPrint('SyncService: pull transactions failed: $e');
    }
  }

  static Future<void> _pullBudgets() async {
    try {
      final budgets = await ApiService.fetchBudgetsFromNetwork();
      if (budgets.isNotEmpty) {
        await CacheService.cacheBudgets(budgets);
      }
    } catch (e) {
      debugPrint('SyncService: pull budgets failed: $e');
    }
  }

  static Future<void> _pullShoppingLists() async {
    try {
      final lists = await ApiService.fetchShoppingListsFromNetwork();
      if (lists.isNotEmpty) {
        await CacheService.cacheShoppingLists(lists);
      }
    } catch (e) {
      debugPrint('SyncService: pull shopping lists failed: $e');
    }
  }

  static Future<void> _pullSavingsGoals() async {
    try {
      final goals = await ApiService.fetchSavingsGoalsFromNetwork();
      if (goals.isNotEmpty) {
        await CacheService.cacheSavingsGoals(goals);
      }
    } catch (e) {
      debugPrint('SyncService: pull savings goals failed: $e');
    }
  }
}

/// Status emitted by the sync stream.
enum SyncStatus { syncing, done, error }
