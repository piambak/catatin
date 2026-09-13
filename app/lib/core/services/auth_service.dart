// lib/core/services/auth_service.dart
//
// Fasad tipis di atas `Repos.auth`. Layar memanggil kelas ini, bukan
// repository, supaya urusan lintas-lapisan (menyimpan token, membersihkan
// sesi, menyelaraskan onboarding, mode demo) tetap di satu tempat.

import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../config/app_config.dart';
import '../data/repositories.dart';
import '../network/api_client.dart';
import '../network/supabase_client.dart';
import 'storage_service.dart';

export '../../models/user_model.dart';

class AuthService {
  AuthService._();

  /// Berbunyi setiap status masuk/keluar berubah.
  ///
  /// Dipasang sebagai `refreshListenable` router supaya penjaga rute dievaluasi
  /// ulang — termasuk saat Supabase mengakhiri sesi dari sisinya sendiri,
  /// ketika tidak ada layar yang sedang memanggil `context.go`.
  static final sessionChanges = _SessionChanges();

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await Repos.auth.register(
      name: name,
      email: email,
      password: password,
    );
    await _persist(auth);
    await _syncBusiness();
    sessionChanges.notify();
    return auth;
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final auth = await Repos.auth.login(email: email, password: password);
    await _persist(auth);
    await _syncBusiness();
    sessionChanges.notify();
    return auth;
  }

  /// Masuk tanpa akun. Seluruh data berasal dari contoh lokal dan tidak ada
  /// request jaringan — apa pun `DATA_SOURCE`-nya.
  static Future<void> enterDemo() async {
    Repos.useDemo(true);
    await Future.wait([
      StorageService.setDemo(true),
      StorageService.saveTokens(
        accessToken: 'demo-token',
        refreshToken: 'demo-refresh',
      ),
      StorageService.saveUserInfo(
        id: 'demo-user-001',
        name: 'Budi Santoso',
        email: 'budi@tokoanda.com',
      ),
      StorageService.setOnboarded(),
    ]);
    sessionChanges.notify();
  }

  static Future<UserModel> me() => Repos.auth.me();

  static Future<void> logout() async {
    if (!Repos.isDemo) {
      try {
        await Repos.auth.logout();
      } on ApiException {
        // Gagal menghubungi backend tidak boleh menahan pengguna tetap masuk:
        // sesi lokal tetap dibersihkan di bawah.
      }
    }
    await StorageService.clearAll();
    Repos.useDemo(false);
    sessionChanges.notify();
  }

  /// Menyiapkan sesi sebelum frame pertama. Dipanggil `main.dart` sesudah
  /// backend diinisialisasi.
  static Future<void> restoreSession() async {
    if (await StorageService.isDemo()) {
      Repos.useDemo(true);
    }
    if (AppConfig.dataSource != DataSource.supabase) return;

    // Penanda "sudah masuk" tanpa sesi Supabase adalah sisa sesi lama: token
    // demo dari build sebelum mode demo punya penanda sendiri, atau sesi yang
    // sudah dicabut. Dibersihkan sekalian dengan onboarding dan business_id
    // miliknya, supaya tidak terbawa ke akun berikutnya.
    if (!Repos.isDemo &&
        !SupabaseBackend.hasSession &&
        await StorageService.isLoggedIn()) {
      await StorageService.clearAll();
    }

    SupabaseBackend.listenSignedOut(() async {
      if (Repos.isDemo) return;
      await StorageService.clearAll();
      sessionChanges.notify();
    });
  }

  static Future<void> _persist(AuthResponse auth) => Future.wait([
        StorageService.saveTokens(
          accessToken: auth.accessToken,
          refreshToken: auth.refreshToken,
        ),
        StorageService.saveUserInfo(
          id: auth.user.id,
          name: auth.user.name,
          email: auth.user.email,
        ),
      ]);

  /// Menyamakan status onboarding dengan profil usaha di backend.
  ///
  /// Pengguna lama yang masuk di perangkat baru langsung ke dashboard; akun
  /// yang belum punya profil — termasuk sesudah akun lain dipakai di perangkat
  /// ini — diarahkan ke onboarding. Best-effort: kegagalan di sini tidak boleh
  /// menggagalkan login yang sudah berhasil.
  static Future<void> _syncBusiness() async {
    try {
      final business = await Repos.business.getCurrent();
      if (business == null) {
        await StorageService.clearBusiness();
      } else {
        await StorageService.setBusinessId(business.id);
        await StorageService.setOnboarded();
      }
    } on ApiException {
      // Status lokal dibiarkan; layar onboarding memuat ulang profilnya sendiri.
    }
  }
}

class _SessionChanges extends ChangeNotifier {
  void notify() => notifyListeners();
}
