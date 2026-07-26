import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global notifier so any widget can reactively show the pending count
/// without needing a Provider or state-management package.
final pendingCountNotifier = ValueNotifier<int>(0);

// ── Model ──────────────────────────────────────────────────────────────────────

class PendingTx {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String description;
  final String source;
  final String category;
  final DateTime detectedAt;
  final String rawText;
  final String transactionCode;

  const PendingTx({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.source,
    required this.category,
    required this.detectedAt,
    required this.rawText,
    this.transactionCode = '',
  });

  PendingTx copyWith({
    double? amount,
    String? type,
    String? description,
    String? category,
  }) => PendingTx(
    id: id,
    source: source,
    detectedAt: detectedAt,
    rawText: rawText,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    description: description ?? this.description,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'source': source,
    'category': category,
    'detectedAt': detectedAt.toIso8601String(),
    'rawText': rawText,
    'transactionCode': transactionCode,
  };

  factory PendingTx.fromJson(Map<String, dynamic> j) => PendingTx(
    id: j['id'] as String,
    amount: (j['amount'] as num).toDouble(),
    type: j['type'] as String,
    description: j['description'] as String,
    source: j['source'] as String,
    category: j['category'] as String,
    detectedAt: DateTime.parse(j['detectedAt'] as String),
    rawText: j['rawText'] as String,
    transactionCode: (j['transactionCode'] as String?) ?? '',
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class PendingTxService {
  static const _key = 'flutter.pending_transactions';

  static bool _isLikelyDuplicate(PendingTx existing, PendingTx incoming) {
    final samePrefix = existing.id.split('_').first == incoming.id.split('_').first;
    if (samePrefix) return true;

    final timeDelta = existing.detectedAt.difference(incoming.detectedAt).inSeconds.abs();
    final nearInTime = timeDelta <= 120;
    final sameCore =
        existing.amount == incoming.amount &&
        existing.description.toLowerCase() == incoming.description.toLowerCase() &&
        existing.source.toLowerCase() == incoming.source.toLowerCase();

    if (nearInTime && sameCore) return true;

    if (nearInTime &&
        existing.rawText.trim().toLowerCase() == incoming.rawText.trim().toLowerCase()) {
      return true;
    }

    return false;
  }

  /// Call once on app start so that transactions written by the native
  /// NotificationService while the app was closed are immediately reflected
  /// in the badge count.
  static Future<void> syncOnStartup() async {
    try {
      // First, ask native side for any transactions written while Flutter was not running.
      try {
        final channel = MethodChannel('com.cointrack/notifications');
        final dynamic raw = await channel.invokeMethod('getPendingTransactions');
        debugPrint('[PendingTxService] Native getPendingTransactions rawType=${raw.runtimeType}');
        if (raw is List && raw.isNotEmpty) {
          debugPrint('[PendingTxService] Native pending payload count=${raw.length}');
          for (final entry in raw) {
            try {
              final Map<String, dynamic> j = entry is String ? jsonDecode(entry) as Map<String, dynamic> : entry as Map<String, dynamic>;
              final tx = PendingTx.fromJson(j);
              debugPrint('[PendingTxService] Importing native pending tx id=${tx.id} source=${tx.source} amount=${tx.amount}');
              await add(tx);
            } catch (e) {
              debugPrint('[PendingTxService] Failed to parse native pending entry type=${entry.runtimeType}: $e');
            }
          }
        } else {
          debugPrint('[PendingTxService] Native pending payload empty or not a List');
        }
      } catch (e) {
        debugPrint('[PendingTxService] No native pending transactions or channel unavailable: $e');
      }

      pendingCountNotifier.value = await count();
      debugPrint('[PendingTxService] Synced ${pendingCountNotifier.value} pending transactions');
    } catch (e) {
      debugPrint('[PendingTxService] Error syncing pending transactions: $e');
      pendingCountNotifier.value = 0;
    }
  }

  /// Returns all pending transactions, newest first.
  static Future<List<PendingTx>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
      final dynamic rawValue = prefs.get(_key);
      if (rawValue == null) return [];

      // Normalize to a List<dynamic> regardless of storage format
      List<dynamic> entries = [];
      try {
        if (rawValue is String) {
          if (rawValue.isEmpty) return [];
          entries = jsonDecode(rawValue) as List<dynamic>;
        } else if (rawValue is List) {
          entries = rawValue.cast<dynamic>();
        } else {
          debugPrint('[PendingTxService] Unsupported prefs type for $_key: ${rawValue.runtimeType}');
          return [];
        }

        final items = entries
            .map((e) => e is String ? jsonDecode(e) as Map<String, dynamic> : e as Map<String, dynamic>)
            .map((m) => PendingTx.fromJson(m))
            .toList();
        items.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        return items;
      } catch (e) {
        debugPrint('[PendingTxService] Failed to parse pending transactions: $e');
        return [];
    }
  }

  /// Adds a pending transaction.  Silently skips duplicates (same id prefix).
  static Future<void> add(PendingTx tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await getAll();
      for (final item in existing) {
        if (_isLikelyDuplicate(item, tx)) {
          debugPrint(
            '[PendingTxService] Skipping duplicate transaction id=${tx.id} (matched existing id=${item.id})',
          );
          return;
        }
      }

      final list = existing.map((e) => jsonEncode(e.toJson())).toList();
      list.add(jsonEncode(tx.toJson()));
      await prefs.setString(_key, jsonEncode(list));
      debugPrint('[PendingTxService] Added transaction: ${tx.description} (${tx.amount})');
      pendingCountNotifier.value = await count();
    } catch (e) {
      debugPrint('[PendingTxService] Error adding transaction: $e');
    }
  }

  /// Removes a pending transaction by id.
  static Future<void> remove(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawValue = prefs.get(_key);
      if (rawValue == null) return;

      List<dynamic> list;
      if (rawValue is String && rawValue.isNotEmpty) {
        list = jsonDecode(rawValue) as List<dynamic>;
      } else if (rawValue is List) {
        list = rawValue.cast<dynamic>();
      } else {
        return;
      }

      final initialCount = list.length;
      list.removeWhere((entry) {
        final obj = entry is String ? jsonDecode(entry) as Map<String, dynamic> : entry as Map<String, dynamic>;
        return obj['id'] == id;
      });

      await prefs.setString(_key, jsonEncode(list));
      debugPrint('[PendingTxService] Removed transaction: $id (${initialCount - list.length} removed)');
      pendingCountNotifier.value = await count();
    } catch (e) {
      debugPrint('[PendingTxService] Error removing transaction: $e');
    }
  }

  /// Returns the current pending count.
  static Future<int> count() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dynamic rawValue = prefs.get(_key);
      if (rawValue == null) return 0;
      try {
        if (rawValue is String) {
          final list = jsonDecode(rawValue) as List<dynamic>;
          final count = list.length;
          debugPrint('[PendingTxService] Current pending count: $count');
          return count;
        } else if (rawValue is List) {
          final count = rawValue.length;
          debugPrint('[PendingTxService] Current pending count: $count');
          return count;
        } else {
          return 0;
        }
      } catch (e) {
        debugPrint('[PendingTxService] Failed to parse pending transactions JSON: $e');
        return 0;
      }
    } catch (e) {
      debugPrint('[PendingTxService] Error counting transactions: $e');
      return 0;
    }
  }
}
