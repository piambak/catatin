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

  /// Semua data dari backend. Kegagalan dilempar sebagai [ApiException]
  /// supaya benar-benar kelihatan di UI.
  api,

  /// Coba backend dulu, jatuh ke seed lokal kalau endpoint-nya belum ada
  /// atau jaringan mati. Mode transisi saat backend dibangun bertahap.
  hybrid,
}

class AppConfig {
  AppConfig._();

  // ── Nilai mentah dari --dart-define ────────────────────────────────────────

  /// Root URL backend, contoh `https://api.catatin.id/api/v1`.
  /// Kosong berarti aplikasi jalan tanpa backend.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _rawDataSource = String.fromEnvironment('DATA_SOURCE');

  /// Cetak request/response HTTP ke konsol. Jangan diaktifkan di rilis publik.
  static const bool enableApiLog = bool.fromEnvironment('ENABLE_API_LOG');

  static const int connectTimeoutMs =
      int.fromEnvironment('API_CONNECT_TIMEOUT_MS', defaultValue: 15000);

  static const int receiveTimeoutMs =
      int.fromEnvironment('API_RECEIVE_TIMEOUT_MS', defaultValue: 15000);

  // ── Turunan ────────────────────────────────────────────────────────────────

  /// Default cerdas: tanpa `API_BASE_URL` aplikasi otomatis jalan mode [mock],
  /// jadi `flutter run` polos selalu bisa dipakai kontributor baru.
  static DataSource get dataSource {
    switch (_rawDataSource) {
      case 'mock':
        return DataSource.mock;
      case 'api':
        return DataSource.api;
      case 'hybrid':
        return DataSource.hybrid;
      default:
        return apiBaseUrl.isEmpty ? DataSource.mock : DataSource.hybrid;
    }
  }

  /// True kalau ada mode yang benar-benar memanggil jaringan.
  static bool get usesNetwork => dataSource != DataSource.mock;

  /// Pesan kalau kombinasi define-nya tidak masuk akal — dicetak sekali
  /// saat startup, bukan dilempar, supaya app tetap bisa jalan mode mock.
  static String? get configError {
    if (usesNetwork && apiBaseUrl.isEmpty) {
      return 'DATA_SOURCE=$_rawDataSource butuh API_BASE_URL, tapi kosong. '
          'Aplikasi jalan dengan data mock.';
    }
    return null;
  }

  /// Ringkasan satu baris untuk log startup dan layar Pengaturan.
  static String get summary => usesNetwork
      ? 'sumber data: ${dataSource.name} → $apiBaseUrl'
      : 'sumber data: mock (tanpa backend)';
}
