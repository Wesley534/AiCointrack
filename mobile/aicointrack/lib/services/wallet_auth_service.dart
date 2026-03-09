import 'dart:async';
import 'dart:math';
import 'package:coinbase_wallet_sdk/coinbase_wallet_sdk.dart';
import 'package:coinbase_wallet_sdk/eth_web3_rpc.dart';
import 'package:coinbase_wallet_sdk/request.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'token_service.dart';

/// Handles "Sign in with Base Wallet" via Coinbase Wallet SDK + SIWE.
///
/// Flow:
///   1. initiateHandshake  → opens Coinbase/Base Wallet app, gets address
///   2. personal_sign      → wallet signs a SIWE message
///   3. POST /auth/wallet  → backend verifies SIWE, returns JWT + optional firebase_custom_token
///   4. (optional) signInWithCustomToken → signs into Firebase so auth stream emits true
class WalletAuthService {
  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Builds a EIP-4361 (SIWE) message.
  /// Chain ID 8453 = Base mainnet.
  String _buildSiweMessage(String address, String nonce) {
    const domain = 'cointrack.xyz';
    final now = '${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z';
    return '$domain wants you to sign in with your Ethereum account:\n'
        '$address\n\n'
        'Sign in to AiCoinTrack — AI-powered expense tracker on Base.\n\n'
        'URI: https://$domain\n'
        'Version: 1\n'
        'Chain ID: 8453\n'
        'Nonce: $nonce\n'
        'Issued At: $now';
  }

  // ─── Step 1 + 2: Connect wallet and sign SIWE message ─────────────────────

  /// Opens the Base/Coinbase Wallet app via deep link, requests accounts,
  /// then requests a personal_sign of a SIWE message.
  ///
  /// Returns a map with keys: address, message, signature.
  /// Throws an [Exception] on any failure.
  Future<Map<String, String>> connectAndSign() async {
    // Reset any stale session first
    await CoinbaseWalletSDK.shared.resetSession();

    debugPrint('[WalletAuth] Step 1: Initiating handshake...');

    final handshakeResults = await CoinbaseWalletSDK.shared.initiateHandshake([
      const RequestAccounts(),
    ]);

    debugPrint('[WalletAuth] Handshake results: $handshakeResults');

    if (handshakeResults.isEmpty) {
      throw Exception('No response from wallet — is Coinbase Wallet installed?');
    }

    final accountResult = handshakeResults.first;
    if (accountResult.error != null) {
      throw Exception('Wallet error: ${accountResult.error!.message}');
    }

    final address = accountResult.account?.address;
    if (address == null || address.isEmpty) {
      throw Exception('No wallet address returned.');
    }

    debugPrint('[WalletAuth] Step 2: Got address: $address');

    final nonce = _generateNonce();
    final message = _buildSiweMessage(address, nonce);

    debugPrint('[WalletAuth] Step 3: Requesting signature...');

    final signResults = await CoinbaseWalletSDK.shared.makeRequest(
      Request(actions: [
        PersonalSign(address: address, message: message),
      ]),
    );

    debugPrint('[WalletAuth] Sign results: $signResults');

    if (signResults.isEmpty) {
      throw Exception('No signature response from wallet.');
    }

    if (signResults.first.error != null) {
      throw Exception('Signature failed: ${signResults.first.error!.message}');
    }

    final signature = signResults.first.value;
    if (signature == null || signature.isEmpty) {
      throw Exception('Empty signature returned from wallet.');
    }

    debugPrint('[WalletAuth] Step 4: Got signature: $signature');

    return {
      'address': address,
      'message': message,
      'signature': signature,
    };
  }

  // ─── Full login flow ───────────────────────────────────────────────────────

  /// Full Base Wallet login:
  ///   connectAndSign → POST /auth/wallet → save JWT → optional Firebase custom token sign-in
  ///
  /// After this method returns successfully:
  ///   - JWT is stored in SharedPreferences via [TokenService]
  ///   - If the backend returned a firebase_custom_token, the user is also signed
  ///     into Firebase so [AuthService.appAuthStateChanges()] emits true
  ///
  /// Throws on any failure so the caller can surface the error in the UI.
  Future<void> loginWithWallet() async {
    // Step 1 & 2: open wallet app, get address + signature
    final walletData = await connectAndSign();

    debugPrint('[WalletAuth] Step 5: Sending SIWE data to backend...');

    // Step 3: send to backend for SIWE verification
    final data = await ApiService.walletLogin(
      address: walletData['address']!,
      signature: walletData['signature']!,
      message: walletData['message']!,
    );

    // Step 4: persist JWT (ApiService.walletLogin already does this, but be safe)
    final jwt = data['jwt'] ?? data['accessToken'];
    if (jwt == null) {
      throw Exception('Backend did not return a JWT token.');
    }
    await TokenService.saveJwt(jwt as String);

    debugPrint('[WalletAuth] ✓ JWT saved.');

    // Step 5 (optional): sign into Firebase with custom token so the
    // Firebase auth stream also becomes authenticated. The backend only
    // returns this when it has a service account configured.
    final firebaseToken = data['firebase_custom_token'] as String?;
    if (firebaseToken != null && firebaseToken.isNotEmpty) {
      try {
        await AuthService.signInWithCustomToken(firebaseToken);
        debugPrint('[WalletAuth] ✓ Firebase custom token sign-in successful.');
      } catch (e) {
        // Non-fatal — the app auth stream falls back to the JWT check.
        debugPrint('[WalletAuth] Firebase custom token sign-in skipped: $e');
      }
    } else {
      debugPrint(
        '[WalletAuth] No firebase_custom_token in response — '
        'auth stream will use JWT fallback.',
      );
    }
  }
}