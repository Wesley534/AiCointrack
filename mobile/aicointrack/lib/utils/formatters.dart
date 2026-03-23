import 'dart:math';
import 'package:intl/intl.dart';

/// Utility formatting helpers used across pages.
class Formatters {
  /// Format an ISO 8601 date string as 'Mar 8'
  static String formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  /// Generate a random mock transaction hash ('0x' + 32 lowercase hex chars).
  static String generateMockTxHash() {
    final rng = Random.secure();
    const hex = '0123456789abcdef';
    final sb = StringBuffer('0x');
    for (int i = 0; i < 32; i++) {
      sb.write(hex[rng.nextInt(16)]);
    }
    return sb.toString();
  }

  /// Format KES currency with thousands separator
  static String formatKes(double amount) {
    return 'KES ${NumberFormat('#,##0', 'en_KE').format(amount)}';
  }
}
