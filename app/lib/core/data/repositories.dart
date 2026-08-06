// lib/core/data/repositories.dart
//
// KONTRAK LAPISAN DATA — inilah satu-satunya permukaan yang perlu dibaca
// kalau kamu mau menyambungkan backend.
//
// Aturan mainnya:
//
//   screens/  →  core/services/  →  core/data/  →  mock | api
//                (fasad tipis)     (kontrak ini)
//
// Screen tidak pernah menyentuh Dio. Menambah backend = mengisi
// `api_repositories.dart`, bukan menyunting puluhan file layar.
//
// Semua method boleh melempar [ApiException] (lihat `core/network/api_client.dart`).

import '../config/app_config.dart';
import '../../models/models.dart';
import 'api_repositories.dart';
import 'hybrid_repositories.dart';
import 'mock_repositories.dart';

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
}

abstract class BusinessRepository {
  /// `null` kalau pengguna belum punya profil usaha.
  Future<BusinessProfile?> getCurrent();

  Future<BusinessProfile> create(BusinessDraft draft);

  Future<BusinessProfile> update(String id, BusinessDraft draft);
}

abstract class TransactionRepository {
  Future<List<TxCategoryData>> getCategories();

  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    String? businessId,
  });

  Future<TxData?> getTransaction(String id);

  Future<bool> createTransaction(TransactionDraft draft);

  Future<bool> deleteTransaction(String id);
}

/// Metrik yang bisa ditarik riwayat bulanannya untuk grafik KPI.
enum KpiMetric { income, expense, profit, ytd }

abstract class DashboardRepository {
  Future<MonthlySummary> getSummary({int? month, int? year});

  Future<List<RecentTx>> getRecentTransactions({int limit = 5});

  Future<List<TaxDeadline>> getDeadlines({int limit = 3});

  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric);
}

abstract class LibraryRepository {
  Future<List<DocCategory>> getCategories();

  Future<List<Document>> getDocuments({
    String? query,
    String? categoryId,
    String? type,
  });

  Future<Document?> getDocument(String id);
}

// ── Pemilih implementasi ──────────────────────────────────────────────────────

/// Titik tunggal tempat implementasi repository dipilih.
///
/// Mode ditentukan [AppConfig.dataSource], yang berasal dari `--dart-define`:
///
/// * `mock`   — seluruhnya data lokal, nol request jaringan
/// * `api`    — seluruhnya backend, error naik ke UI
/// * `hybrid` — coba backend, jatuh ke mock kalau endpoint belum ada
///
/// Tes boleh menyuntik implementasi palsu lewat setter, lalu memanggil
/// [reset] di `tearDown`.
class Repos {
  Repos._();

  static AuthRepository? _auth;
  static BusinessRepository? _business;
  static TransactionRepository? _transaction;
  static DashboardRepository? _dashboard;
  static LibraryRepository? _library;

  static AuthRepository get auth => _auth ??= switch (AppConfig.dataSource) {
        DataSource.mock => MockAuthRepository(),
        DataSource.api => ApiAuthRepository(),
        DataSource.hybrid =>
          HybridAuthRepository(ApiAuthRepository(), MockAuthRepository()),
      };

  static BusinessRepository get business =>
      _business ??= switch (AppConfig.dataSource) {
        DataSource.mock => MockBusinessRepository(),
        DataSource.api => ApiBusinessRepository(),
        DataSource.hybrid => HybridBusinessRepository(
            ApiBusinessRepository(), MockBusinessRepository()),
      };

  static TransactionRepository get transaction =>
      _transaction ??= switch (AppConfig.dataSource) {
        DataSource.mock => MockTransactionRepository(),
        DataSource.api => ApiTransactionRepository(),
        DataSource.hybrid => HybridTransactionRepository(
            ApiTransactionRepository(), MockTransactionRepository()),
      };

  static DashboardRepository get dashboard =>
      _dashboard ??= switch (AppConfig.dataSource) {
        DataSource.mock => MockDashboardRepository(),
        DataSource.api => ApiDashboardRepository(),
        DataSource.hybrid => HybridDashboardRepository(
            ApiDashboardRepository(), MockDashboardRepository()),
      };

  static LibraryRepository get library =>
      _library ??= switch (AppConfig.dataSource) {
        DataSource.mock => MockLibraryRepository(),
        DataSource.api => ApiLibraryRepository(),
        DataSource.hybrid =>
          HybridLibraryRepository(ApiLibraryRepository(), MockLibraryRepository()),
      };

  // ── Injeksi untuk tes ───────────────────────────────────────────────────────

  static set auth(AuthRepository value) => _auth = value;
  static set business(BusinessRepository value) => _business = value;
  static set transaction(TransactionRepository value) => _transaction = value;
  static set dashboard(DashboardRepository value) => _dashboard = value;
  static set library(LibraryRepository value) => _library = value;

  /// Buang semua instance supaya dibangun ulang dari [AppConfig].
  static void reset() {
    _auth = null;
    _business = null;
    _transaction = null;
    _dashboard = null;
    _library = null;
  }
}
