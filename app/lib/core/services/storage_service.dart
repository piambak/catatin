// lib/core/services/storage_service.dart
//
// Token disimpan di secure storage (Keychain/Keystore, WebCrypto di web),
// sisanya di SharedPreferences.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class StorageService {
  StorageService._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Token JWT ─────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secure.write(key: StorageKeys.accessToken, value: accessToken),
      _secure.write(key: StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _secure.read(key: StorageKeys.accessToken);

  static Future<String?> getRefreshToken() =>
      _secure.read(key: StorageKeys.refreshToken);

  static Future<void> clearTokens() async {
    await Future.wait([
      _secure.delete(key: StorageKeys.accessToken),
      _secure.delete(key: StorageKeys.refreshToken),
    ]);
  }

  // ── Info pengguna ─────────────────────────────────────────

  static Future<void> saveUserInfo({
    required String id,
    required String name,
    required String email,
    String? businessId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(StorageKeys.userId, id),
      prefs.setString(StorageKeys.userName, name),
      prefs.setString(StorageKeys.userEmail, email),
      if (businessId != null) prefs.setString(StorageKeys.businessId, businessId),
    ]);
  }

  static Future<String?> getUserId() async =>
      (await SharedPreferences.getInstance()).getString(StorageKeys.userId);

  static Future<String?> getUserName() async =>
      (await SharedPreferences.getInstance()).getString(StorageKeys.userName);

  static Future<String?> getUserEmail() async =>
      (await SharedPreferences.getInstance()).getString(StorageKeys.userEmail);

  static Future<String?> getBusinessId() async =>
      (await SharedPreferences.getInstance()).getString(StorageKeys.businessId);

  static Future<void> setBusinessId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.businessId, id);
  }

  // ── Onboarding & sesi ─────────────────────────────────────

  static Future<bool> isOnboarded() async =>
      (await SharedPreferences.getInstance()).getBool(StorageKeys.onboarded) ??
      false;

  static Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboarded, true);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([clearTokens(), prefs.clear()]);
  }
}
