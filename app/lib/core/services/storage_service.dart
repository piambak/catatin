// lib/core/services/storage_service.dart
//
// Token disimpan di secure storage (Keychain/Keystore, WebCrypto di web),
// sisanya di SharedPreferences.
//
// Mode `supabase`: sesi aslinya dikelola klien Supabase sendiri (di
// SharedPreferences — `localStorage` di web) dan diperbarui otomatis. Token
// di sini hanya salinan penanda "sudah masuk" untuk penjaga rute.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class StorageService {
  StorageService._();

  // ── Salinan di memori untuk penjaga rute ──────────────────
  //
  // Penjaga rute membaca status masuk & onboarding di SETIAP navigasi; di web
  // status masuk berarti mendekripsi token lewat WebCrypto. Karena semua
  // penulisan kunci ini lewat kelas ini, salinan di memori selalu bisa
  // diperbarui bersamaan dengan penulisannya (write-through) — tidak pernah
  // basi selama prosesnya sama (T-27). `null` = belum pernah dibaca.
  static bool? _loggedIn;
  static bool? _onboarded;

  /// Lupakan salinan di memori. Untuk tes yang mengganti isi penyimpanan
  /// tiruan di antara kasus.
  @visibleForTesting
  static void resetCache() {
    _loggedIn = null;
    _onboarded = null;
  }

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
    _loggedIn = accessToken.isNotEmpty;
  }

  static Future<String?> getAccessToken() =>
      _secure.read(key: StorageKeys.accessToken);

  static Future<String?> getRefreshToken() =>
      _secure.read(key: StorageKeys.refreshToken);

  static Future<void> clearTokens() async {
    _loggedIn = false;
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
      if (businessId != null)
        prefs.setString(StorageKeys.businessId, businessId),
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
    _onboarded = false;
    await Future.wait([
      prefs.remove(StorageKeys.businessId),
      prefs.remove(StorageKeys.onboarded),
    ]);
  }

  // ── Onboarding & sesi ─────────────────────────────────────

  static Future<bool> isOnboarded() async {
    final cached = _onboarded;
    if (cached != null) return cached;
    final stored =
        (await SharedPreferences.getInstance()).getBool(
          StorageKeys.onboarded,
        ) ??
        false;
    // `??=`, bukan `=`: penulisan yang terjadi selama pembacaan di atas lebih
    // baru dari hasil baca ini dan tidak boleh tertimpa.
    return _onboarded ??= stored;
  }

  static Future<void> setOnboarded() async {
    _onboarded = true;
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
    final cached = _loggedIn;
    if (cached != null) return cached;
    try {
      final token = await getAccessToken();
      // `??=` — lihat catatan di [isOnboarded].
      return _loggedIn ??= token != null && token.isNotEmpty;
    } catch (_) {
      // Token yang tidak bisa didekripsi — mis. tersimpan build lama yang
      // masih menulis serentak (lihat saveTokens) — sama saja dengan tidak
      // punya sesi. Lebih baik diminta masuk lagi daripada penjaga rute
      // melempar galat dan aplikasi macet.
      await clearTokens();
      return false;
    }
  }

  /// Mengakhiri sesi di perangkat ini: token, info pengguna, usaha,
  /// onboarding, penanda demo — dan sisa sesi klien Supabase — dihapus.
  ///
  /// Yang DIPERTAHANKAN hanya preferensi milik perangkat, bukan milik akun:
  /// saat ini tema ([StorageKeys.themeMode]). Dulu fungsi ini `prefs.clear()`
  /// polos (`clearAll`), sehingga setiap keluar atau refresh token yang gagal
  /// ikut mereset tema ke terang (T-23).
  ///
  /// Onboarding dan `business_id` sengaja ikut dihapus: keduanya milik akun,
  /// dan akun berikutnya di perangkat yang sama tidak boleh mewarisinya.
  /// Pengguna yang masuk lagi tidak melihat onboarding — `AuthService`
  /// menyelaraskannya dari profil usaha di backend saat masuk.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final kept = <String, String>{
      for (final key in _deviceKeys)
        if (prefs.getString(key) case final value?) key: value,
    };
    _onboarded = false;
    await Future.wait([clearTokens(), prefs.clear()]);
    for (final entry in kept.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  /// Kunci SharedPreferences yang bertahan melewati [clearSession].
  static const _deviceKeys = [StorageKeys.themeMode];
}
