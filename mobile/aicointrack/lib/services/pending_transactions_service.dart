import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  const PendingTx({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.source,
    required this.category,
    required this.detectedAt,
    required this.rawText,
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
  );
}

// ── Service ───────────────────────────────────────────────────────────────────

class PendingTxService {
  static const _key = 'pending_transactions';

  /// Call once on app start so that transactions written by the native
  /// NotificationService while the app was closed are immediately reflected
  /// in the badge count.
  static Future<void> syncOnStartup() async {
    pendingCountNotifier.value = await count();
  }

  /// Returns all pending transactions, newest first.
  static Future<List<PendingTx>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => PendingTx.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  /// Adds a pending transaction.  Silently skips duplicates (same id prefix).
  static Future<void> add(PendingTx tx) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];

    // Deduplicate by the hash prefix embedded in the id
    final prefix = tx.id.split('_').first;
    if (raw.any((s) {
      final decoded = jsonDecode(s) as Map;
      return (decoded['id'] as String).startsWith(prefix);
    })) {
      return;
    }

    raw.add(jsonEncode(tx.toJson()));
    await prefs.setStringList(_key, raw);
  }

  /// Removes a pending transaction by id.
  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map)['id'] == id);
    await prefs.setStringList(_key, raw);
  }

  /// Returns the current pending count.
  static Future<int> count() async => (await getAll()).length;
}
