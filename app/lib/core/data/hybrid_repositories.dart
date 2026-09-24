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
//
// T-16 & T-24: versi lama menangkap SETIAP [ApiException] lalu jatuh ke mock.
// Dua akibatnya serius:
//   * kata sandi salah → backend 401 → ditangkap → `mock.login()` yang menerima
//     kredensial apa pun → pengguna "masuk" sebagai pengguna demo;
//   * backend MENOLAK transaksi (400/422) → ditulis ke mock in-memory → UI
//     bilang "berhasil" → transaksi hilang saat halaman dimuat ulang.
// Perbaikannya adalah menangkap LEBIH SEDIKIT, bukan menambah penanganan error.

import 'dart:typed_data';

import '../../models/models.dart';
import '../network/api_client.dart';
import 'repositories.dart';

/// Status yang berarti "endpoint ini belum ada atau tidak terjangkau" —
/// satu-satunya alasan sah untuk memakai data lokal.
///
/// `0` = gagal di level jaringan (timeout, DNS, offline), lihat [ApiException].
/// `404`/`501` = endpoint belum dibangun di backend.
///
/// Apa pun di luar daftar ini adalah JAWABAN backend — penolakan kredensial,
/// penolakan validasi, galat server — dan harus sampai ke pengguna apa adanya.
const _statusBolehFallback = {0, 404, 501};

Future<T> _orFallback<T>(
  Future<T> Function() primary,
  Future<T> Function() fallback, {

  /// Disetel `false` untuk operasi yang tidak boleh punya jalur mock sama
  /// sekali — seluruh auth. Lebih baik pengguna melihat galat jaringan
  /// daripada masuk sebagai orang lain.
  bool allowFallback = true,
}) async {
  try {
    return await primary();
  } on ApiException catch (e) {
    if (!allowFallback || !_statusBolehFallback.contains(e.statusCode)) {
      rethrow;
    }
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
  }) => _orFallback(
    () => api.register(name: name, email: email, password: password),
    () => mock.register(name: name, email: email, password: password),
    allowFallback: false,
  );

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) => _orFallback(
    () => api.login(email: email, password: password),
    () => mock.login(email: email, password: password),
    allowFallback: false,
  );

  @override
  Future<UserModel> me() => _orFallback(api.me, mock.me, allowFallback: false);

  @override
  Future<void> logout() =>
      _orFallback(api.logout, mock.logout, allowFallback: false);

  @override
  Future<void> signInWithGoogle() => api.signInWithGoogle();

  @override
  Future<AuthResponse?> currentSession() => api.currentSession();

  @override
  Future<Set<String>> signInProviders() => api.signInProviders();

  @override
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) => api.setPassword(
    newPassword: newPassword,
    currentPassword: currentPassword,
  );
}

// ── Profil usaha ──────────────────────────────────────────────────────────────

class HybridBusinessRepository implements BusinessRepository {
  final BusinessRepository api;
  final BusinessRepository mock;

  HybridBusinessRepository(this.api, this.mock);

  @override
  Future<BusinessProfile?> getCurrent() =>
      _orFallback(api.getCurrent, mock.getCurrent);

  /// Selalu tulis ke penyimpanan lokal dulu supaya profil yang baru diisi tidak
  /// hilang saat backend belum terjangkau — baru kemudian coba kirim ke server.
  ///
  /// Beda dengan transaksi: di sini salinan lokal memang disengaja sebagai
  /// penyangga onboarding. Tapi syarat jatuh ke lokal sekarang sama ketatnya —
  /// kalau backend MENOLAK isinya (400/422), penggunanya harus tahu, bukan
  /// dibiarkan mengira profilnya tersimpan.
  @override
  Future<BusinessProfile> create(BusinessDraft draft) async {
    final local = await mock.create(draft);
    try {
      return await api.create(draft);
    } on ApiException catch (e) {
      if (!_statusBolehFallback.contains(e.statusCode)) rethrow;
      return local;
    }
  }

  @override
  Future<BusinessProfile> update(String id, BusinessDraft draft) async {
    final local = await mock.update(id, draft);
    try {
      return await api.update(id, draft);
    } on ApiException catch (e) {
      if (!_statusBolehFallback.contains(e.statusCode)) rethrow;
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
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) => _orFallback(
    () => api.getTransactions(
      month: month,
      year: year,
      from: from,
      to: to,
      businessId: businessId,
    ),
    () => mock.getTransactions(
      month: month,
      year: year,
      from: from,
      to: to,
      businessId: businessId,
    ),
  );

  @override
  Future<TxData?> getTransaction(String id) =>
      _orFallback(() => api.getTransaction(id), () => mock.getTransaction(id));

  @override
  Future<bool> createTransaction(TransactionDraft draft) => _orFallback(
    () => api.createTransaction(draft),
    () => mock.createTransaction(draft),
  );

  @override
  Future<bool> updateTransaction(String id, TransactionDraft draft) =>
      _orFallback(
        () => api.updateTransaction(id, draft),
        () => mock.updateTransaction(id, draft),
      );

  @override
  Future<bool> deleteTransaction(String id) => _orFallback(
    () => api.deleteTransaction(id),
    () => mock.deleteTransaction(id),
  );

  @override
  Future<YearAggregate> getAggregate({required int year}) => _orFallback(
    () => api.getAggregate(year: year),
    () => mock.getAggregate(year: year),
  );
}

// ── Transaksi berulang ──────────────────────────────────────────────────────

class HybridRecurringRepository implements RecurringRepository {
  final RecurringRepository api;
  final RecurringRepository mock;

  HybridRecurringRepository(this.api, this.mock);

  @override
  Future<List<RecurringTemplate>> getTemplates() =>
      _orFallback(api.getTemplates, mock.getTemplates);

  @override
  Future<RecurringTemplate> createTemplate(RecurringDraft draft) => _orFallback(
    () => api.createTemplate(draft),
    () => mock.createTemplate(draft),
  );

  @override
  Future<RecurringTemplate> updateTemplate(String id, RecurringDraft draft) =>
      _orFallback(
        () => api.updateTemplate(id, draft),
        () => mock.updateTemplate(id, draft),
      );

  @override
  Future<RecurringTemplate> stopTemplate(String id) =>
      _orFallback(() => api.stopTemplate(id), () => mock.stopTemplate(id));
}

// ── Lampiran struk ────────────────────────────────────────────────────────────

class HybridAttachmentRepository implements AttachmentRepository {
  final AttachmentRepository api;
  final AttachmentRepository mock;

  HybridAttachmentRepository(this.api, this.mock);

  @override
  Future<List<TxAttachment>> getAttachments(String transactionId) =>
      _orFallback(
        () => api.getAttachments(transactionId),
        () => mock.getAttachments(transactionId),
      );

  @override
  Future<TxAttachment> uploadAttachment(
    String transactionId, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => _orFallback(
    () => api.uploadAttachment(
      transactionId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    ),
    () => mock.uploadAttachment(
      transactionId,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    ),
  );

  @override
  Future<void> deleteAttachment(String transactionId, String attachmentId) =>
      _orFallback(
        () => api.deleteAttachment(transactionId, attachmentId),
        () => mock.deleteAttachment(transactionId, attachmentId),
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

  @override
  Future<MonthClose> getMonthClose({required int month, required int year}) =>
      _orFallback(
        () => api.getMonthClose(month: month, year: year),
        () => mock.getMonthClose(month: month, year: year),
      );
}

// ── Simulator ─────────────────────────────────────────────────────────────────

class HybridSimulatorRepository implements SimulatorRepository {
  final SimulatorRepository api;
  final SimulatorRepository mock;

  HybridSimulatorRepository(this.api, this.mock);

  @override
  Future<SimulatorInputs> getInputs({int? month, int? year}) => _orFallback(
    () => api.getInputs(month: month, year: year),
    () => mock.getInputs(month: month, year: year),
  );
}
