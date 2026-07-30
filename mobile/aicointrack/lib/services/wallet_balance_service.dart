import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for reading real-time wallet balances from Base Sepolia network
/// using direct JSON-RPC calls (no backend dependency)
class WalletBalanceService {
  static const String _logTag = '[WalletBalanceService]';

  // Base Sepolia Configuration
  static const int BASE_CHAIN_ID = 84532;
  static const String USDC_CONTRACT = '0x036CbD53842c5426634e7929541eC2318f3dCF7e';

  // USDC has 6 decimals
  static const int USDC_DECIMALS = 6;

  // ETH has 18 decimals
  static const int ETH_DECIMALS = 18;

  // Fallback RPC if env not loaded
  static const String DEFAULT_RPC_URL = 'https://sepolia.base.org';

  late final String _rpcUrl;

  WalletBalanceService() {
    _rpcUrl = dotenv.env['BASE_SEPOLIA_RPC_URL'] ?? DEFAULT_RPC_URL;
    debugPrint('$_logTag initialized with RPC: $_rpcUrl');
  }

  /// Get native ETH balance for a wallet address
  /// Returns balance in ETH (converted from wei)
  Future<double> getEthBalance(String address) async {
    try {
      if (address.isEmpty) {
        debugPrint('$_logTag getEthBalance: empty address provided');
        return 0.0;
      }

      // Ensure address has 0x prefix
      final normalizedAddress = address.startsWith('0x') ? address : '0x$address';

      debugPrint('$_logTag getEthBalance: fetching for $normalizedAddress');

      final response = await http
          .post(
            Uri.parse(_rpcUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_getBalance',
              'params': [normalizedAddress, 'latest'],
              'id': 1,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('RPC request timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception('RPC error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for JSON-RPC error response
      if (data.containsKey('error')) {
        final error = data['error'];
        throw Exception('RPC error: ${error['message'] ?? error['code']}');
      }

      final balanceHex = data['result'] as String? ?? '0x0';
      debugPrint('$_logTag getEthBalance: raw balance hex = $balanceHex');

      // Convert hex string to BigInt (wei), then to ETH
      final balanceWei = BigInt.parse(balanceHex);
      final balanceEth = _weiToEth(balanceWei);

      debugPrint('$_logTag getEthBalance: $normalizedAddress = $balanceEth ETH');
      return balanceEth;
    } catch (e) {
      debugPrint('$_logTag getEthBalance error: $e');
      return 0.0;
    }
  }

  /// Get USDC ERC-20 balance for a wallet address
  /// Returns balance in USDC (converted from contract units with 6 decimals)
  Future<double> getUsdcBalance(String address) async {
    try {
      if (address.isEmpty) {
        debugPrint('$_logTag getUsdcBalance: empty address provided');
        return 0.0;
      }

      // Ensure address has 0x prefix and is lowercase
      final normalizedAddress =
          (address.startsWith('0x') ? address : '0x$address').toLowerCase();

      debugPrint('$_logTag getUsdcBalance: fetching for $normalizedAddress');

      // balanceOf(address) function selector
      const String balanceOfSelector = '0x70a08231';

      // Encode the address parameter (32 bytes, left-padded with zeros)
      final encodedAddress = _encodeAddress(normalizedAddress);
      final data = '$balanceOfSelector$encodedAddress';

      debugPrint('$_logTag getUsdcBalance: encoded call data = $data');

      final response = await http
          .post(
            Uri.parse(_rpcUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'eth_call',
              'params': [
                {
                  'to': USDC_CONTRACT,
                  'data': data,
                },
                'latest',
              ],
              'id': 1,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('RPC request timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception('RPC error: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Check for JSON-RPC error response
      if (responseData.containsKey('error')) {
        final error = responseData['error'];
        throw Exception('RPC error: ${error['message'] ?? error['code']}');
      }

      final resultHex = responseData['result'] as String? ?? '0x0';
      debugPrint('$_logTag getUsdcBalance: raw result hex = $resultHex');

      // Convert hex string to BigInt, then to USDC (6 decimals)
      final balanceUnits = BigInt.parse(resultHex);
      final balanceUsdc = _convertFromDecimals(balanceUnits, USDC_DECIMALS);

      debugPrint('$_logTag getUsdcBalance: $normalizedAddress = $balanceUsdc USDC');
      return balanceUsdc;
    } catch (e) {
      debugPrint('$_logTag getUsdcBalance error: $e');
      return 0.0;
    }
  }

  /// Get both ETH and USDC balances for an address
  /// Returns a map with formatted values for UI display
  Future<Map<String, dynamic>> getWalletBalances(String address) async {
    try {
      if (address.isEmpty) {
        throw Exception('Wallet address cannot be empty');
      }

      debugPrint('$_logTag getWalletBalances: fetching for $address');

      // Fetch both balances in parallel
      final results = await Future.wait([
        getEthBalance(address),
        getUsdcBalance(address),
      ]);

      final ethBalance = results[0] as double;
      final usdcBalance = results[1] as double;

      final balances = {
        'eth': ethBalance,
        'usdc': usdcBalance,
        'eth_formatted': _formatBalance(ethBalance, 4),
        'usdc_formatted': _formatBalance(usdcBalance, 2),
      };

      debugPrint('$_logTag getWalletBalances: $balances');
      return balances;
    } catch (e) {
      debugPrint('$_logTag getWalletBalances error: $e');
      // Return fallback values on error
      return {
        'eth': 0.0,
        'usdc': 0.0,
        'eth_formatted': '0.0000 ETH',
        'usdc_formatted': '0.00 USDC',
        'error': e.toString(),
      };
    }
  }

  /// Convert wei (BigInt) to ETH (double)
  /// 1 ETH = 10^18 wei
  double _weiToEth(BigInt wei) {
    return _convertFromDecimals(wei, ETH_DECIMALS);
  }

  /// Convert token units to human-readable value using decimal places
  double _convertFromDecimals(BigInt value, int decimals) {
    final divisor = BigInt.from(10).pow(decimals);
    final quotient = value ~/ divisor;
    final remainder = value % divisor;

    // Convert to double with proper decimal places
    final decimal = remainder.toDouble() / divisor.toDouble();
    return quotient.toDouble() + decimal;
  }

  /// Format balance for UI display with currency symbol
  String _formatBalance(double balance, int decimalPlaces) {
    return balance.toStringAsFixed(decimalPlaces);
  }

  /// Encode wallet address for balanceOf function call
  /// Removes 0x prefix and left-pads to 32 bytes (64 hex chars)
  String _encodeAddress(String address) {
    // Remove 0x prefix if present
    var cleaned = address.startsWith('0x') ? address.substring(2) : address;
    // Ensure lowercase
    cleaned = cleaned.toLowerCase();
    // Left-pad with zeros to 64 characters (32 bytes)
    return cleaned.padLeft(64, '0');
  }
}
