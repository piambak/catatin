// lib/core/services/storage_service.dart
//
// Token disimpan di secure storage (Keychain/Keystore, WebCrypto di web),
// sisanya di SharedPreferences.
//
// Mode `supabase`: sesi aslinya dikelola klien Supabase sendiri (di
// SharedPreferences — `localStorage` di web) dan diperbarui otomatis. Token
// di sini hanya salinan penanda "sudah masuk" untuk penjaga rute.

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
    // Berurutan, BUKAN Future.wait. Di web, flutter_secure_storage membuat
    // kunci enkripsinya saat penulisan pertama. Dua penulisan serentak di
    // peramban yang masih bersih masing-masing membuat kunci sendiri, lalu
    // token pertama tak bisa didekripsi lagi (OperationError) — penjaga rute
    // melempar GoException dan login pertama macet di layar masuk.
    await _secure.write(key: StorageKeys.accessToken, value: accessToken);
    await _secure.write(key: StorageKeys.refreshToken, value: refreshToken);
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

  /// Lupakan usaha dan status onboarding — dipakai saat akun yang baru masuk
  /// ternyata belum punya profil usaha, supaya sisa akun lain di perangkat
  /// yang sama tidak ikut terbawa.
  static Future<void> clearBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(StorageKeys.businessId),
      prefs.remove(StorageKeys.onboarded),
    ]);
  }

  // ── Onboarding & sesi ─────────────────────────────────────

  static Future<bool> isOnboarded() async =>
      (await SharedPreferences.getInstance()).getBool(StorageKeys.onboarded) ??
      false;

  static Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboarded, true);
  }

  /// True kalau sesi yang tersimpan adalah sesi demo (data contoh).
  static Future<bool> isDemo() async =>
      (await SharedPreferences.getInstance()).getBool(StorageKeys.demoMode) ??
      false;

  static Future<void> setDemo(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.demoMode, on);
  }

  static Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      // Token yang tidak bisa didekripsi — mis. tersimpan build lama yang
      // masih menulis serentak (lihat saveTokens) — sama saja dengan tidak
      // punya sesi. Lebih baik diminta masuk lagi daripada penjaga rute
      // melempar galat dan aplikasi macet.
      await clearTokens();
      return false;
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([clearTokens(), prefs.clear()]);
  }
}
