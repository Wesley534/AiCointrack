import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/cache_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// API service for backend communication and placeholder data for UI pages.
class ApiService {
  // Backend URL is configured in lib/config/constants.dart
  static const String baseUrl = AppConstants.BACKEND_URL;

  /// Register or authenticate user on the backend using Firebase ID token.
  /// Stores the returned JWT for subsequent API calls.
  static Future<Map<String, dynamic>> registerUserWithBackend() async {
    try {
      final idToken = await AuthService.getIdToken();

      if (idToken == null) {
        throw Exception('No user signed in');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/firebase'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jwt = data['accessToken'] ?? data['jwt'];
        if (jwt != null) {
          await TokenService.saveJwt(jwt);
        }
        return data;
      } else {
        throw Exception(
          'Backend registration failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }

  /// Wallet login via SIWE. Returns JWT and optional firebase_custom_token.
  static Future<Map<String, dynamic>> walletLogin({
    required String address,
    required String signature,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/auth/wallet'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'address': address,
            'signature': signature,
            'message': message,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Wallet login failed: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final jwt = data['jwt'];
    if (jwt != null) {
      await TokenService.saveJwt(jwt);
    }
    return data;
  }

  /// Create Privy embedded wallet for user (email signup).
  static Future<Map<String, dynamic>> createWallet() async {
    final jwt = await TokenService.getJwt();
    if (jwt == null) throw Exception('Not signed in');

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/auth/create-wallet'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      final body = response.body;
      throw Exception(
        response.statusCode == 400 || response.statusCode == 503
            ? (jsonDecode(body)['detail'] ?? body)
            : 'Wallet creation failed',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Link wallet to existing account. Requires Firebase token.
  static Future<Map<String, dynamic>> linkWallet({
    required String firebaseToken,
    required String address,
    required String signature,
    required String message,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/auth/link-wallet'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firebase_token': firebaseToken,
            'address': address,
            'signature': signature,
            'message': message,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Link wallet failed: ${response.statusCode} - ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Refresh the ID token and send to backend (optional helper).
  static Future<String?> refreshAndSendToken() async {
    try {
      final newToken = await AuthService.refreshIdToken();

      if (newToken == null) {
        throw Exception('Failed to refresh token');
      }

      await http.post(
        Uri.parse('$baseUrl/api/v1/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        },
        body: jsonEncode({'idToken': newToken}),
      );

      return newToken;
    } catch (e) {
      // For now, just log and swallow – UI can continue with cached data.
      // ignore: avoid_print
      print('Failed to refresh token: $e');
      return null;
    }
  }

  /// Fetch user profile from backend. Uses JWT if available.
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      var token = await TokenService.getJwt();
      if (token == null) {
        token = await AuthService.getIdToken();
      }
      if (token == null) {
        throw Exception('No user signed in');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await TokenService.clearJwt();
        await AuthService.signOut();
        throw Exception('Unauthorized - please sign in again');
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  /// Convenience helper – returns the JWT or Firebase ID token, or null.
  static Future<String?> _getToken() async {
    return await TokenService.getJwt() ?? await AuthService.getIdToken();
  }

  /// Authenticated GET helper.
  static Future<http.Response> _authGet(String path) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not signed in');
    return await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
  }

  /// Authenticated POST helper.
  static Future<http.Response> _authPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not signed in');
    return await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Authenticated PUT helper.
  static Future<http.Response> _authPut(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not signed in');
    return await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  // ─── DASHBOARD ──────────────────────────────────────────────────────────────

  /// Fetch dashboard summary – returns cache immediately, refreshes in background.
  /// Pass [onRefresh] to get notified when fresh data arrives.
  static Future<Map<String, dynamic>> fetchDashboardSummary({
    void Function(Map<String, dynamic>)? onRefresh,
  }) async {
    // 1. Try cache first
    final cached = await CacheService.getCachedDashboard();

    // 2. Fire network request in background
    fetchDashboardFromNetwork().then((fresh) {
      if (fresh.isNotEmpty) {
        CacheService.cacheDashboard(fresh);
        onRefresh?.call(fresh);
      }
    }).catchError((e) {
      debugPrint('Background dashboard refresh failed: $e');
    });

    // 3. Return cache (or empty if first launch)
    return cached ?? {};
  }

  /// Raw network fetch for dashboard (no cache logic).
  static Future<Map<String, dynamic>> fetchDashboardFromNetwork() async {
    final response = await _authGet('/api/v1/dashboard/summary');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
  }

  /// Fetch end-of-month closeout summary from backend.
  static Future<Map<String, dynamic>> fetchCloseoutData() async {
    try {
      final response = await _authGet('/api/v1/dashboard/closeout');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching closeout data: $e');
    }
    return {};
  }

  /// Fetch settings / profile from backend.
  static Future<Map<String, dynamic>> fetchSettingsData() async {
    try {
      final response = await _authGet('/api/v1/dashboard/settings');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
    return {};
  }

  // ─── WALLET ─────────────────────────────────────────────────────────────────

  /// Get the user's wallet address.
  static Future<Map<String, dynamic>> getWalletAddress() async {
    final response = await _authGet('/api/v1/wallet/address');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get wallet address: ${response.statusCode}');
  }

  /// Get withdrawal destinations (M-PESA, bank, etc.).
  static Future<List<dynamic>> getWithdrawDestinations() async {
    final response = await _authGet('/api/v1/wallet/destinations');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to get destinations: ${response.statusCode}');
  }

  /// Initiate a withdrawal.
  static Future<Map<String, dynamic>> initiateWithdrawal({
    required double amountUsdc,
    required String destinationType,
    required String destinationId,
  }) async {
    final response = await _authPost('/api/v1/wallet/withdraw/initiate', {
      'amount_usdc': amountUsdc,
      'destination_type': destinationType,
      'destination_id': destinationId,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Withdrawal failed: ${response.statusCode}');
  }

  /// Check withdrawal status.
  static Future<Map<String, dynamic>> getWithdrawalStatus(String id) async {
    final response = await _authGet('/api/v1/wallet/withdraw/$id/status');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get status: ${response.statusCode}');
  }

  /// Get wallet balance.
  static Future<Map<String, dynamic>> getWalletBalance() async {
    final response = await _authGet('/api/v1/wallet/balance');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get balance: ${response.statusCode}');
  }

  // ─── BUDGET ──────────────────────────────────────────────────────────────────

  /// Budget overview – returns cache immediately, refreshes in background.
  static Future<List<BudgetCategoryExample>> fetchBudgetOverview({
    void Function(List<BudgetCategoryExample>)? onRefresh,
  }) async {
    final cached = await CacheService.getCachedBudgets();

    fetchBudgetsFromNetwork().then((fresh) {
      if (fresh.isNotEmpty) {
        CacheService.cacheBudgets(fresh);
        onRefresh?.call(fresh);
      }
    }).catchError((e) {
      debugPrint('Background budget refresh failed: $e');
    });

    return cached;
  }

  static Future<List<BudgetCategoryExample>> fetchBudgetsFromNetwork() async {
    final response = await _authGet('/api/v1/budgets');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (b) => BudgetCategoryExample(
              id: b['id'] as int?,
              label: b['label'] ?? 'Unknown',
              planned: (b['planned'] ?? 0).toDouble(),
              actual: (b['actual'] ?? 0).toDouble(),
              tag: b['tag'] ?? 'need',
              kind: b['kind'] ?? 'need',
            ),
          )
          .toList();
    }
    return [];
  }

  /// Get current month's budgets from backend.
  static Future<List<BudgetCategoryExample>> fetchCurrentBudget() async {
    try {
      final response = await _authGet('/api/v1/budgets/current');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map(
              (b) => BudgetCategoryExample(
                id: b['id'] as int?,
                label: b['label'] ?? 'Unknown',
                planned: (b['planned'] ?? 0).toDouble(),
                actual: (b['actual'] ?? 0).toDouble(),
                tag: b['tag'] ?? 'need',
                kind: b['kind'] ?? 'need',
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching current budget: $e');
    }
    return [];
  }

  /// Create a new budget on backend.
  /// Create budget – writes locally FIRST (instant UI), then pushes in background.
  static Future<void> createBudget({
    required String label,
    required double planned,
    required String tag,
    required String kind,
    required String month,
  }) async {
    await CacheService.createBudgetLocally(
      label: label, planned: planned, tag: tag, kind: kind, month: month,
    );

    pushBudgetToNetwork(
      label: label, planned: planned, tag: tag, kind: kind, month: month,
    ).catchError((e) {
      debugPrint('Background createBudget push failed (queued): $e');
    });
  }

  /// Raw network POST for a budget.
  static Future<void> pushBudgetToNetwork({
    required String label,
    required double planned,
    required String tag,
    required String kind,
    required String month,
  }) async {
    final response = await _authPost('/api/v1/budgets', {
      'label': label,
      'planned': planned,
      'tag': tag,
      'kind': kind,
      'month': month,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create budget: ${response.body}');
    }
  }

  /// Update an existing budget.
  static Future<void> updateBudget(int budgetId, {
    String? label,
    double? planned,
    double? actual,
    String? tag,
    String? kind,
    String? month,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (planned != null) body['planned'] = planned;
    if (actual != null) body['actual'] = actual;
    if (tag != null) body['tag'] = tag;
    if (kind != null) body['kind'] = kind;
    if (month != null) body['month'] = month;

    final response = await _authPut('/api/v1/budgets/$budgetId', body);
    if (response.statusCode != 200) {
      throw Exception('Failed to update budget: ${response.body}');
    }
  }

  /// Get budget category detail.
  static Future<Map<String, dynamic>> fetchCategoryDetail(int budgetId) async {
    final response = await _authGet('/api/v1/budgets/$budgetId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get category detail: ${response.statusCode}');
  }

  // ─── TRANSACTIONS ──────────────────────────────────────────────────────────

  /// Transactions – returns cache immediately, refreshes in background.
  static Future<List<TransactionExample>> fetchTransactions({
    int? limit,
    int? offset,
    String? source,
    String? month,
    void Function(List<TransactionExample>)? onRefresh,
  }) async {
    final cached = await CacheService.getCachedTransactions(
      limit: limit,
      source: source,
    );

    fetchTransactionsFromNetwork(
      limit: limit, offset: offset, source: source, month: month,
    ).then((fresh) {
      if (fresh.isNotEmpty) {
        CacheService.cacheTransactions(fresh);
        onRefresh?.call(limit != null ? fresh.take(limit).toList() : fresh);
      }
    }).catchError((e) {
      debugPrint('Background transactions refresh failed: $e');
    });

    return cached;
  }

  static Future<List<TransactionExample>> fetchTransactionsFromNetwork({
    int? limit,
    int? offset,
    String? source,
    String? month,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    if (source != null) params['source'] = source;
    if (month != null) params['month'] = month;

    final queryString =
        params.isNotEmpty ? '?${Uri(queryParameters: params).query}' : '';
    final response = await _authGet('/api/v1/transactions/$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((t) {
        final amt = (t['amount'] ?? 0).toDouble();
        final type = t['transaction_type'] ?? 'expense';
        final formattedAmt = type == 'income'
            ? '+${amt.toStringAsFixed(0)}'
            : '-${amt.toStringAsFixed(0)}';

        return TransactionExample(
          description: t['description'] ?? 'Transaction',
          emoji: _categoryEmoji(t['category']),
          amount: formattedAmt,
          date: t['created_at'] != null
              ? t['created_at'].toString().split('T')[0]
              : 'Unknown date',
          source: t['source'] ?? 'manual',
        );
      }).toList();
    }
    return [];
  }

  /// Create offchain transaction – writes locally FIRST (instant UI), then
  /// pushes to network in the background.
  static Future<void> createTransaction({
    required double amount,
    required String description,
    required String source,
    String? category,
    String transactionType = 'expense',
  }) async {
    // 1. Write to local DB immediately so the item appears in the UI
    await CacheService.createTransactionLocally(
      description: description,
      amount: amount,
      source: source,
      category: category,
      transactionType: transactionType,
    );

    // 2. Fire network push in background – SyncService will retry if it fails
    pushTransactionToNetwork(
      amount: amount,
      description: description,
      source: source,
      category: category,
      transactionType: transactionType,
    ).catchError((e) {
      debugPrint('Background createTransaction push failed (queued): $e');
    });
  }

  /// Raw network POST for a transaction (used by SyncService and background push).
  static Future<void> pushTransactionToNetwork({
    required double amount,
    required String description,
    required String source,
    String? category,
    String transactionType = 'expense',
  }) async {
    final response = await _authPost('/api/v1/transactions/offchain', {
      'amount': amount,
      'description': description,
      'source': source,
      'category': category,
      'transaction_type': transactionType,
      'currency': 'KES',
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create transaction: ${response.body}');
    }
  }

  /// Record an onchain (blockchain) transaction.
  static Future<void> recordOnchainTransaction({
    required String txHash,
    required double amountUsdc,
    String? recipient,
    String? note,
    String? category,
    String transactionType = 'expense',
  }) async {
    final response = await _authPost('/api/v1/transactions/onchain', {
      'tx_hash': txHash,
      'amount': amountUsdc,
      'recipient': recipient,
      'description': note,
      'category': category,
      'currency': 'USDC',
      'transaction_type': transactionType,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to record onchain tx: ${response.body}');
    }
  }

  /// AI-categorize a transaction description.
  static Future<Map<String, dynamic>> categorizeWithAI({
    required String description,
    required double amount,
  }) async {
    final response = await _authPost('/api/v1/transactions/ai-categorize', {
      'description': description,
      'amount': amount,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('AI categorization failed: ${response.statusCode}');
  }

  /// Helper to map category strings to emojis.
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

  // ─── SHOPPING ───────────────────────────────────────────────────────────────

  /// Shopping lists – returns cache immediately, refreshes in background.
  static Future<List<ShoppingListExample>> fetchShoppingLists({
    void Function(List<ShoppingListExample>)? onRefresh,
  }) async {
    final cached = await CacheService.getCachedShoppingLists();

    fetchShoppingListsFromNetwork().then((fresh) {
      if (fresh.isNotEmpty) {
        CacheService.cacheShoppingLists(fresh);
        onRefresh?.call(fresh);
      }
    }).catchError((e) {
      debugPrint('Background shopping lists refresh failed: $e');
    });

    return cached;
  }

  static Future<List<ShoppingListExample>> fetchShoppingListsFromNetwork() async {
    final response = await _authGet('/api/v1/shopping-lists');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((l) {
        final itemsList = l['items'] as List<dynamic>? ?? [];
        double total = 0;
        for (var item in itemsList) {
          total += ((item['price'] ?? 0) as num) * ((item['qty'] ?? 1) as num);
        }
        final budget = (l['budget'] ?? 0).toDouble();
        final status = (budget > 0 && total > budget)
            ? 'red'
            : ((budget > 0 && total > budget * 0.8) ? 'yellow' : 'green');

        return ShoppingListExample(
          id: l['id'] as int?,
          name: l['name'] ?? 'Shopping List',
          total: total,
          budget: budget,
          items: itemsList.length,
          status: status,
        );
      }).toList();
    }
    return [];
  }

  /// Create shopping list – writes locally FIRST, then pushes in background.
  static Future<void> createShoppingList({
    required String name,
    required double budget,
  }) async {
    await CacheService.createShoppingListLocally(name: name, budget: budget);

    pushShoppingListToNetwork(name: name, budget: budget).catchError((e) {
      debugPrint('Background createShoppingList push failed (queued): $e');
    });
  }

  /// Raw network POST for a shopping list.
  static Future<void> pushShoppingListToNetwork({
    required String name,
    required double budget,
  }) async {
    final response = await _authPost('/api/v1/shopping-lists', {
      'name': name,
      'budget': budget,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create shopping list: ${response.body}');
    }
  }

  /// Fetch a single shopping list with items – cache-first, network in background.
  static Future<ShoppingDetailExample> fetchShoppingListById(
    int listId, {
    void Function(ShoppingDetailExample)? onRefresh,
  }) async {
    // 1. Try cache first
    final cached = await CacheService.getCachedShoppingDetail(listId);

    // 2. Fire network fetch in background
    _fetchShoppingDetailFromNetwork(listId).then((fresh) {
      CacheService.cacheShoppingDetail(listId, fresh);
      onRefresh?.call(fresh);
    }).catchError((e) {
      debugPrint('Background shopping detail refresh failed: $e');
    });

    // 3. Return cache if available, otherwise wait for network
    if (cached != null) return cached;

    // First load – must wait for network
    try {
      final detail = await _fetchShoppingDetailFromNetwork(listId);
      CacheService.cacheShoppingDetail(listId, detail);
      return detail;
    } catch (e) {
      // Return empty detail so UI doesn't crash
      return ShoppingDetailExample(
        title: 'Shopping List',
        total: 0,
        remaining: 0,
        items: [],
      );
    }
  }

  /// Raw network fetch for a single shopping list detail.
  static Future<ShoppingDetailExample> _fetchShoppingDetailFromNetwork(
      int listId) async {
    final response = await _authGet('/api/v1/shopping-lists/$listId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final itemsList = data['items'] as List<dynamic>? ?? [];
      double total = 0;
      final items = itemsList.map((i) {
        final price = (i['price'] ?? 0).toDouble();
        final qty = (i['qty'] ?? 1) as int;
        total += price * qty;
        return ShoppingItemExample(
          name: i['name'] ?? 'Item',
          qty: qty,
          price: price,
        );
      }).toList();

      final budget = (data['budget'] ?? 0).toDouble();
      return ShoppingDetailExample(
        title: data['name'] ?? 'Shopping List',
        total: total,
        remaining: budget - total,
        items: items,
      );
    }
    throw Exception('Failed to get shopping list: ${response.statusCode}');
  }

  /// Add item to a shopping list – writes locally FIRST, then pushes in background.
  static Future<void> addShoppingItem(int listId, {
    required String name,
    required int qty,
    required double price,
  }) async {
    await CacheService.addShoppingItemLocally(
      listId, name: name, qty: qty, price: price, listServerId: listId,
    );

    pushShoppingItemToNetwork(
      listId, name: name, qty: qty, price: price,
    ).catchError((e) {
      debugPrint('Background addShoppingItem push failed (queued): $e');
    });
  }

  /// Raw network POST for a shopping item.
  static Future<void> pushShoppingItemToNetwork(int listId, {
    required String name,
    required int qty,
    required double price,
  }) async {
    final response = await _authPost('/api/v1/shopping-lists/$listId/items', {
      'name': name,
      'qty': qty,
      'price': price,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add item: ${response.body}');
    }
  }

  // ─── SAVINGS ────────────────────────────────────────────────────────────────

  /// Savings goals – returns cache immediately, refreshes in background.
  static Future<List<SavingsGoalExample>> fetchSavingsGoals({
    void Function(List<SavingsGoalExample>)? onRefresh,
  }) async {
    final cached = await CacheService.getCachedSavingsGoals();

    fetchSavingsGoalsFromNetwork().then((fresh) {
      if (fresh.isNotEmpty) {
        CacheService.cacheSavingsGoals(fresh);
        onRefresh?.call(fresh);
      }
    }).catchError((e) {
      debugPrint('Background savings goals refresh failed: $e');
    });

    return cached;
  }

  static Future<List<SavingsGoalExample>> fetchSavingsGoalsFromNetwork() async {
    final response = await _authGet('/api/v1/savings-goals');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map(
            (g) => SavingsGoalExample(
              id: g['id']?.toString(),
              name: g['name'] ?? 'Goal',
              saved: (g['saved'] ?? 0).toDouble(),
              target: (g['target'] ?? 0).toDouble(),
              monthly: (g['monthly'] ?? 0).toDouble(),
            ),
          )
          .toList();
    }
    return [];
  }

  /// Create savings goal – writes locally FIRST, then pushes in background.
  static Future<void> createSavingsGoal({
    required String name,
    required double saved,
    required double target,
    required double monthly,
  }) async {
    await CacheService.createSavingsGoalLocally(
      name: name, target: target, monthly: monthly,
    );

    pushSavingsGoalToNetwork(
      name: name, saved: saved, target: target, monthly: monthly,
    ).catchError((e) {
      debugPrint('Background createSavingsGoal push failed (queued): $e');
    });
  }

  /// Raw network POST for a savings goal.
  static Future<void> pushSavingsGoalToNetwork({
    required String name,
    required double saved,
    required double target,
    required double monthly,
  }) async {
    final response = await _authPost('/api/v1/savings-goals', {
      'name': name,
      'saved': saved,
      'target': target,
      'monthly': monthly,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create savings goal: ${response.body}');
    }
  }

  /// Contribute USDC to a savings goal.
  static Future<void> contributeToGoal(String goalId, {
    required double amountUsdc,
    required String txHash,
  }) async {
    final response = await _authPost('/api/v1/savings-goals/$goalId/contribute', {
      'amount_usdc': amountUsdc,
      'tx_hash': txHash,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to contribute: ${response.body}');
    }
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class BudgetCategoryExample {
  final int? id;
  final String label;
  final double planned;
  final double actual;
  final String tag;
  final String kind;

  BudgetCategoryExample({
    this.id,
    required this.label,
    required this.planned,
    required this.actual,
    required this.tag,
    required this.kind,
  });
}

class TransactionExample {
  final String description;
  final String emoji;
  final String amount;
  final String date;
  final String source;

  TransactionExample({
    required this.description,
    required this.emoji,
    required this.amount,
    required this.date,
    required this.source,
  });
}

class ShoppingListExample {
  final int? id;
  final String name;
  final double total;
  final double budget;
  final int items;
  final String status;

  ShoppingListExample({
    this.id,
    required this.name,
    required this.total,
    required this.budget,
    required this.items,
    required this.status,
  });
}

class ShoppingDetailExample {
  final String title;
  final double total;
  final double remaining;
  final List<ShoppingItemExample> items;

  ShoppingDetailExample({
    required this.title,
    required this.total,
    required this.remaining,
    required this.items,
  });
}

class ShoppingItemExample {
  final String name;
  final int qty;
  final double price;

  ShoppingItemExample({
    required this.name,
    required this.qty,
    required this.price,
  });
}

class SavingsGoalExample {
  final String? id;
  final String name;
  final double saved;
  final double target;
  final double monthly;

  SavingsGoalExample({
    this.id,
    required this.name,
    required this.saved,
    required this.target,
    required this.monthly,
  });
}
