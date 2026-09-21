// lib/core/data/repositories.dart
//
// KONTRAK LAPISAN DATA — inilah satu-satunya permukaan yang perlu dibaca
// kalau kamu mau menyambungkan backend.
//
// Aturan mainnya:
//
//   screens/  →  core/services/  →  core/data/  →  mock | api | hybrid | supabase
//                (fasad tipis)     (kontrak ini)
//
// Screen tidak pernah menyentuh Dio maupun Supabase. Menambah backend =
// mengisi satu berkas implementasi (`api_repositories.dart` untuk REST,
// `supabase_repositories.dart` untuk Supabase), bukan menyunting puluhan file
// layar.
//
// Semua method boleh melempar [ApiException] (lihat `core/network/api_client.dart`).

import '../config/app_config.dart';
import '../../models/models.dart';
import '../network/api_client.dart';
import 'api_repositories.dart';
import 'hybrid_repositories.dart';
import 'mock_repositories.dart';
import 'supabase_repositories.dart';

/// Dilempar implementasi yang tidak punya alur OAuth.
const googleSignInUnsupported = ApiException(
  statusCode: 409,
  message: 'Masuk dengan Google hanya tersedia saat tersambung ke Supabase.',
);

// ── Kontrak ───────────────────────────────────────────────────────────────────

abstract class AuthRepository {
  /// Daftar akun baru. Implementasi harus langsung mengembalikan sesi aktif.
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  /// Profil pengguna yang sedang login.
  Future<UserModel> me();

  /// Mengakhiri sesi di sisi backend. Penyimpanan lokal dibersihkan
  /// `AuthService`, bukan di sini.
  Future<void> logout();

  /// Membuka halaman masuk Google. Selesai begitu halaman itu terbuka — sesi
  /// baru tiba saat pengguna kembali ke aplikasi (web: halaman dimuat ulang;
  /// Android: deep link), dan diadopsi `AuthService`.
  Future<void> signInWithGoogle();

  /// Sesi yang sedang dipegang backend, atau `null`. Hanya berarti untuk
  /// backend yang mengelola sesinya sendiri (Supabase).
  Future<AuthResponse?> currentSession();

  /// Cara masuk yang terpasang di akun yang sedang masuk, mis.
  /// `{'google', 'email'}`. `email` berarti akun punya kata sandi.
  Future<Set<String>> signInProviders();

  /// Memasang kata sandi pertama atau menggantinya. Sesudahnya akun yang sama
  /// bisa masuk dengan email + kata sandi, di samping cara yang sudah ada.
  ///
  /// [currentPassword] dikirim saat mengganti kata sandi yang sudah ada.
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  });
}

abstract class BusinessRepository {
  /// `null` kalau pengguna belum punya profil usaha.
  Future<BusinessProfile?> getCurrent();

  Future<BusinessProfile> create(BusinessDraft draft);

  Future<BusinessProfile> update(String id, BusinessDraft draft);
}

abstract class TransactionRepository {
  Future<List<TxCategoryData>> getCategories();

  /// Transaksi terbaru lebih dulu. Tanpa filter apa pun, seluruh transaksi
  /// dikembalikan.
  ///
  /// Filternya dua pasang yang tidak boleh dicampur (lihat
  /// [checkTransactionFilter]): [month]/[year] — [month] tanpa [year] berarti
  /// tahun berjalan — atau rentang [from]/[to] yang inklusif di kedua ujung,
  /// boleh salah satunya saja. Jam pada [from]/[to] diabaikan.
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  });

  Future<TxData?> getTransaction(String id);

  Future<bool> createTransaction(TransactionDraft draft);

  /// Mengganti isi transaksi [id]. Usaha pemilik transaksi tidak ikut pindah.
  Future<bool> updateTransaction(String id, TransactionDraft draft);

  Future<bool> deleteTransaction(String id);

  /// Pemasukan, pengeluaran, HPP, jumlah transaksi, dan omzet YTD per bulan
  /// sepanjang [year] — selalu 12 bulan.
  Future<YearAggregate> getAggregate({required int year});
}

/// Menolak filter [TransactionRepository.getTransactions] yang saling
/// bertentangan, sama dengan balasan 400 `validation_failed` di kontrak REST.
///
/// Dipanggil setiap implementasi sebelum menyentuh data, jadi campuran yang
/// salah gagal di semua mode — bukan hanya saat tersambung backend.
void checkTransactionFilter({
  int? month,
  int? year,
  DateTime? from,
  DateTime? to,
}) {
  if ((from != null || to != null) && (month != null || year != null)) {
    throw ArgumentError('Filter from/to tidak boleh dicampur dengan month/year.');
  }
  if (from != null && to != null && dateOnly(to).isBefore(dateOnly(from))) {
    throw ArgumentError.value(to, 'to', 'harus sama dengan atau setelah from');
  }
}

/// [value] tanpa jam, menit, dan detik.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

abstract class RecurringRepository {
  /// Template aktif lebih dulu, lalu diurutkan `next_date` makin dekat;
  /// template tanpa `next_date` (nonaktif) di paling akhir.
  Future<List<RecurringTemplate>> getTemplates();

  Future<RecurringTemplate> createTemplate(RecurringDraft draft);

  /// Mengganti seluruh isi template [id]. Menolak dengan [ApiException] 409
  /// kalau template itu sudah dihentikan — buat template baru, bukan
  /// menghidupkan yang lama.
  Future<RecurringTemplate> updateTemplate(String id, RecurringDraft draft);

  /// Menghentikan pengulangan template [id]. Template yang sudah nonaktif
  /// dikembalikan apa adanya, tanpa galat.
  Future<RecurringTemplate> stopTemplate(String id);
}

/// Metrik yang bisa ditarik riwayat bulanannya untuk grafik KPI.
enum KpiMetric { income, expense, profit, ytd }

abstract class DashboardRepository {
  Future<MonthlySummary> getSummary({int? month, int? year});

  Future<List<RecentTx>> getRecentTransactions({int limit = 5});

  Future<List<TaxDeadline>> getDeadlines({int limit = 3});

  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric);
}

// ── Pemilih implementasi ──────────────────────────────────────────────────────

/// Titik tunggal tempat implementasi repository dipilih.
///
/// Mode ditentukan [AppConfig.dataSource], yang berasal dari `--dart-define`:
///
/// * `mock`     — seluruhnya data lokal, nol request jaringan
/// * `api`      — seluruhnya backend REST, error naik ke UI
/// * `hybrid`   — coba backend REST, jatuh ke mock kalau endpoint belum ada
/// * `supabase` — seluruhnya Supabase, error naik ke UI
///
/// Selama sesi demo ([useDemo]) keempatnya selalu mock, apa pun modenya.
///
/// Tes boleh menyuntik implementasi palsu lewat setter, lalu memanggil
/// [reset] di `tearDown`.
class Repos {
  Repos._();

  static AuthRepository? _auth;
  static BusinessRepository? _business;
  static TransactionRepository? _transaction;
  static DashboardRepository? _dashboard;
  static RecurringRepository? _recurring;

  static bool _demo = false;

  /// True selama pengguna masuk lewat "Masuk sebagai pengguna demo".
  static bool get isDemo => _demo;

  /// Menyalakan atau mematikan sesi demo.
  ///
  /// Sesi demo selalu memakai data contoh, supaya tombol demo tetap berfungsi
  /// di build yang tersambung backend — termasuk situs publik. Instance lama
  /// dibuang karena getter di bawah menyimpannya dengan `??=`.
  static void useDemo(bool on) {
    _demo = on;
    reset();
  }

  static DataSource get _source => _demo ? DataSource.mock : AppConfig.dataSource;

  static AuthRepository get auth => _auth ??= switch (_source) {
        DataSource.mock => MockAuthRepository(),
        DataSource.api => ApiAuthRepository(),
        DataSource.hybrid =>
          HybridAuthRepository(ApiAuthRepository(), MockAuthRepository()),
        DataSource.supabase => SupabaseAuthRepository(),
      };

  static BusinessRepository get business =>
      _business ??= switch (_source) {
        DataSource.mock => MockBusinessRepository(),
        DataSource.api => ApiBusinessRepository(),
        DataSource.hybrid => HybridBusinessRepository(
            ApiBusinessRepository(), MockBusinessRepository()),
        DataSource.supabase => SupabaseBusinessRepository(),
      };

  static TransactionRepository get transaction =>
      _transaction ??= switch (_source) {
        DataSource.mock => MockTransactionRepository(),
        DataSource.api => ApiTransactionRepository(),
        DataSource.hybrid => HybridTransactionRepository(
            ApiTransactionRepository(), MockTransactionRepository()),
        DataSource.supabase => SupabaseTransactionRepository(),
      };

  static DashboardRepository get dashboard =>
      _dashboard ??= switch (_source) {
        DataSource.mock => MockDashboardRepository(),
        DataSource.api => ApiDashboardRepository(),
        DataSource.hybrid => HybridDashboardRepository(
            ApiDashboardRepository(), MockDashboardRepository()),
        DataSource.supabase => SupabaseDashboardRepository(),
      };

  static RecurringRepository get recurring =>
      _recurring ??= switch (_source) {
        DataSource.mock => MockRecurringRepository(),
        DataSource.api => ApiRecurringRepository(),
        DataSource.hybrid => HybridRecurringRepository(
            ApiRecurringRepository(), MockRecurringRepository()),
        DataSource.supabase => SupabaseRecurringRepository(),
      };

  // ── Injeksi untuk tes ───────────────────────────────────────────────────────

  static set auth(AuthRepository value) => _auth = value;
  static set business(BusinessRepository value) => _business = value;
  static set transaction(TransactionRepository value) => _transaction = value;
  static set dashboard(DashboardRepository value) => _dashboard = value;
  static set recurring(RecurringRepository value) => _recurring = value;

  /// Buang semua instance supaya dibangun ulang dari [AppConfig].
  static void reset() {
    _auth = null;
    _business = null;
    _transaction = null;
    _dashboard = null;
    _recurring = null;
  }
}
