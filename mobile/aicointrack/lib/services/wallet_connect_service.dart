import 'package:coinbase_wallet_sdk/coinbase_wallet_sdk.dart';
import 'package:coinbase_wallet_sdk/configuration.dart';
import 'package:flutter/foundation.dart';

/// Initialises the Coinbase Wallet SDK (used for Base Wallet sign-in).
///
/// This is NOT WalletConnect — the Coinbase Wallet SDK uses its own
/// deep-link protocol independent of WalletConnect project IDs.
///
/// Call [init] once at app startup (in main.dart) so the SDK relay is
/// ready by the time the user taps "Sign in with Base Wallet".
///
/// Platform configuration:
///   iOS    : host = cbwallet://wsegue  (Coinbase Wallet's registered scheme)
///            callback = aicointrack:// (our app's registered scheme in Info.plist)
///   Android: domain = https://cointrack-nu.vercel.app (HTTPS App Link verified via assetlinks.json)
class WalletConnectService {
  static bool _initialized = false;

  /// Initialise the Coinbase Wallet SDK.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;

    await CoinbaseWalletSDK.shared.configure(
      Configuration(
        ios: IOSConfiguration(
          host: Uri.parse('cbwallet://wsegue'),
          callback: Uri.parse('aicointrack://'),
        ),
        android: AndroidConfiguration(
          domain: Uri.parse('https://cointrack-nu.vercel.app'),
        ),
      ),
    );

    _initialized = true;
    debugPrint('✓ CoinbaseWalletSDK initialized');
  }

  /// True after [init] has completed successfully.
  static bool get isInitialized => _initialized;
}