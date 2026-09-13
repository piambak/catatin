// lib/core/config/app_config.dart
//
// Satu-satunya tempat konfigurasi lingkungan hidup.
//
// Semua nilai masuk lewat `--dart-define` supaya tidak ada URL/rahasia yang
// ter-hardcode di source dan tiap kontributor bisa menunjuk backend-nya
// sendiri tanpa mengubah file yang di-commit.
//
//   flutter run \
//     --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
//     --dart-define=DATA_SOURCE=hybrid \
//     --dart-define=ENABLE_API_LOG=true
//
//   flutter run \
//     --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
//     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
//     --dart-define=DATA_SOURCE=supabase
//
// Atau pakai file JSON (lihat `dart_define.example.json`):
//
//   flutter run --dart-define-from-file=dart_define.json
//
// Catatan: `String.fromEnvironment` hanya bisa dibaca sebagai `const`, jadi
// semua field di bawah wajib `static const`.

/// Dari mana aplikasi mengambil data.
enum DataSource {
  /// Semua data dari seed lokal. Tidak ada request jaringan sama sekali.
  /// Dipakai untuk demo publik, screenshot, dan tes widget.
  mock,

  /// Semua data dari backend REST. Kegagalan dilempar sebagai [ApiException]
  /// supaya benar-benar kelihatan di UI.
  api,

  /// Coba backend REST dulu, jatuh ke seed lokal kalau endpoint-nya belum ada
  /// atau jaringan mati. Mode transisi saat backend dibangun bertahap.
  hybrid,

  /// Supabase: akun lewat Supabase Auth, data dari Postgres yang dijaga Row
  /// Level Security. Kegagalan dilempar sebagai [ApiException], sama seperti
  /// [api].
  ///
  /// Sengaja tidak punya pasangan hybrid: fallback ke mock akan menutupi login
  /// yang gagal dengan login palsu. Skemanya juga mendarat utuh dalam satu
  /// migrasi, jadi tidak ada keadaan "setengah jadi" yang perlu dijembatani.
  supabase,
}

class AppConfig {
  AppConfig._();

  // ── Nilai mentah dari --dart-define ────────────────────────────────────────

  /// Root URL backend REST, contoh `https://api.catatin.id/api/v1`.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL proyek Supabase, contoh `https://abcdefghijklmnop.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable key proyek Supabase (`sb_publishable_…`).
  ///
  /// Kunci ini MEMANG dirancang publik — ikut ter-compile ke bundel web dan
  /// boleh di-commit. Yang melindungi data adalah Row Level Security di
  /// `supabase/migrations/`, bukan kerahasiaan kunci ini. Secret key
  /// (`sb_secret_…`) tidak pernah boleh masuk ke sini: ia melewati RLS.
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const String _rawDataSource = String.fromEnvironment('DATA_SOURCE');

  /// Cetak request/response HTTP ke konsol. Jangan diaktifkan di rilis publik.
  static const bool enableApiLog = bool.fromEnvironment('ENABLE_API_LOG');

  static const int connectTimeoutMs =
      int.fromEnvironment('API_CONNECT_TIMEOUT_MS', defaultValue: 15000);

  static const int receiveTimeoutMs =
      int.fromEnvironment('API_RECEIVE_TIMEOUT_MS', defaultValue: 15000);

  // ── Turunan ────────────────────────────────────────────────────────────────

  /// Mode yang DIMINTA lewat define, sebelum dicek kelengkapannya.
  ///
  /// Default cerdas: tanpa `DATA_SOURCE`, URL Supabase yang terisi berarti
  /// [DataSource.supabase], URL REST berarti [DataSource.hybrid], dan tanpa
  /// keduanya [DataSource.mock] — jadi `flutter run` polos selalu bisa dipakai
  /// kontributor baru.
  static DataSource get _requested {
    switch (_rawDataSource) {
      case 'mock':
        return DataSource.mock;
      case 'api':
        return DataSource.api;
      case 'hybrid':
        return DataSource.hybrid;
      case 'supabase':
        return DataSource.supabase;
      default:
        if (supabaseUrl.isNotEmpty) return DataSource.supabase;
        return apiBaseUrl.isEmpty ? DataSource.mock : DataSource.hybrid;
    }
  }

  static bool _isComplete(DataSource source) => switch (source) {
        DataSource.mock => true,
        DataSource.api || DataSource.hybrid => apiBaseUrl.isNotEmpty,
        DataSource.supabase =>
          supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty,
      };

  /// Mode yang benar-benar dipakai.
  ///
  /// Kalau konfigurasi wajib mode yang diminta kosong, aplikasi jalan mode
  /// [DataSource.mock] alih-alih menembak URL kosong — dan [configError]
  /// menjelaskan sebabnya.
  static DataSource get dataSource =>
      _isComplete(_requested) ? _requested : DataSource.mock;

  /// True kalau ada mode yang benar-benar memanggil jaringan.
  static bool get usesNetwork => dataSource != DataSource.mock;

  /// Pesan kalau kombinasi define-nya tidak masuk akal — dicetak sekali
  /// saat startup, bukan dilempar, supaya app tetap bisa jalan mode mock.
  static String? get configError {
    final requested = _requested;
    if (_isComplete(requested)) return null;
    return switch (requested) {
      DataSource.supabase =>
        'DATA_SOURCE=supabase butuh SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY, '
            'tapi salah satunya kosong. Aplikasi jalan dengan data mock.',
      _ => 'DATA_SOURCE=${requested.name} butuh API_BASE_URL, tapi kosong. '
          'Aplikasi jalan dengan data mock.',
    };
  }

  /// Ringkasan satu baris untuk log startup.
  static String get summary => switch (dataSource) {
        DataSource.mock => 'sumber data: mock (tanpa backend)',
        DataSource.supabase => 'sumber data: supabase → $supabaseUrl',
        DataSource.api ||
        DataSource.hybrid =>
          'sumber data: ${dataSource.name} → $apiBaseUrl',
      };
}
