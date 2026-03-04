import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';

/// API service for backend communication and placeholder data for UI pages.
class ApiService {
  // Backend URL is configured in lib/config/constants.dart
  static const String baseUrl = AppConstants.BACKEND_URL;

  /// Register or authenticate user on the backend using Firebase ID token.
  ///
  /// This method retrieves the Firebase ID token from the current user
  /// and sends it to your backend API. Your backend should verify the token
  /// with Firebase Admin SDK and create/update the user in your database.
  static Future<Map<String, dynamic>> registerUserWithBackend() async {
    try {
      final idToken = await AuthService.getIdToken();

      if (idToken == null) {
        throw Exception('No user signed in');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/firebase/register'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Backend registration failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
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

  /// Fetch user profile data from backend.
  static Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final idToken = await AuthService.getIdToken();

      if (idToken == null) {
        throw Exception('No user signed in');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/v1/users/profile'),
            headers: {
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await AuthService.signOut();
        throw Exception('Unauthorized - please sign in again');
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // ─── PLACEHOLDER API HELPERS FOR EACH PAGE ─────────────────────────────────

  /// Dashboard placeholder response.
  static Future<Map<String, dynamic>> fetchDashboardSummary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'freeToSpend': 24500,
      'variance': 2300,
      'monthProgress': 0.26,
    };
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
  static Future<List<TransactionExample>> fetchTransactions() async {
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
      CloseoutMetric(label: 'Income', value: 'Ksh 85,000', color: AppColors.accentGreen),
      CloseoutMetric(label: 'Expenses', value: 'Ksh 67,200', color: AppColors.danger),
      CloseoutMetric(label: 'Saved', value: 'Ksh 12,800', color: AppColors.accentGreen),
      CloseoutMetric(label: 'Surplus', value: 'Ksh 5,000', color: AppColors.warning),
    ],
    categoryDiffs: const [
      CloseoutCategoryDelta(label: '🍔 Food', delta: '-Ksh 3,600'),
      CloseoutCategoryDelta(label: '🏠 Rent', delta: 'Ksh 0'),
      CloseoutCategoryDelta(label: '🚗 Transport', delta: '+Ksh 2,800'),
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

  CloseoutSummaryExample({
    required this.metrics,
    required this.categoryDiffs,
  });
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

  const CloseoutCategoryDelta({
    required this.label,
    required this.delta,
  });
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

  const SettingsToggle({
    required this.label,
    required this.enabled,
  });
}

