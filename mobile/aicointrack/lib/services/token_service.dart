import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for the backend JWT.
///
/// JWTs are stored in secure storage. A one-time migration path keeps
/// existing signed-in users working by moving any legacy SharedPreferences JWT
/// into secure storage the first time it is read.
class TokenService {
  static const _jwtKey = 'cointrack_jwt';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveJwt(String jwt) async {
    await _secureStorage.write(key: _jwtKey, value: jwt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
  }

  static Future<String?> getJwt() async {
    final secureJwt = await _secureStorage.read(key: _jwtKey);
    if (secureJwt != null && secureJwt.isNotEmpty) {
      return secureJwt;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyJwt = prefs.getString(_jwtKey);
    if (legacyJwt != null && legacyJwt.isNotEmpty) {
      debugPrint('[TokenService] Migrating legacy JWT from SharedPreferences');
      await _secureStorage.write(key: _jwtKey, value: legacyJwt);
      await prefs.remove(_jwtKey);
      return legacyJwt;
    }

    return null;
  }

  static Future<void> clearJwt() async {
    await _secureStorage.delete(key: _jwtKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
  }
}
