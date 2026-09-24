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

  /// Pesan galat masuk dengan Google yang belum ditampilkan layar masuk.
  static final oauthError = ValueNotifier<String?>(null);

  /// Tombol Google hanya berarti kalau backend-nya Supabase.
  static bool get googleSignInAvailable =>
      AppConfig.dataSource == DataSource.supabase;

  /// Login/daftar email sedang berjalan. Selama itu event `signedIn` dari
  /// Supabase milik alur ini sendiri, jadi pendengar sesi tidak ikut
  /// menyimpan dan menyinkronkan untuk kedua kalinya.
  static bool _signingIn = false;

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _withSigningIn(() async {
        final auth = await Repos.auth.register(
          name: name,
          email: email,
          password: password,
        );
        await _persist(auth);
        await _syncBusiness();
        sessionChanges.notify();
        return auth;
      });

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      _withSigningIn(() async {
        final auth = await Repos.auth.login(email: email, password: password);
        await _persist(auth);
        await _syncBusiness();
        sessionChanges.notify();
        return auth;
      });

  /// Membuka halaman masuk Google. Di web halaman ini ditinggalkan; hasilnya
  /// diadopsi [restoreSession] saat aplikasi dimuat ulang. Di Android hasilnya
  /// tiba lewat pendengar sesi.
  static Future<void> signInWithGoogle() {
    oauthError.value = null;
    _googlePending = true;
    return Repos.auth.signInWithGoogle();
  }

  /// Masuk dengan Google sudah dimulai dan belum berakhir (Android). Galat Auth
  /// lain — mis. refresh token gagal saat offline — tidak boleh tampil sebagai
  /// "Masuk dengan Google gagal".
  static bool _googlePending = false;

  static Future<T> _withSigningIn<T>(Future<T> Function() run) async {
    _signingIn = true;
    try {
      return await run();
    } finally {
      _signingIn = false;
    }
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

  /// Bagian "Cara masuk" di Pengaturan hanya berarti untuk akun Supabase
  /// sungguhan — bukan sesi demo.
  static bool get signInMethodsEditable =>
      googleSignInAvailable && !Repos.isDemo;

  static Future<Set<String>> signInProviders() => Repos.auth.signInProviders();

  static Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) =>
      Repos.auth.setPassword(
        newPassword: newPassword,
        currentPassword: currentPassword,
      );

  static Future<void> logout() async {
    if (!Repos.isDemo) {
      try {
        await Repos.auth.logout();
      } on ApiException {
        // Gagal menghubungi backend tidak boleh menahan pengguna tetap masuk:
        // sesi lokal tetap dibersihkan di bawah.
      }
    }
    await StorageService.clearSession();
    Repos.useDemo(false);
    sessionChanges.notify();
  }

  /// Menyiapkan sesi sebelum frame pertama. Dipanggil `main.dart` sesudah
  /// backend diinisialisasi.
  static Future<void> restoreSession() async {
    // Mode REST: refresh token yang ditolak server mengakhiri sesi dari lapisan
    // jaringan. Dipasang di sini — sebelum request pertama — supaya penjaga
    // rute langsung membawa pengguna ke layar masuk (T-23).
    ApiClient.onSessionEnded = _endSessionFromServer;

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
      await StorageService.clearSession();
    }

    // Kebalikannya: Supabase memegang sesi yang belum dikenal penyimpanan
    // lokal — halaman baru dimuat ulang sebagai kembalian masuk dengan Google.
    if (!Repos.isDemo && SupabaseBackend.hasSession) {
      await _adoptSession();
    }
    oauthError.value = SupabaseBackend.oauthError;

    SupabaseBackend.listenAuthChanges(
      onSignedIn: (_) async {
        _googlePending = false;
        if (Repos.isDemo || _signingIn) return;
        if (await _adoptSession()) sessionChanges.notify();
      },
      onSignedOut: () async {
        if (Repos.isDemo) return;
        await StorageService.clearSession();
        sessionChanges.notify();
      },
      onAuthError: (_) {
        if (!_googlePending || SupabaseBackend.hasSession) return;
        _googlePending = false;
        oauthError.value = 'Masuk dengan Google gagal. Coba lagi.';
      },
    );
  }

  static Future<void> _endSessionFromServer() async {
    if (Repos.isDemo) return;
    await StorageService.clearSession();
    sessionChanges.notify();
  }

  /// Menyalin sesi Supabase ke penyimpanan lokal kalau belum dikenal, lalu
  /// menyelaraskan onboarding. Mengembalikan `true` kalau ada yang berubah.
  ///
  /// Penanda milik akun lain (id berbeda) dibuang dulu beserta onboarding dan
  /// `business_id`-nya, supaya tidak terbawa ke akun Google yang baru masuk.
  static Future<bool> _adoptSession() async {
    final auth = await Repos.auth.currentSession();
    if (auth == null) return false;

    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) {
      if (await StorageService.getUserId() == auth.user.id) return false;
      await StorageService.clearSession();
    }

    await _persist(auth);
    await _syncBusiness();
    return true;
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
