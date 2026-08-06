// lib/core/data/api_repositories.dart
//
// ► FILE INI YANG KAMU SUNTING SAAT MENYAMBUNGKAN BACKEND. ◄
//
// Semua panggilan HTTP aplikasi ada di sini — tidak ada satu pun `Dio` di
// folder `screens/` atau `widgets/`. Path endpoint-nya terkumpul di
// `core/constants/app_constants.dart` (kelas `ApiEndpoints`), dan bentuk
// payload yang diharapkan didokumentasikan di `docs/BACKEND.md`.
//
// Kontrak error: setiap method melempar [ApiException] (bukan
// `DioException`) supaya lapisan di atasnya tidak perlu tahu soal Dio.

import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';
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

  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    String? businessId,
  }) async {
    try {
      final now = DateTime.now();
      final res = await ApiClient.get(ApiEndpoints.transactions, params: {
        'month': month ?? now.month,
        'year': year ?? now.year,
        if (businessId != null) 'business_id': businessId,
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
  Future<bool> deleteTransaction(String id) async {
    try {
      await ApiClient.delete(ApiEndpoints.transactionById(id));
      return true;
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

// ── Pustaka peraturan ─────────────────────────────────────────────────────────

class ApiLibraryRepository implements LibraryRepository {
  @override
  Future<List<DocCategory>> getCategories() async {
    try {
      final res = await ApiClient.get(ApiEndpoints.docCategories);
      return (res.data['categories'] as List)
          .map((e) => DocCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<List<Document>> getDocuments({
    String? query,
    String? categoryId,
    String? type,
  }) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.documents, params: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (categoryId != null) 'category': categoryId,
        if (type != null) 'type': type,
      });
      return (res.data['documents'] as List)
          .map((e) => Document.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw apiException(e);
    }
  }

  @override
  Future<Document?> getDocument(String id) async {
    try {
      final res = await ApiClient.get(ApiEndpoints.documentById(id));
      return Document.fromJson(res.data['document'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw apiException(e);
    }
  }
}
