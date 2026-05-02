import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'local_db_service.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _initialized = false;
  bool _isSyncing = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await LocalDbService.instance.init();
    unawaited(syncAll(trigger: 'app_launch'));

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (_hasConnection(results)) {
        unawaited(syncAll(trigger: 'connectivity_restored'));
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _initialized = false;
  }

  Future<void> syncAll({required String trigger}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint('[SyncService] syncAll trigger=$trigger');
    try {
      await syncPendingTransactions();
      await refreshCaches();
      await LocalDbService.instance.pruneSyncedTransactions();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncPendingTransactions() async {
    final pending = await LocalDbService.instance
        .getPendingTransactionsForSync();
    for (final tx in pending) {
      try {
        final response = await ApiService.pushTransactionToBackend(tx);
        final serverId = (response['id'] ?? response['server_id']).toString();
        await LocalDbService.instance.markTransactionSynced(
          tx['local_id'].toString(),
          serverId: serverId,
          serverPayload: response,
        );
      } catch (e) {
        final status = _isTransientSyncError(e) ? 'pending' : 'failed';
        await LocalDbService.instance.markTransactionSyncStatus(
          tx['local_id'].toString(),
          status,
        );
      }
    }
  }

  Future<void> refreshCaches() async {
    try {
      final transactions = await ApiService.fetchTransactionsFromApi(limit: 50);
      await LocalDbService.instance.upsertServerTransactions(transactions);
      await LocalDbService.instance.upsertCache('transactions_meta', {
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      });

      final budgets = await ApiService.fetchCurrentBudgetFromApi();
      await LocalDbService.instance.upsertCache('budgets', budgets);

      final shoppingLists = await ApiService.fetchShoppingListsFromApi();
      await LocalDbService.instance.upsertCache(
        'shopping_lists',
        shoppingLists,
      );

      final savingsGoals = await ApiService.fetchSavingsGoalsFromApi();
      await LocalDbService.instance.upsertCache('savings_goals', savingsGoals);

      final profile = await ApiService.fetchUserProfileFromApi();
      await LocalDbService.instance.upsertCache('profile', profile);

      final dashboard = await ApiService.fetchDashboardSummaryRemote();
      await LocalDbService.instance.upsertCache('dashboard_summary', dashboard);

      final wallet = await ApiService.fetchWalletBalanceRemote();
      await LocalDbService.instance.upsertCache('wallet_balance', wallet);

      final categories = <String>{
        ...transactions
            .map((tx) => (tx['category'] ?? '').toString())
            .where((value) => value.isNotEmpty),
        ...budgets
            .map((budget) => (budget['label'] ?? '').toString())
            .where((value) => value.isNotEmpty),
        ...shoppingLists
            .map((list) => (list['name'] ?? '').toString())
            .where((value) => value.isNotEmpty),
        ...savingsGoals
            .map((goal) => (goal['name'] ?? '').toString())
            .where((value) => value.isNotEmpty),
      };
      await LocalDbService.instance.cacheCategories(categories);
    } catch (e) {
      debugPrint('[SyncService] refreshCaches skipped: $e');
    }
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  bool _isTransientSyncError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection');
  }

  Future<bool> trySyncAfterWrite() async {
    final isOnline = await _isOnline();
    if (!isOnline) {
      return false;
    }
    await syncPendingTransactions();
    return true;
  }
}
