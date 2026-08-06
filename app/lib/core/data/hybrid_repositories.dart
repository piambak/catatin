// lib/core/data/hybrid_repositories.dart
//
// Mode transisi: pakai backend kalau bisa, jatuh ke data lokal kalau endpoint-nya
// belum ada atau jaringan mati.
//
// Gunanya saat backend dibangun bertahap — endpoint `/transactions` sudah jadi
// sementara `/dashboard/summary` belum, aplikasi tetap bisa dipakai penuh.
// Kalau semua endpoint sudah siap, pindah ke `DATA_SOURCE=api` supaya
// kegagalan benar-benar kelihatan dan tidak tersamar data contoh.
//
// Hanya [ApiException] yang ditangkap. Bug pemrograman tetap naik ke atas.

import '../../models/models.dart';
import '../network/api_client.dart';
import 'repositories.dart';

Future<T> _orFallback<T>(
  Future<T> Function() primary,
  Future<T> Function() fallback,
) async {
  try {
    return await primary();
  } on ApiException {
    return fallback();
  }
}

// ── Auth ──────────────────────────────────────────────────────────────────────

class HybridAuthRepository implements AuthRepository {
  final AuthRepository api;
  final AuthRepository mock;

  HybridAuthRepository(this.api, this.mock);

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _orFallback(
        () => api.register(name: name, email: email, password: password),
        () => mock.register(name: name, email: email, password: password),
      );

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      _orFallback(
        () => api.login(email: email, password: password),
        () => mock.login(email: email, password: password),
      );

  @override
  Future<UserModel> me() => _orFallback(api.me, mock.me);
}

// ── Profil usaha ──────────────────────────────────────────────────────────────

class HybridBusinessRepository implements BusinessRepository {
  final BusinessRepository api;
  final BusinessRepository mock;

  HybridBusinessRepository(this.api, this.mock);

  @override
  Future<BusinessProfile?> getCurrent() =>
      _orFallback(api.getCurrent, mock.getCurrent);

  /// Selalu tulis ke penyimpanan lokal dulu supaya profil tidak hilang saat
  /// backend menolak — baru kemudian coba kirim ke server.
  @override
  Future<BusinessProfile> create(BusinessDraft draft) async {
    final local = await mock.create(draft);
    try {
      return await api.create(draft);
    } on ApiException {
      return local;
    }
  }

  @override
  Future<BusinessProfile> update(String id, BusinessDraft draft) async {
    final local = await mock.update(id, draft);
    try {
      return await api.update(id, draft);
    } on ApiException {
      return local;
    }
  }
}

// ── Transaksi ─────────────────────────────────────────────────────────────────

class HybridTransactionRepository implements TransactionRepository {
  final TransactionRepository api;
  final TransactionRepository mock;

  HybridTransactionRepository(this.api, this.mock);

  @override
  Future<List<TxCategoryData>> getCategories() =>
      _orFallback(api.getCategories, mock.getCategories);

  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    String? businessId,
  }) =>
      _orFallback(
        () => api.getTransactions(
            month: month, year: year, businessId: businessId),
        () => mock.getTransactions(
            month: month, year: year, businessId: businessId),
      );

  @override
  Future<TxData?> getTransaction(String id) => _orFallback(
        () => api.getTransaction(id),
        () => mock.getTransaction(id),
      );

  @override
  Future<bool> createTransaction(TransactionDraft draft) => _orFallback(
        () => api.createTransaction(draft),
        () => mock.createTransaction(draft),
      );

  @override
  Future<bool> deleteTransaction(String id) => _orFallback(
        () => api.deleteTransaction(id),
        () => mock.deleteTransaction(id),
      );
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class HybridDashboardRepository implements DashboardRepository {
  final DashboardRepository api;
  final DashboardRepository mock;

  HybridDashboardRepository(this.api, this.mock);

  @override
  Future<MonthlySummary> getSummary({int? month, int? year}) => _orFallback(
        () => api.getSummary(month: month, year: year),
        () => mock.getSummary(month: month, year: year),
      );

  @override
  Future<List<RecentTx>> getRecentTransactions({int limit = 5}) => _orFallback(
        () => api.getRecentTransactions(limit: limit),
        () => mock.getRecentTransactions(limit: limit),
      );

  @override
  Future<List<TaxDeadline>> getDeadlines({int limit = 3}) => _orFallback(
        () => api.getDeadlines(limit: limit),
        () => mock.getDeadlines(limit: limit),
      );

  @override
  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric) => _orFallback(
        () => api.getKpiHistory(metric),
        () => mock.getKpiHistory(metric),
      );
}

// ── Pustaka peraturan ─────────────────────────────────────────────────────────

class HybridLibraryRepository implements LibraryRepository {
  final LibraryRepository api;
  final LibraryRepository mock;

  HybridLibraryRepository(this.api, this.mock);

  @override
  Future<List<DocCategory>> getCategories() =>
      _orFallback(api.getCategories, mock.getCategories);

  @override
  Future<List<Document>> getDocuments({
    String? query,
    String? categoryId,
    String? type,
  }) =>
      _orFallback(
        () => api.getDocuments(
            query: query, categoryId: categoryId, type: type),
        () => mock.getDocuments(
            query: query, categoryId: categoryId, type: type),
      );

  @override
  Future<Document?> getDocument(String id) => _orFallback(
        () => api.getDocument(id),
        () => mock.getDocument(id),
      );
}
