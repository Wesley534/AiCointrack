import 'package:coinbase_wallet_sdk/coinbase_wallet_sdk.dart';
import 'package:coinbase_wallet_sdk/configuration.dart';
import 'package:flutter/foundation.dart';

class WalletConnectService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await CoinbaseWalletSDK.shared.configure(
      Configuration(
        ios: IOSConfiguration(
          host: Uri.parse('cbwallet://wsegue'),
          callback: Uri.parse('aicointrack://'),
        ),
        android: AndroidConfiguration(
          domain: Uri.parse('aicointrack://'),
        ),
      ),
    );

    _initialized = true;
    debugPrint('✓ CoinbaseWalletSDK initialized');
  }

  static bool get isInitialized => _initialized;
}
