import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'token_service.dart';

class SecuritySettingsState {
  const SecuritySettingsState({
    required this.hasPin,
    required this.appLockEnabled,
    required this.biometricEnabled,
    required this.biometricAvailable,
    required this.isLocked,
  });

  final bool hasPin;
  final bool appLockEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final bool isLocked;
}

class LocalAuthLockService {
  LocalAuthLockService._();

  static const _pinHashKey = 'cointrack_pin_hash';
  static const _pinSaltKey = 'cointrack_pin_salt';
  static const _pinLengthKey = 'cointrack_pin_length';

  static const _pinEnabledKey = 'pin_enabled';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _appLockEnabledKey = 'app_lock_enabled';
  static const _pinSetupSkippedKey = 'pin_setup_skipped';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final ValueNotifier<bool> _lockState = ValueNotifier<bool>(false);

  static bool _initialized = false;

  static ValueListenable<bool> get lockStateListenable => _lockState;
  static bool get isLocked => _lockState.value;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshLockState();
  }

  static Future<void> refreshLockState() async {
    final hasSession = await _hasValidSession();
    final hasPin = await isPinConfigured();
    final appLockEnabled = await isAppLockEnabled();

    _lockState.value = hasSession && hasPin && appLockEnabled;
  }

  static Future<bool> _hasValidSession() async {
    final jwt = await TokenService.getJwt();
    if (jwt != null && jwt.isNotEmpty) {
      return true;
    }
    return AuthService.isUserSignedIn();
  }

  static Future<void> markUnlocked() async {
    _lockState.value = false;
  }

  static Future<void> lockIfNeeded() async {
    final hasPin = await isPinConfigured();
    final appLockEnabled = await isAppLockEnabled();
    final hasSession = await _hasValidSession();
    _lockState.value = hasSession && hasPin && appLockEnabled;
  }

  static Future<void> onSessionEnded() async {
    _lockState.value = false;
  }

  static Future<bool> isPinConfigured() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    return (hash?.isNotEmpty ?? false) && (salt?.isNotEmpty ?? false);
  }

  static Future<int?> getPinLength() async {
    final raw = await _secureStorage.read(key: _pinLengthKey);
    return int.tryParse(raw ?? '');
  }

  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  static Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, enabled);
    await refreshLockState();
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final biometrics = await _localAuth.getAvailableBiometrics();
      debugPrint(
        '[LocalAuthLockService] biometric availability supported=$supported canCheck=$canCheck biometrics=$biometrics',
      );

      if (!supported) return false;

      // Some Android OEM builds report an empty biometric list even when
      // biometric auth is configured and can authenticate successfully.
      if (Platform.isAndroid) {
        return canCheck || biometrics.isNotEmpty;
      }

      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint(
        '[LocalAuthLockService] biometric availability check failed: $e',
      );
      return false;
    }
  }

  static Future<SecuritySettingsState> getSecurityState() async {
    return SecuritySettingsState(
      hasPin: await isPinConfigured(),
      appLockEnabled: await isAppLockEnabled(),
      biometricEnabled: await isBiometricEnabled(),
      biometricAvailable: await isBiometricAvailable(),
      isLocked: _lockState.value,
    );
  }

  static Future<void> savePin({
    required String pin,
    required bool enableBiometric,
  }) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinSaltKey, value: salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(
      key: _pinLengthKey,
      value: pin.length.toString(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, true);
    await prefs.setBool(_appLockEnabledKey, true);
    await prefs.setBool(_biometricEnabledKey, enableBiometric);
    await prefs.setBool(_pinSetupSkippedKey, false);

    _lockState.value = false;
  }

  static Future<void> deferPinSetupPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinSetupSkippedKey, true);
  }

  static Future<void> requestPinSetupPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinSetupSkippedKey, false);
  }

  static Future<bool> shouldPromptForPinSetup({
    bool forceAfterLogin = false,
  }) async {
    if (await isPinConfigured()) {
      return false;
    }

    if (forceAfterLogin) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_pinSetupSkippedKey) ?? false);
  }

  static Future<bool> verifyPin(String pin) async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);
    if (hash == null || salt == null) return false;

    final computed = _hashPin(pin, salt);
    final matches = computed == hash;
    if (matches) {
      _lockState.value = false;
    }
    return matches;
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final enabled = await isBiometricEnabled();
      final available = await isBiometricAvailable();
      if (!enabled || !available) {
        return false;
      }

      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock AiCoinTrack',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );

      debugPrint(
        '[LocalAuthLockService] biometric authenticate success=$success',
      );
      if (success) {
        _lockState.value = false;
      }
      return success;
    } catch (e) {
      debugPrint('[LocalAuthLockService] biometric authenticate failed: $e');
      return false;
    }
  }

  static Future<void> clearPinConfiguration() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _secureStorage.delete(key: _pinLengthKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.setBool(_appLockEnabledKey, false);
    await prefs.setBool(_pinSetupSkippedKey, false);

    _lockState.value = false;
  }

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
