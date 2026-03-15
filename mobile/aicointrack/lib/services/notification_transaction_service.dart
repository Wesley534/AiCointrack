import 'package:flutter/services.dart';

/// Bridges Android's NotificationListenerService to Dart and parses
/// financial transactions out of notification text.
class NotificationTransactionService {
  static const _channel = MethodChannel('com.cointrack/notifications');

  // Ordered map: first matching pattern wins.  Value is the tx type, or null
  // to fall back to keyword-based inference.
  static final _patterns = <RegExp, String?>{
    RegExp(r'received\s+Ksh\s*([\d,]+\.?\d*)', caseSensitive: false): 'income',
    RegExp(r'(?:sent|paid)\s+Ksh\s*([\d,]+\.?\d*)', caseSensitive: false):
        'expense',
    RegExp(r'debited\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)', caseSensitive: false):
        'expense',
    RegExp(r'credited\s+(?:Ksh|KES)\s*([\d,]+\.?\d*)', caseSensitive: false):
        'income',
    RegExp(r'(?:Ksh|KES)\s*([\d,]+\.?\d*)', caseSensitive: false): null,
  };

  /// Sets up the MethodChannel handler.  Call once on app start (no context
  /// needed).  [onTransaction] is invoked whenever a new transaction is parsed.
  static void init({
    required void Function(ParsedNotificationTx tx) onTransaction,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onNotification') return;
      final args = Map<String, String>.from(call.arguments as Map);
      final tx = _parse(
        title: args['title'] ?? '',
        text: args['text'] ?? '',
        pkg: args['pkg'] ?? '',
      );
      if (tx != null) onTransaction(tx);
    });
  }

  /// Returns true if the system has granted notification listener access.
  static Future<bool> isAccessGranted() async {
    return await _channel.invokeMethod<bool>('isNotificationAccessGranted') ??
        false;
  }

  /// Opens the Android notification listener settings screen.
  static Future<void> openSettings() async {
    await _channel.invokeMethod('openNotificationSettings');
  }

  // ── Internal parser ────────────────────────────────────────────────────────

  static ParsedNotificationTx? _parse({
    required String title,
    required String text,
    required String pkg,
  }) {
    final body = '$title $text';
    final lower = body.toLowerCase();

    final moneyWords = [
      'ksh',
      'kes',
      'received',
      'debited',
      'credited',
      'sent',
      'paid',
      'payment',
    ];
    if (!moneyWords.any((w) => lower.contains(w))) return null;

    double? amount;
    String? txType;

    for (final entry in _patterns.entries) {
      final match = entry.key.firstMatch(body);
      if (match != null) {
        amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
        txType = entry.value;
        break;
      }
    }
    if (amount == null || amount <= 0) return null;

    txType ??=
        lower.contains('received') || lower.contains('credited')
            ? 'income'
            : 'expense';

    final merchantMatch = RegExp(
      r'(?:to|from|at|by)\s+([A-Z][A-Za-z0-9\s&]{2,30}?)(?:\s+(?:Ksh|KES|on\s|Ref|via|\.|,)|$)',
    ).firstMatch(body);
    final description =
        merchantMatch?.group(1)?.trim() ?? _appName(pkg) ?? title;

    // Bucket to the current minute so identical rapid notifications dedup
    final minuteBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final hash = '${amount}_${txType}_$minuteBucket'.hashCode;

    return ParsedNotificationTx(
      amount: amount,
      type: txType,
      description: description,
      source: _appName(pkg) ?? 'Notification',
      rawText: body,
      hash: hash,
    );
  }

  static String? _appName(String pkg) =>
      const {
        'com.safaricom.mpesa': 'M-Pesa',
        'com.kcbgroup.mobilebanking': 'KCB Bank',
        'ke.co.equity.mobile': 'Equity Bank',
        'com.ncba.ke.android': 'NCBA Bank',
        'com.google.android.gm': 'Gmail',
      }[pkg];
}

/// Parsed result from a notification.
class ParsedNotificationTx {
  final double amount;
  final String type; // 'income' | 'expense'
  final String description;
  final String source;
  final String rawText;
  final int hash;

  const ParsedNotificationTx({
    required this.amount,
    required this.type,
    required this.description,
    required this.source,
    required this.rawText,
    required this.hash,
  });
}
