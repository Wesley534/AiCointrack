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
class WalletAuthService {
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _buildSiweMessage(String address, String nonce) {
    const domain = 'cointrack.xyz';
    final now = '${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z';
    return '$domain wants you to sign in with your Ethereum account:\n'
        '$address\n\n'
        'Sign in to CoinTrack — AI-powered expense tracker on Base.\n\n'
        'URI: https://$domain\n'
        'Version: 1\n'
        'Chain ID: 8453\n'
        'Nonce: $nonce\n'
        'Issued At: $now';
  }

  /// Connect wallet via Coinbase Wallet SDK, sign SIWE message.
  Future<Map<String, String>> connectAndSign() async {
    debugPrint('=== Step 1: Initiating handshake ===');

    final handshakeResults = await CoinbaseWalletSDK.shared.initiateHandshake([
      const RequestAccounts(),
    ]);

    debugPrint('=== Handshake results: $handshakeResults ===');

    if (handshakeResults.isEmpty) {
      throw Exception('No response from wallet');
    }

    final accountResult = handshakeResults.first;
    if (accountResult.error != null) {
      throw Exception('Wallet error: ${accountResult.error!.message}');
    }

    // Address is on the account object
    final address = accountResult.account?.address;
    if (address == null || address.isEmpty) {
      throw Exception('No address returned from wallet');
    }

    debugPrint('=== Step 2: Got address: $address ===');

    final nonce = _generateNonce();
    final message = _buildSiweMessage(address, nonce);

    debugPrint('=== Step 3: Requesting signature ===');

    final signResults = await CoinbaseWalletSDK.shared.makeRequest(
      Request(actions: [
        PersonalSign(address: address, message: message),
      ]),
    );

    debugPrint('=== Sign results: $signResults ===');

    if (signResults.isEmpty) {
      throw Exception('No signature response');
    }

    if (signResults.first.error != null) {
      throw Exception('Signature failed: ${signResults.first.error!.message}');
    }

    final signature = signResults.first.value!;
    debugPrint('=== Step 4: Got signature: $signature ===');

    return {'address': address, 'message': message, 'signature': signature};
  }

  /// Full login: connect, sign, send to backend, store JWT, optionally sign into Firebase.
  Future<void> loginWithWallet() async {
    final walletData = await connectAndSign();

    final data = await ApiService.walletLogin(
      address: walletData['address']!,
      signature: walletData['signature']!,
      message: walletData['message']!,
    );

    final jwt = data['jwt'] ?? data['accessToken'];
    if (jwt == null) throw Exception('No token in response');
    await TokenService.saveJwt(jwt);

    final firebaseToken = data['firebase_custom_token'] as String?;
    if (firebaseToken != null && firebaseToken.isNotEmpty) {
      try {
        await AuthService.signInWithCustomToken(firebaseToken);
      } catch (e) {
        debugPrint('Firebase custom token sign-in skipped: $e');
      }
    }
  }
}
