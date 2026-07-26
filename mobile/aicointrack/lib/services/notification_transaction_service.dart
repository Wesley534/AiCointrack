import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Bridges Android's NotificationListenerService to Dart and parses
/// financial transactions out of notification text with robust patterns
/// specific to M-Pesa and Kenyan banks.
class NotificationTransactionService {
  static const _channel = MethodChannel('com.cointrack/notifications');

  // ── Known financial apps ─────────────────────────────────────────────────
  static const _watchedApps = <String, String>{
    'com.safaricom.mpesa': 'M-Pesa',
    'com.kcbgroup.mobilebanking': 'KCB Bank',
    'ke.co.equity.mobile': 'Equity Bank',
    'com.ncba.ke.android': 'NCBA Bank',
    'com.google.android.gm': 'Gmail',
  };

  // ── Transaction code patterns (M-Pesa, bank refs) ────────────────────────
  // M-Pesa transaction IDs: F4L4XYZ1 (alphanumeric, 6-10 chars)
  // Often at the start of messages or prefixed with "ID:" / "code:"
  static final _txCodePattern = RegExp(
    r'(?:transaction|txn|ref|reference|ID)\s*(?::|no|number)?\s*([A-Z0-9]{6,12})',
    caseSensitive: false,
  );

  // Also matches standalone tx codes at the start of SMS like "F4L4XYZ1 confirmed..."
  static final _standaloneTxCode = RegExp(
    r'^([A-Z0-9]{6,10})\s+(?:confirmed|is\s+your)',
    caseSensitive: false,
  );

  // ── M-Pesa specific patterns ─────────────────────────────────────────────
  // M-Pesa uses both "Receive" and "received", "Send" and "sent"
  // Real format: "F4L4XYZ1 confirmed on 15/1/24 at 10:30AM Receive Ksh 500.00 from NAME"
  static final _mpesaReceiveFrom = RegExp(
    r'(?:receive|received|you\s+have\s+received)\s+'  // action
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)\s*'                // amount
    r'(?:from)\s+([A-Za-z][A-Za-z\s]{1,30}?)'         // sender (accepts lowercase too)
    r'(?:\s+on|\s+at|\.|,|!|$)',                      // boundary
    caseSensitive: false,
  );

  static final _mpesaSendTo = RegExp(
    r'(?:send|sent|you\s+have\s+sent|paid)\s+'         // action
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)\s*'                // amount
    r'(?:to)\s+([A-Za-z][A-Za-z\s]{1,30}?)'           // recipient (accepts lowercase too)
    r'(?:\s+on|\s+at|\.|,|!|$)',                      // boundary
    caseSensitive: false,
  );

  // Shorter patterns for truncated messages
  static final _mpesaReceiveShort = RegExp(
    r'(?:receive|received)\s+'                          // action (accepts both forms)
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)',                    // amount
    caseSensitive: false,
  );

  static final _mpesaSendShort = RegExp(
    r'(?:send|sent|paid)\s+'                            // action (accepts both forms)
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)',                    // amount
    caseSensitive: false,
  );

  // ── Bank-specific patterns ───────────────────────────────────────────────
  static final _bankCredited = RegExp(
    r'(?:credited|deposited)\s+(?:with\s+)?'     // action
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)',             // amount
    caseSensitive: false,
  );

  static final _bankDebited = RegExp(
    r'(?:debited|withdrawn|charged)\s+(?:with\s+)?'  // action
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)',                  // amount
    caseSensitive: false,
  );

  // ── Fallback transaction words detection ─────────────────────────────────
  // These words must appear in the text for it to be considered a transaction.
  static final _mandatoryTxWords = <RegExp>[
    RegExp(r'received', caseSensitive: false),
    RegExp(r'receive', caseSensitive: false),  // M-Pesa uses "Receive"
    RegExp(r'sent', caseSensitive: false),
    RegExp(r'send', caseSensitive: false),     // M-Pesa uses "Send"
    RegExp(r'paid', caseSensitive: false),
    RegExp(r'debited', caseSensitive: false),
    RegExp(r'credited', caseSensitive: false),
    RegExp(r'deposited', caseSensitive: false),
    RegExp(r'withdrawn', caseSensitive: false),
    RegExp(r'transaction', caseSensitive: false),
    RegExp(r'transferred', caseSensitive: false),
    RegExp(r'payment', caseSensitive: false),
    RegExp(r'purchase', caseSensitive: false),
    RegExp(r'withdrawal', caseSensitive: false),
    RegExp(r'charge', caseSensitive: false),
    RegExp(r'balance', caseSensitive: false),  // M-Pesa messages include "New M-PESA balance is..."
  ];

  // ── Counterparty/merchant extraction ─────────────────────────────────────
  // Accepts both uppercase and lowercase starting letters
  static final _counterpartyPattern = RegExp(
    r"(?:to|from|at|by|via)\s+"
    r"([A-Za-z][A-Za-z0-9\s&.'-]{2,40}?)"
    r"(?:\s+(?:Ksh|KES|on\s|Ref|reference|ID|transaction|\.|,|!)|$)",
    caseSensitive: false,
  );

  // ── General amount pattern (last resort) ─────────────────────────────────
  static final _amountPattern = RegExp(
    r'(?:Ksh|KES)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  // ── Ordered patterns: first match wins, gives type + amount + counterparty ──
  static final _orderedPatterns = <_TxPattern>[
    // M-Pesa specific — most precise first
    _TxPattern(_mpesaReceiveFrom, 'income', counterpartyGroup: 2),
    _TxPattern(_mpesaSendTo, 'expense', counterpartyGroup: 2),
    _TxPattern(_mpesaReceiveShort, 'income'),
    _TxPattern(_mpesaSendShort, 'expense'),
    // Bank-specific
    _TxPattern(_bankCredited, 'income'),
    _TxPattern(_bankDebited, 'expense'),
  ];

  // ── Init ─────────────────────────────────────────────────────────────────

  /// Sets up the MethodChannel handler. Call once on app start.
  /// [onTransaction] is invoked whenever a new transaction is parsed.
  static void init({
    required void Function(ParsedNotificationTx tx) onTransaction,
  }) {
    _channel.setMethodCallHandler((call) async {
      try {
        if (call.method != 'onNotification') return;
        final args = Map<String, String>.from(call.arguments as Map);
        final tx = _parse(
          title: args['title'] ?? '',
          text: args['text'] ?? '',
          pkg: args['pkg'] ?? '',
        );
        if (tx != null) {
          debugPrint('[NotificationService] Parsed: ${tx.description} (${tx.amount})');
          onTransaction(tx);
        }
      } catch (e) {
        debugPrint('[NotificationService] Error: $e');
      }
    });
  }

  // ── Permission checks ────────────────────────────────────────────────────

  static Future<bool> isAccessGranted() async {
    return await _channel.invokeMethod<bool>('isNotificationAccessGranted') ?? false;
  }

  static Future<String> testService() async {
    return await _channel.invokeMethod<String>('testNotificationService') ?? 'failed';
  }

  static Future<void> openSettings() async {
    await _channel.invokeMethod('openNotificationSettings');
  }

  // ── SMS Permission ──────────────────────────────────────────────────────

  static Future<bool> hasSmsPermission() async {
    return await _channel.invokeMethod<bool>('hasSmsPermission') ?? false;
  }

  static Future<void> requestSmsPermission() async {
    await _channel.invokeMethod('requestSmsPermission');
  }

  // ── Historical SMS Scanning ──────────────────────────────────────────────

  static Future<List<ParsedNotificationTx>> scanHistoricalMessages({
    required int durationDays,
  }) async {
    debugPrint('[NotificationService] Scanning historical: last $durationDays days');

    final result = await _channel.invokeMethod<List<dynamic>>(
      'scanHistoricalMessages',
      {'durationDays': durationDays},
    );

    if (result == null || result.isEmpty) {
      debugPrint('[NotificationService] No messages from channel');
      return [];
    }

    final transactions = <ParsedNotificationTx>[];
    for (final raw in result) {
      try {
        final entry = Map<String, String>.from(raw as Map);
        // Android side stores body as 'rawText', not 'body'
        final messageBody = entry['rawText'] ?? entry['body'] ?? '';
        final parsed = _parse(
          title: entry['title'] ?? '',
          text: messageBody,
          pkg: entry['sender'] ?? '',
        );
        if (parsed != null) {
          transactions.add(parsed);
        }
      } catch (e) {
        debugPrint('[NotificationService] Parse error: $e');
      }
    }

    debugPrint('[NotificationService] Found ${transactions.length} / ${result.length} messages parsed');
    return transactions;
  }

  // ── Internal parser ──────────────────────────────────────────────────────

  static ParsedNotificationTx? _parse({
    required String title,
    required String text,
    required String pkg,
  }) {
    final body = '$title $text'.trim();
    if (body.isEmpty) return null;

    final lower = body.toLowerCase();
    final sender = _watchedApps[pkg];
    final isKnownSender = sender != null;

    // ── Pre-filter: must have at least one mandatory tx keyword or Ksh/KES with a tx word ──
    final hasTxKeyword = _mandatoryTxWords.any((re) => re.hasMatch(lower));
    final hasMoney = _amountPattern.hasMatch(body);

    if (!hasTxKeyword && !isKnownSender) {
      if (!hasMoney) return null;
      // Has Ksh/KES but no keyword — only process if known sender
      if (pkg.isEmpty) return null;
    }

    // ── Check for transaction code ───────────────────────────────────────
    String? txCode;
    final txCodeMatch = _txCodePattern.firstMatch(body);
    if (txCodeMatch != null) {
      txCode = txCodeMatch.group(1);
    }
    if (txCode == null) {
      // Try standalone code at start of message: "F4L4XYZ1 confirmed..."
      final standaloneMatch = _standaloneTxCode.firstMatch(body);
      if (standaloneMatch != null) {
        txCode = standaloneMatch.group(1);
      }
    }
    final hasTxCode = txCode != null && txCode!.isNotEmpty;

    // ── Try ordered patterns for amount extraction ───────────────────────
    double? amount;
    String? txType;
    String? counterparty;

    for (final pattern in _orderedPatterns) {
      final match = pattern.regex.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amountStr);
        txType = pattern.type;
        if (pattern.counterpartyGroup != null &&
            match.groupCount >= pattern.counterpartyGroup!) {
          counterparty = match.group(pattern.counterpartyGroup!)?.trim();
        }
        break;
      }
    }

    // ── Fallback: generic amount pattern ─────────────────────────────────
    if (amount == null && (hasTxKeyword || hasTxCode || isKnownSender)) {
      final genericMatch = _amountPattern.firstMatch(body);
      if (genericMatch != null) {
        final amountStr = genericMatch.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amountStr);
      }
    }

    if (amount == null || amount <= 0) return null;

    txType ??= _inferType(lower);

    // ── Extract description (counterparty) ──────────────────────────────
    String description;
    if (counterparty != null && counterparty.isNotEmpty) {
      description = counterparty;
    } else {
      final cpMatch = _counterpartyPattern.firstMatch(body);
      if (cpMatch != null) {
        description = cpMatch.group(1)!.trim();
      } else if (txCode != null && txCode.isNotEmpty) {
        description = 'M-PESA Tx $txCode';
      } else {
        description = sender ?? title;
      }
    }

    // Build hash for dedup
    final minuteBucket = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final hashStr =
        '${amount}_${txType}_${txCode ?? ''}_${(txCode ?? '').isNotEmpty ? '' : minuteBucket}';
    final hash = hashStr.hashCode;

    return ParsedNotificationTx(
      amount: amount,
      type: txType,
      description: description,
      source: sender ?? _extractSource(lower),
      rawText: body,
      hash: hash,
      transactionCode: txCode ?? '',
    );
  }

  static String _inferType(String lower) {
    if (lower.contains('receive') ||
        lower.contains('credited') ||
        lower.contains('deposited') ||
        lower.contains('income')) {
      return 'income';
    }
    return 'expense';
  }

  static String _extractSource(String lower) {
    if (lower.contains('mpesa') || lower.contains('safaricom')) return 'M-Pesa';
    if (lower.contains('kcb')) return 'KCB Bank';
    if (lower.contains('equity')) return 'Equity Bank';
    if (lower.contains('ncba')) return 'NCBA Bank';
    return 'Notification';
  }
}

class _TxPattern {
  final RegExp regex;
  final String type;
  final int? counterpartyGroup;

  const _TxPattern(this.regex, this.type, {this.counterpartyGroup});
}

class ParsedNotificationTx {
  final double amount;
  final String type;
  final String description;
  final String source;
  final String rawText;
  final int hash;
  final String transactionCode;

  const ParsedNotificationTx({
    required this.amount,
    required this.type,
    required this.description,
    required this.source,
    required this.rawText,
    required this.hash,
    this.transactionCode = '',
  });
}
