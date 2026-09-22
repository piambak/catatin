// lib/core/data/api_repositories.dart
//
// ► FILE INI YANG KAMU SUNTING SAAT MENYAMBUNGKAN BACKEND REST. ◄
// (Backend Supabase punya berkasnya sendiri: `supabase_repositories.dart`.)
//
// Semua panggilan HTTP aplikasi ada di sini — tidak ada satu pun `Dio` di
// folder `screens/` atau `widgets/`. Path endpoint-nya terkumpul di
// `core/constants/app_constants.dart` (kelas `ApiEndpoints`), dan bentuk
// payload yang diharapkan didokumentasikan di
// `wiki/arsitektur/backend-dan-api.md`.
//
// Kontrak error: setiap method melempar [ApiException] (bukan
// `DioException`) supaya lapisan di atasnya tidak perlu tahu soal Dio.

import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../utils/formatters.dart';
import 'repositories.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

class ApiAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await ApiClient.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      // Backend hanya membuat akun; sesi diambil lewat login.
      return login(email: email, password: password);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<UserModel> me() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.me);
      return UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  /// Kontrak REST belum punya endpoint logout — token cukup dibuang di klien.
  @override
  Future<void> logout() async {}

  /// Kontrak REST belum punya alur OAuth.
  @override
  Future<void> signInWithGoogle() async => throw googleSignInUnsupported;

  /// Sesi REST hanya berupa token di penyimpanan lokal.
  @override
  Future<AuthResponse?> currentSession() async => null;

  /// Kontrak REST hanya mengenal email + kata sandi.
  @override
  Future<Set<String>> signInProviders() async => {'email'};

  /// Kontrak REST belum punya endpoint ganti kata sandi.
  @override
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) async =>
      throw const ApiException(
        statusCode: 409,
        message: 'Mengganti kata sandi belum tersedia.',
      );
}

// ── Profil usaha ──────────────────────────────────────────────────────────────

class ApiBusinessRepository implements BusinessRepository {
  @override
  Future<BusinessProfile?> getCurrent() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.business);
      final list = res.data['profiles'] as List<dynamic>;
      if (list.isEmpty) return null;
      return BusinessProfile.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<BusinessProfile> create(BusinessDraft draft) async {
    try {
      final res =
          await ApiClient.post(ApiEndpoints.business, data: draft.toJson());
      return BusinessProfile.fromJson(
          res.data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<BusinessProfile> update(String id, BusinessDraft draft) async {
    try {
      final res = await ApiClient.patch(
        ApiEndpoints.businessById(id),
        data: draft.toJson(),
      );
      return BusinessProfile.fromJson(
          res.data['profile'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }
}

// ── Transaksi ─────────────────────────────────────────────────────────────────

class ApiTransactionRepository implements TransactionRepository {
  @override
  Future<List<TxCategoryData>> getCategories() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.txCategories);
      return (res.data['categories'] as List)
          .map((e) => TxCategoryData.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  /// Hanya filter yang diisi yang dikirim. Tanpa filter, server mengembalikan
  /// seluruh transaksi — sama dengan mode mock dan Supabase.
  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) async {
    checkTransactionFilter(month: month, year: year, from: from, to: to);
    try {
      final res = await ApiClient.get(ApiEndpoints.transactions, params: {
        'month': ?month,
        'year': ?year,
        if (from != null) 'from': Tanggal.api(from),
        if (to != null) 'to': Tanggal.api(to),
        'business_id': ?businessId,
      });
      return (res.data['transactions'] as List)
          .map((e) => TxData.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<TxData?> getTransaction(String id) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.transactionById(id));
      return TxData.fromJson(res.data['transaction'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<bool> createTransaction(TransactionDraft draft) async {
    try {
      await ApiClient.post(ApiEndpoints.transactions, data: draft.toJson());
      return true;
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<bool> updateTransaction(String id, TransactionDraft draft) async {
    try {
      await ApiClient.patch(
        ApiEndpoints.transactionById(id),
        data: draft.toJson(),
      );
      return true;
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    try {
      await ApiClient.delete(ApiEndpoints.transactionById(id));
      return true;
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<YearAggregate> getAggregate({required int year}) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.transactionsAggregate,
        params: {'year': year},
      );
      return YearAggregate.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }
}

// ── Transaksi berulang ──────────────────────────────────────────────────────

class ApiRecurringRepository implements RecurringRepository {
  @override
  Future<List<RecurringTemplate>> getTemplates() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.recurring);
      return (res.data['templates'] as List)
          .map((e) => RecurringTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<RecurringTemplate> createTemplate(RecurringDraft draft) async {
    try {
      final res =
          await ApiClient.post(ApiEndpoints.recurring, data: draft.toJson());
      return RecurringTemplate.fromJson(
          res.data['template'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<RecurringTemplate> updateTemplate(
    String id,
    RecurringDraft draft,
  ) async {
    try {
      final res = await ApiClient.patch(
        ApiEndpoints.recurringById(id),
        data: draft.toJson(),
      );
      return RecurringTemplate.fromJson(
          res.data['template'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<RecurringTemplate> stopTemplate(String id) async {
    try {
      final res = await ApiClient.post(ApiEndpoints.recurringStop(id));
      return RecurringTemplate.fromJson(
          res.data['template'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class ApiDashboardRepository implements DashboardRepository {
  @override
  Future<MonthlySummary> getSummary({int? month, int? year}) async {
    try {
      final now = DateTime.now();
      final res = await ApiClient.get(ApiEndpoints.dashboardSummary, params: {
        'month': month ?? now.month,
        'year': year ?? now.year,
      });
      return MonthlySummary.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<List<RecentTx>> getRecentTransactions({int limit = 5}) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.transactions,
        params: {'limit': limit},
      );
      return (res.data['transactions'] as List)
          .map((e) => RecentTx.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<List<TaxDeadline>> getDeadlines({int limit = 3}) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.taxCalendar,
        params: {'limit': limit},
      );
      return (res.data['deadlines'] as List)
          .map((e) => TaxDeadline.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric) async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.dashboardKpiHistory,
        params: {'metric': metric.name},
      );
      return (res.data['points'] as List)
          .map((e) => KpiPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }
}
