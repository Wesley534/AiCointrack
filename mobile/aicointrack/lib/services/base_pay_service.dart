import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:async';

class BasePayService {
  // Callback scheme for the pay flow (must be registered in app)
  static const String _callbackScheme = 'aicointrackpay';

  // Miniapp pay page on the web (hosted miniapp)
  static const String _payUrlBase = 'https://cointrack-nu.vercel.app/pay';

  /// Opens the miniapp pay page in an in-app browser and returns a map
  /// containing { 'status': 'completed'|'cancelled'|'failed', 'id': ..., 'txHash': ... }
  static Future<Map<String, String>?> startPay({
    required String amount, // USD string like '5.00'
    required String to,
  }) async {
    final url = '$_payUrlBase?amount=${Uri.encodeQueryComponent(amount)}&to=${Uri.encodeQueryComponent(to)}&redirect=$_callbackScheme';
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(preferEphemeral: false),
      );

      // Expected callback: aicointrackpay://pay?status=completed&id=...&txHash=...
      final uri = Uri.parse(result);
      final params = <String, String>{};
      uri.queryParameters.forEach((k, v) {
        params[k] = v;
      });
      return params;
    } catch (e) {
      return null;
    }
  }
}
