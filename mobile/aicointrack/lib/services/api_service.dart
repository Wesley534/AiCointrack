import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../services/token_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// API service for backend communication and placeholder data for UI pages.
class ApiService {
  // Backend URL is configured in lib/config/constants.dart
  static const String baseUrl = AppConstants.BACKEND_URL;
  // Dev tunnel can introduce significant latency; keep API timeout generous.
  static const Duration _requestTimeout = Duration(seconds: 60);

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
            _requestTimeout,
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
          _requestTimeout,
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
          _requestTimeout,
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
          _requestTimeout,
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
  static Future<Map<String, dynamic>> fetchUserProfileFromApi() async {
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
            _requestTimeout,
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

  static Future<Map<String, dynamic>> fetchUserProfile() async {
    final cached = await LocalDbService.instance.getProfileBasics();
    try {
      final remote = await fetchUserProfileFromApi();
      await LocalDbService.instance.upsertCache('profile', remote);
      return remote;
    } catch (e) {
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    var token = await TokenService.getJwt();
    if (token == null) {
      token = await AuthService.getIdToken();
    }
    if (token == null) {
      throw Exception('No user signed in');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  static Exception _buildApiException(http.Response response) {
    try {
      final decoded = _decodeBody(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'] ?? response.body;
        return Exception(detail.toString());
      }
    } catch (_) {}
    return Exception(
      'Request failed: ${response.statusCode} - ${response.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> fetchTransactionsFromApi({
    int limit = 50,
    String? source,
    String? transactionType,
  }) async {
    final headers = await _authHeaders();
    final query = <String, String>{
      'limit': '$limit',
      if (source != null && source.isNotEmpty) 'source': source,
      if (transactionType != null && transactionType.isNotEmpty)
        'transaction_type': transactionType,
    };

    final uri = Uri.parse(
      '$baseUrl/api/v1/transactions/',
    ).replace(queryParameters: query);
    final response = await http
        .get(uri, headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final decoded = _decodeBody(response.body);
    final list = decoded is Map<String, dynamic>
        ? (decoded['transactions'] as List<dynamic>? ?? <dynamic>[])
        : (decoded as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchTransactions({
    int limit = 50,
    String? source,
    String? transactionType,
  }) async {
    final local = await LocalDbService.instance.getTransactions(
      syncedLimit: limit,
      source: source,
      transactionType: transactionType,
    );

    try {
      final remote = await fetchTransactionsFromApi(
        limit: limit,
        source: source,
        transactionType: transactionType,
      );
      await LocalDbService.instance.upsertServerTransactions(remote);
      await LocalDbService.instance.upsertCache('transactions_meta', {
        'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      });
      final categories = remote
          .map((item) => (item['category'] ?? '').toString())
          .where((item) => item.isNotEmpty);
      await LocalDbService.instance.cacheCategories(categories);
      return LocalDbService.instance.getTransactions(
        syncedLimit: limit,
        source: source,
        transactionType: transactionType,
      );
    } catch (e) {
      if (local.isNotEmpty) {
        return local;
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCachedTransactions({
    int limit = 50,
    String? source,
    String? transactionType,
  }) {
    return LocalDbService.instance.getTransactions(
      syncedLimit: limit,
      source: source,
      transactionType: transactionType,
    );
  }

  static Future<List<Map<String, dynamic>>> refreshTransactionsCache({
    int limit = 50,
    String? source,
    String? transactionType,
  }) async {
    final remote = await fetchTransactionsFromApi(
      limit: limit,
      source: source,
      transactionType: transactionType,
    );
    await LocalDbService.instance.upsertServerTransactions(remote);
    await LocalDbService.instance.upsertCache('transactions_meta', {
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
    });
    final categories = remote
        .map((item) => (item['category'] ?? '').toString())
        .where((item) => item.isNotEmpty);
    await LocalDbService.instance.cacheCategories(categories);
    return LocalDbService.instance.getTransactions(
      syncedLimit: limit,
      source: source,
      transactionType: transactionType,
    );
  }

  static Future<Map<String, dynamic>> recordOffchainTransaction({
    required String description,
    required double amount,
    required String source,
    required String transactionType,
    required String category,
    String currency = 'KES',
    String? referenceNumber,
  }) async {
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localTx = await LocalDbService.instance.insertPendingTransaction(
      localId: localId,
      amount: amount,
      transactionType: transactionType,
      description: description,
      category: category,
      source: source,
    );

    try {
      final response = await _createOffchainTransactionOnBackend(
        description: description,
        amount: amount,
        source: source,
        transactionType: transactionType,
        category: category,
        currency: currency,
        referenceNumber: referenceNumber,
      );
      await LocalDbService.instance.markTransactionSynced(
        localId,
        serverId: (response['id'] ?? '').toString(),
        serverPayload: response,
      );
      return Map<String, dynamic>.from(response)
        ..['local_id'] = localId
        ..['sync_status'] = 'synced';
    } catch (e) {
      await LocalDbService.instance.markTransactionSyncStatus(
        localId,
        _isTransientNetworkError(e) ? 'pending' : 'failed',
      );
      return localTx;
    }
  }

  static Future<Map<String, dynamic>> pushTransactionToBackend(
    Map<String, dynamic> localTransaction,
  ) {
    return _createOffchainTransactionOnBackend(
      description: (localTransaction['description'] ?? '').toString(),
      amount: _readDouble(localTransaction['amount']),
      source: (localTransaction['source'] ?? 'cash').toString(),
      transactionType: (localTransaction['transaction_type'] ?? 'expense')
          .toString(),
      category: (localTransaction['category'] ?? 'General').toString(),
    );
  }

  static Future<Map<String, dynamic>> _createOffchainTransactionOnBackend({
    required String description,
    required double amount,
    required String source,
    required String transactionType,
    required String category,
    String currency = 'KES',
    String? referenceNumber,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/transactions/offchain'),
          headers: headers,
          body: jsonEncode({
            'description': description,
            'amount': amount,
            'source': source,
            'transaction_type': transactionType,
            'category': category,
            'currency': currency,
            if (referenceNumber != null && referenceNumber.isNotEmpty)
              'reference_number': referenceNumber,
          }),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<List<Map<String, dynamic>>> fetchCurrentBudgetFromApi() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/budgets/current'), headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final decoded = _decodeBody(response.body) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchCurrentBudget() async {
    final cached = await LocalDbService.instance.getBudgetSummaries();
    try {
      final remote = await fetchCurrentBudgetFromApi();
      await LocalDbService.instance.upsertCache('budgets', remote);
      final categories = remote
          .map((item) => (item['label'] ?? '').toString())
          .where((item) => item.isNotEmpty);
      await LocalDbService.instance.cacheCategories(categories);
      return remote;
    } catch (e) {
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCachedBudget() {
    return LocalDbService.instance.getBudgetSummaries();
  }

  static Future<List<Map<String, dynamic>>> refreshBudgetCache() async {
    final remote = await fetchCurrentBudgetFromApi();
    await LocalDbService.instance.upsertCache('budgets', remote);
    final categories = remote
        .map((item) => (item['label'] ?? '').toString())
        .where((item) => item.isNotEmpty);
    await LocalDbService.instance.cacheCategories(categories);
    return remote;
  }

  static Future<Map<String, dynamic>> createBudget({
    required String label,
    required double planned,
    required String tag,
    required String kind,
    required String month,
    double actual = 0.0,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/budgets'),
          headers: headers,
          body: jsonEncode({
            'label': label,
            'planned': planned,
            'actual': actual,
            'tag': tag,
            'kind': kind,
            'month': month,
          }),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<Map<String, dynamic>> updateBudget(
    int id, {
    String? label,
    double? planned,
    double? actual,
    String? tag,
    String? kind,
    String? month,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/v1/budgets/$id'),
          headers: headers,
          body: jsonEncode({
            if (label != null) 'label': label,
            if (planned != null) 'planned': planned,
            if (actual != null) 'actual': actual,
            if (tag != null) 'tag': tag,
            if (kind != null) 'kind': kind,
            if (month != null) 'month': month,
          }),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<List<Map<String, dynamic>>> fetchShoppingListsFromApi() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/shopping-lists'), headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final decoded = _decodeBody(response.body) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>>
  fetchShoppingListsCachedFirst() async {
    final cached = await fetchCachedShoppingLists();
    try {
      return await refreshShoppingListsCache();
    } catch (e) {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCachedShoppingLists() {
    return LocalDbService.instance.getCachedList('shopping_lists');
  }

  static Future<List<Map<String, dynamic>>> refreshShoppingListsCache() async {
    final remote = await fetchShoppingListsFromApi();
    await LocalDbService.instance.upsertCache('shopping_lists', remote);
    return remote;
  }

  static Future<Map<String, dynamic>> createShoppingList({
    required String name,
    required double budget,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/shopping-lists'),
          headers: headers,
          body: jsonEncode({'name': name, 'budget': budget, 'status': 'green'}),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    final decoded = Map<String, dynamic>.from(
      _decodeBody(response.body) as Map,
    );
    await refreshShoppingListsCache().catchError(
      (_) => <Map<String, dynamic>>[],
    );
    return decoded;
  }

  static Future<Map<String, dynamic>> fetchShoppingListDetail(
    int listId,
  ) async {
    final cached = await fetchCachedShoppingListDetail(listId);
    try {
      return await refreshShoppingListDetailCache(listId);
    } catch (e) {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchShoppingListDetailFromApi(
    int listId,
  ) async {
    final headers = await _authHeaders();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/v1/shopping-lists/$listId'),
          headers: headers,
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<Map<String, dynamic>> fetchCachedShoppingListDetail(
    int listId,
  ) {
    return LocalDbService.instance.getCachedMap('shopping_detail_$listId');
  }

  static Future<Map<String, dynamic>> refreshShoppingListDetailCache(
    int listId,
  ) async {
    final remote = await fetchShoppingListDetailFromApi(listId);
    await LocalDbService.instance.upsertCache(
      'shopping_detail_$listId',
      remote,
    );
    return remote;
  }

  static Future<Map<String, dynamic>> addShoppingItem(
    int listId, {
    required String name,
    required int qty,
    required double price,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/shopping-lists/$listId/items'),
          headers: headers,
          body: jsonEncode({'name': name, 'qty': qty, 'price': price}),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    final decoded = Map<String, dynamic>.from(
      _decodeBody(response.body) as Map,
    );
    await refreshShoppingListDetailCache(
      listId,
    ).catchError((_) => <String, dynamic>{});
    await refreshShoppingListsCache().catchError(
      (_) => <Map<String, dynamic>>[],
    );
    return decoded;
  }

  static Future<Map<String, dynamic>> updateShoppingItem(
    int listId,
    int itemId, {
    required String name,
    required int qty,
    required double price,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/v1/shopping-lists/$listId/items/$itemId'),
          headers: headers,
          body: jsonEncode({'name': name, 'qty': qty, 'price': price}),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }
    final decoded = Map<String, dynamic>.from(
      _decodeBody(response.body) as Map,
    );
    await refreshShoppingListDetailCache(
      listId,
    ).catchError((_) => <String, dynamic>{});
    await refreshShoppingListsCache().catchError(
      (_) => <Map<String, dynamic>>[],
    );
    return decoded;
  }

  static Future<List<Map<String, dynamic>>> fetchSavingsGoalsFromApi() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/savings-goals'), headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final decoded = _decodeBody(response.body) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>>
  fetchSavingsGoalsCachedFirst() async {
    final cached = await fetchCachedSavingsGoals();
    try {
      return await refreshSavingsGoalsCache();
    } catch (e) {
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCachedSavingsGoals() {
    return LocalDbService.instance.getCachedList('savings_goals');
  }

  static Future<List<Map<String, dynamic>>> refreshSavingsGoalsCache() async {
    final remote = await fetchSavingsGoalsFromApi();
    await LocalDbService.instance.upsertCache('savings_goals', remote);
    return remote;
  }

  static Future<Map<String, dynamic>> createSavingsGoal(
    String name,
    double target,
    double monthly,
  ) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/savings-goals'),
          headers: headers,
          body: jsonEncode({
            'name': name,
            'saved': 0.0,
            'target': target,
            'monthly': monthly,
          }),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    final decoded = Map<String, dynamic>.from(
      _decodeBody(response.body) as Map,
    );
    await refreshSavingsGoalsCache().catchError(
      (_) => <Map<String, dynamic>>[],
    );
    return decoded;
  }

  static Future<Map<String, dynamic>> contributeToSavingsGoal(
    int goalId, {
    required double amountUsdc,
    required String txHash,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/v1/savings-goals/$goalId/contribute'),
          headers: headers,
          body: jsonEncode({'amount_usdc': amountUsdc, 'tx_hash': txHash}),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }
    final decoded = Map<String, dynamic>.from(
      _decodeBody(response.body) as Map,
    );
    await refreshSavingsGoalsCache().catchError(
      (_) => <Map<String, dynamic>>[],
    );
    return decoded;
  }

  static Future<Map<String, dynamic>> fetchDashboardSummaryRemote() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/dashboard/summary'), headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<Map<String, dynamic>> fetchDashboardSummaryFromApi() async {
    final cached = await LocalDbService.instance.getDashboardSummary();
    try {
      final remote = await fetchDashboardSummaryRemote();
      await LocalDbService.instance.upsertCache('dashboard_summary', remote);
      return remote;
    } catch (e) {
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchCachedDashboardSummary() {
    return LocalDbService.instance.getDashboardSummary();
  }

  static Future<Map<String, dynamic>> refreshDashboardSummaryCache() async {
    final remote = await fetchDashboardSummaryRemote();
    await LocalDbService.instance.upsertCache('dashboard_summary', remote);
    return remote;
  }

  static Future<Map<String, dynamic>> fetchWalletBalanceRemote() async {
    final headers = await _authHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/api/v1/wallet/balance'), headers: headers)
        .timeout(
          _requestTimeout,
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }
    return Map<String, dynamic>.from(_decodeBody(response.body) as Map);
  }

  static Future<Map<String, dynamic>> fetchWalletBalance() async {
    final cached = await LocalDbService.instance.getWalletBalance();
    try {
      final remote = await fetchWalletBalanceRemote();
      await LocalDbService.instance.upsertCache('wallet_balance', remote);
      return remote;
    } catch (e) {
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchCachedWalletBalance() {
    return LocalDbService.instance.getWalletBalance();
  }

  static Future<Map<String, dynamic>> refreshWalletBalanceCache() async {
    final remote = await fetchWalletBalanceRemote();
    await LocalDbService.instance.upsertCache('wallet_balance', remote);
    return remote;
  }

  static Future<DateTime?> getTransactionsLastSyncedAt() async {
    final meta = await LocalDbService.instance.getCachedMap(
      'transactions_meta',
    );
    final raw = meta['last_synced_at']?.toString();
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<bool> isTransactionsCacheStale() async {
    final ts = await getTransactionsLastSyncedAt();
    if (ts == null) return true;
    return DateTime.now().toUtc().difference(ts.toUtc()) >
        const Duration(hours: 12);
  }

  static Future<List<String>> fetchCachedCategories() async {
    final cached = await LocalDbService.instance.getCachedCategories();
    if (cached.isNotEmpty) return cached;
    return const [
      'General',
      'Food',
      'Transport',
      'Entertainment',
      'Shopping',
      'Health',
      'Savings',
      'Income',
    ];
  }

  static bool _isTransientNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection');
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ─── PLACEHOLDER API HELPERS FOR EACH PAGE ─────────────────────────────────

  /// Dashboard placeholder response.
  static Future<Map<String, dynamic>> fetchDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'freeToSpend': 24500, 'variance': 2300, 'monthProgress': 0.26};
  }

  /// Budget overview placeholder response.
  static Future<List<BudgetCategoryExample>> fetchBudgetOverview() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleBudgetCategories;
  }

  /// Category detail placeholder response.
  static Future<Map<String, dynamic>> fetchCategoryDetail() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'category': 'Food',
      'overBy': 3600,
      'planned': 20000,
      'actual': 23600,
    };
  }

  /// Transactions placeholder response.
  static Future<List<TransactionExample>> fetchTransactionsExample() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleTransactions;
  }

  /// Shopping lists placeholder response.
  static Future<List<ShoppingListExample>> fetchShoppingLists() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleShoppingLists;
  }

  /// Shopping list detail placeholder response.
  static Future<ShoppingDetailExample> fetchShoppingDetail() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleShoppingDetail;
  }

  /// Savings goals placeholder response.
  static Future<List<SavingsGoalExample>> fetchSavingsGoals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleSavingsGoals;
  }

  /// Closeout summary placeholder response.
  static Future<CloseoutSummaryExample> fetchCloseoutSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleCloseoutSummary;
  }

  /// Settings placeholder response.
  static Future<SettingsExample> fetchSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return exampleSettings;
  }

  // ─── STATIC EXAMPLE DATA USED BY PAGES ─────────────────────────────────────

  static final List<BudgetCategoryExample> exampleBudgetCategories = [
    BudgetCategoryExample(
      label: '🍔 Food',
      planned: 20000,
      actual: 23600,
      tag: 'need',
      kind: 'need',
    ),
    BudgetCategoryExample(
      label: '🏠 Rent',
      planned: 30000,
      actual: 30000,
      tag: 'need',
      kind: 'need',
    ),
    BudgetCategoryExample(
      label: '🚗 Transport',
      planned: 8000,
      actual: 5200,
      tag: 'need',
      kind: 'need',
    ),
    BudgetCategoryExample(
      label: '🎉 Entertainment',
      planned: 12750,
      actual: 9000,
      tag: 'want',
      kind: 'want',
    ),
    BudgetCategoryExample(
      label: '💰 Savings',
      planned: 17000,
      actual: 17000,
      tag: 'save',
      kind: 'save',
    ),
  ];

  static final List<TransactionExample> exampleTransactions = [
    TransactionExample(
      description: 'Uber – CBD to Westlands',
      emoji: '🚗',
      amount: '-350',
      date: 'Mar 8',
      source: 'auto',
    ),
    TransactionExample(
      description: 'MiniSend – Jane',
      emoji: '💸',
      amount: '+5,000',
      date: 'Mar 7',
      source: 'chain',
    ),
    TransactionExample(
      description: 'Quickmart',
      emoji: '🛒',
      amount: '-1,840',
      date: 'Mar 7',
      source: 'auto',
    ),
    TransactionExample(
      description: 'Netflix',
      emoji: '🎬',
      amount: '-1,100',
      date: 'Mar 5',
      source: 'manual',
    ),
  ];

  static final List<ShoppingListExample> exampleShoppingLists = [
    ShoppingListExample(
      name: 'Weekly Groceries',
      total: 3400,
      budget: 4000,
      items: 8,
      status: 'green',
    ),
    ShoppingListExample(
      name: 'Electronics',
      total: 48000,
      budget: 40000,
      items: 3,
      status: 'red',
    ),
    ShoppingListExample(
      name: 'Household',
      total: 1800,
      budget: 2000,
      items: 5,
      status: 'yellow',
    ),
  ];

  static final ShoppingDetailExample exampleShoppingDetail =
      ShoppingDetailExample(
        title: 'Weekly Groceries',
        total: 1820,
        remaining: 2180,
        items: [
          ShoppingItemExample(name: 'Rice 5kg', qty: 1, price: 500),
          ShoppingItemExample(name: 'Milk x6', qty: 2, price: 200),
          ShoppingItemExample(name: 'Bread', qty: 1, price: 120),
          ShoppingItemExample(name: 'Chicken', qty: 1, price: 650),
          ShoppingItemExample(name: 'Tomatoes 1kg', qty: 2, price: 150),
        ],
      );

  static final List<SavingsGoalExample> exampleSavingsGoals = [
    SavingsGoalExample(
      name: 'Emergency Fund 🛡️',
      saved: 34000,
      target: 100000,
      monthly: 5000,
    ),
    SavingsGoalExample(
      name: 'Vacation ✈️',
      saved: 12000,
      target: 50000,
      monthly: 3000,
    ),
    SavingsGoalExample(
      name: 'Laptop 💻',
      saved: 8000,
      target: 120000,
      monthly: 10000,
    ),
  ];

  static final CloseoutSummaryExample exampleCloseoutSummary =
      CloseoutSummaryExample(
        metrics: [
          CloseoutMetric(
            label: 'Income',
            value: 'KES 85,000',
            color: AppColors.positive,
          ),
          CloseoutMetric(
            label: 'Expenses',
            value: 'KES 67,200',
            color: AppColors.danger,
          ),
          CloseoutMetric(
            label: 'Saved',
            value: 'KES 12,800',
            color: AppColors.positive,
          ),
          CloseoutMetric(
            label: 'Surplus',
            value: 'KES 5,000',
            color: AppColors.warning,
          ),
        ],
        categoryDiffs: const [
          CloseoutCategoryDelta(label: '🍔 Food', delta: '-KES 3,600'),
          CloseoutCategoryDelta(label: '🏠 Rent', delta: 'KES 0'),
          CloseoutCategoryDelta(label: '🚗 Transport', delta: '+KES 2,800'),
        ],
      );

  static final SettingsExample exampleSettings = SettingsExample(
    userName: 'John Kamau',
    email: 'john@example.com',
    walletLabel: '0x3F…9a2c · Base',
    toggles: const [
      SettingsToggle(label: 'Auto-logging (Notifications)', enabled: true),
      SettingsToggle(label: 'Email Parsing', enabled: true),
      SettingsToggle(label: 'Blockchain Sync (Base)', enabled: true),
      SettingsToggle(label: 'AI Categorization', enabled: true),
      SettingsToggle(label: 'Strict Budget Mode', enabled: false),
      SettingsToggle(label: 'AI Insights Feed', enabled: true),
    ],
  );
}

// ─── EXAMPLE DATA MODELS ─────────────────────────────────────────────────────

class BudgetCategoryExample {
  final String label;
  final double planned;
  final double actual;
  final String tag;
  final String kind; // need / want / save

  BudgetCategoryExample({
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
  final String source; // auto / chain / manual

  TransactionExample({
    required this.description,
    required this.emoji,
    required this.amount,
    required this.date,
    required this.source,
  });
}

class ShoppingListExample {
  final String name;
  final double total;
  final double budget;
  final int items;
  final String status; // green / yellow / red

  ShoppingListExample({
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
  final String name;
  final double saved;
  final double target;
  final double monthly;

  SavingsGoalExample({
    required this.name,
    required this.saved,
    required this.target,
    required this.monthly,
  });
}

class CloseoutSummaryExample {
  final List<CloseoutMetric> metrics;
  final List<CloseoutCategoryDelta> categoryDiffs;

  CloseoutSummaryExample({required this.metrics, required this.categoryDiffs});
}

class CloseoutMetric {
  final String label;
  final String value;
  final Color color;

  CloseoutMetric({
    required this.label,
    required this.value,
    required this.color,
  });
}

class CloseoutCategoryDelta {
  final String label;
  final String delta;

  const CloseoutCategoryDelta({required this.label, required this.delta});
}

class SettingsExample {
  final String userName;
  final String email;
  final String walletLabel;
  final List<SettingsToggle> toggles;

  const SettingsExample({
    required this.userName,
    required this.email,
    required this.walletLabel,
    required this.toggles,
  });
}

class SettingsToggle {
  final String label;
  final bool enabled;

  const SettingsToggle({required this.label, required this.enabled});
}
