// lib/core/data/mock_repositories.dart
//
// Implementasi repository tanpa jaringan. Dipakai:
//
// * demo publik di GitHub Pages (tidak ada backend yang tayang),
// * `flutter run` polos oleh kontributor baru,
// * tes widget yang tidak boleh menyentuh HTTP.
//
// Datanya diambil dari `mock_data.dart`. Perubahan (tambah/hapus transaksi,
// simpan profil usaha) disimpan di memori/SharedPreferences supaya alur
// aplikasi tetap terasa nyata dalam satu sesi.

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import 'mock_data.dart';
import 'repositories.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(MockData.latency);
    final base = MockData.demoSession;
    return AuthResponse(
      accessToken: base.accessToken,
      refreshToken: base.refreshToken,
      user: UserModel(
        id: base.user.id,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(MockData.latency);
    final base = MockData.demoSession;
    return AuthResponse(
      accessToken: base.accessToken,
      refreshToken: base.refreshToken,
      user: UserModel(
        id: base.user.id,
        name: base.user.name,
        email: email,
        createdAt: base.user.createdAt,
      ),
    );
  }

  @override
  Future<UserModel> me() async {
    await Future.delayed(MockData.latency);
    return MockData.demoUser;
  }
}

// ── Profil usaha ──────────────────────────────────────────────────────────────

/// Menyimpan profil usaha di SharedPreferences supaya tetap ada setelah
/// aplikasi ditutup — perilaku ini juga dipakai sebagai cache offline oleh
/// mode `hybrid`.
class MockBusinessRepository implements BusinessRepository {
  static const _kName = 'biz_name';
  static const _kType = 'biz_type';
  static const _kOwner = 'biz_owner';
  static const _kNpwp = 'biz_npwp';
  static const _kPkp = 'biz_pkp';
  static const _kEmp = 'biz_emp';

  @override
  Future<BusinessProfile?> getCurrent() async {
    final p = await SharedPreferences.getInstance();
    final name = p.getString(_kName);
    if (name == null) return null;
    return _build(BusinessDraft(
      businessName: name,
      ownerName: p.getString(_kOwner),
      npwp: p.getString(_kNpwp),
      businessType: p.getString(_kType) ?? '',
      pkpStatus: p.getBool(_kPkp) ?? false,
      employeeCount: p.getInt(_kEmp) ?? 0,
    ));
  }

  @override
  Future<BusinessProfile> create(BusinessDraft draft) async {
    await _save(draft);
    return _build(draft);
  }

  @override
  Future<BusinessProfile> update(String id, BusinessDraft draft) async {
    await _save(draft);
    return _build(draft, id: id);
  }

  Future<void> _save(BusinessDraft d) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, d.businessName);
    await p.setString(_kType, d.businessType);
    await p.setBool(_kPkp, d.pkpStatus);
    await p.setInt(_kEmp, d.employeeCount);
    if (d.ownerName != null) await p.setString(_kOwner, d.ownerName!);
    if (d.npwp != null) await p.setString(_kNpwp, d.npwp!);
  }

  BusinessProfile _build(BusinessDraft d, {String id = 'local-biz'}) =>
      BusinessProfile(
        id: id,
        userId: 'local',
        businessName: d.businessName,
        ownerName: d.ownerName,
        npwp: d.npwp,
        businessType: d.businessType,
        pkpStatus: d.pkpStatus,
        employeeCount: d.employeeCount,
        isActive: true,
        createdAt: DateTime.now(),
      );
}

// ── Transaksi ─────────────────────────────────────────────────────────────────

class MockTransactionRepository implements TransactionRepository {
  /// Transaksi yang ditambahkan selama sesi berjalan — hidup di memori saja.
  static final List<TxData> _added = [];
  static final Set<String> _deleted = {};

  List<TxData> get _all => [
        ..._added,
        ...MockData.transactions.where((t) => !_deleted.contains(t.id)),
      ]..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<List<TxCategoryData>> getCategories() async {
    await Future.delayed(MockData.latency);
    return MockData.txCategories;
  }

  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    String? businessId,
  }) async {
    await Future.delayed(MockData.latency);
    return _all
        .where((t) =>
            (month == null || t.date.month == month) &&
            (year == null || t.date.year == year))
        .toList();
  }

  @override
  Future<TxData?> getTransaction(String id) async {
    await Future.delayed(MockData.latency);
    final all = _all;
    if (all.isEmpty) return null;
    return all.where((t) => t.id == id).firstOrNull ?? all.first;
  }

  @override
  Future<bool> createTransaction(TransactionDraft draft) async {
    await Future.delayed(MockData.latency);
    final category = MockData.txCategories
            .where((c) => c.id == draft.categoryId)
            .firstOrNull ??
        MockData.txCategories.first;
    _added.insert(
      0,
      TxData(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        businessId: draft.businessId,
        date: DateTime.tryParse(draft.date) ?? DateTime.now(),
        type: draft.type,
        amount: draft.amount,
        category: category,
        description: draft.description,
        paymentMethod: draft.paymentMethod,
        receiptNote: draft.receiptNote,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    await Future.delayed(MockData.latency);
    _added.removeWhere((t) => t.id == id);
    _deleted.add(id);
    return true;
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<MonthlySummary> getSummary({int? month, int? year}) async {
    await Future.delayed(MockData.latency);
    return MockData.monthlySummary;
  }

  @override
  Future<List<RecentTx>> getRecentTransactions({int limit = 5}) async {
    await Future.delayed(MockData.latency);
    return MockData.recentTransactions.take(limit).toList();
  }

  @override
  Future<List<TaxDeadline>> getDeadlines({int limit = 3}) async {
    await Future.delayed(MockData.latency);
    return MockData.deadlines.take(limit).toList();
  }

  @override
  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric) async {
    await Future.delayed(MockData.latency);
    return MockData.kpiHistory(metric.name);
  }
}

// ── Pustaka peraturan ─────────────────────────────────────────────────────────

class MockLibraryRepository implements LibraryRepository {
  @override
  Future<List<DocCategory>> getCategories() async {
    await Future.delayed(MockData.latency);
    return MockData.docCategories;
  }

  @override
  Future<List<Document>> getDocuments({
    String? query,
    String? categoryId,
    String? type,
  }) async {
    await Future.delayed(MockData.latency);
    var docs = MockData.documents;
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      docs = docs
          .where((d) =>
              d.title.toLowerCase().contains(q) ||
              (d.summary?.toLowerCase().contains(q) ?? false) ||
              d.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    if (categoryId != null) {
      docs = docs.where((d) => d.categoryId == categoryId).toList();
    }
    if (type != null) {
      docs = docs.where((d) => d.type.label == type).toList();
    }
    return docs;
  }

  @override
  Future<Document?> getDocument(String id) async {
    await Future.delayed(MockData.latency);
    return MockData.documents.where((d) => d.id == id).firstOrNull;
  }
}
