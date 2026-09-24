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

import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/models.dart';
import '../network/api_client.dart';
import '../utils/formatters.dart';
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

  /// Tidak ada sesi di mana pun selain penyimpanan lokal.
  @override
  Future<void> logout() async {}

  /// Layar tidak menampilkan tombol Google di mode ini; ini hanya penjaga.
  @override
  Future<void> signInWithGoogle() async => throw googleSignInUnsupported;

  @override
  Future<AuthResponse?> currentSession() async => null;

  /// Akun demo masuk dengan email + kata sandi.
  @override
  Future<Set<String>> signInProviders() async => {'email'};

  @override
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) =>
      Future.delayed(MockData.latency);
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
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) async {
    checkTransactionFilter(month: month, year: year, from: from, to: to);
    await Future.delayed(MockData.latency);
    final start = from == null ? null : dateOnly(from);
    final end = to == null ? null : dateOnly(to);
    return _all.where((t) {
      final day = dateOnly(t.date);
      return (month == null || t.date.month == month) &&
          (year == null || t.date.year == year) &&
          (start == null || !day.isBefore(start)) &&
          (end == null || !day.isAfter(end));
    }).toList();
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

  /// Versi baru menggantikan yang lama di [_added]; kalau yang lama berasal
  /// dari seed, id-nya ikut masuk [_deleted] supaya tidak muncul dua kali.
  @override
  Future<bool> updateTransaction(String id, TransactionDraft draft) async {
    await Future.delayed(MockData.latency);
    final old = _all.where((t) => t.id == id).firstOrNull;
    if (old == null) return false;
    final category = MockData.txCategories
            .where((c) => c.id == draft.categoryId)
            .firstOrNull ??
        old.category;
    _added
      ..removeWhere((t) => t.id == id)
      ..add(TxData(
        id: id,
        businessId: old.businessId,
        date: DateTime.tryParse(draft.date) ?? old.date,
        type: draft.type,
        amount: draft.amount,
        category: category,
        description: draft.description,
        paymentMethod: draft.paymentMethod,
        receiptNote: draft.receiptNote,
        createdAt: old.createdAt,
      ));
    _deleted.add(id);
    return true;
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    await Future.delayed(MockData.latency);
    _added.removeWhere((t) => t.id == id);
    _deleted.add(id);
    return true;
  }

  /// Dihitung dari daftar transaksi contoh, jadi transaksi yang ditambah atau
  /// dihapus selama sesi ikut terhitung.
  @override
  Future<YearAggregate> getAggregate({required int year}) async {
    await Future.delayed(MockData.latency);
    final totals = <int, MonthTotals>{};
    for (final t in _all.where((t) => t.date.year == year)) {
      final m = t.date.month;
      final prev = totals[m] ??
          (month: m, income: 0.0, expense: 0.0, cogs: 0.0, txCount: 0);
      totals[m] = (
        month: m,
        income: prev.income + (t.isIncome ? t.amount : 0),
        expense: prev.expense + (t.isIncome ? 0 : t.amount),
        cogs: prev.cogs + (!t.isIncome && t.category.isCogs ? t.amount : 0),
        txCount: prev.txCount + 1,
      );
    }
    return YearAggregate.fromMonthlyTotals(year, totals.values);
  }
}

// ── Transaksi berulang ──────────────────────────────────────────────────────

class MockRecurringRepository implements RecurringRepository {
  /// Hidup di memori saja, sama seperti [MockTransactionRepository._added] —
  /// tidak ada seed di `MockData` untuk fitur ini.
  static final List<RecurringTemplate> _templates = [];

  /// Profil usaha bawaan [MockBusinessRepository]; template tidak perlu tahu
  /// id usaha yang sesungguhnya karena mode mock selalu satu usaha per sesi.
  static const _businessId = 'local-biz';

  @override
  Future<List<RecurringTemplate>> getTemplates() async {
    await Future.delayed(MockData.latency);
    final list = [..._templates];
    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      if (a.nextDate == null || b.nextDate == null) {
        return (a.nextDate == null ? 1 : 0) - (b.nextDate == null ? 1 : 0);
      }
      return a.nextDate!.compareTo(b.nextDate!);
    });
    return list;
  }

  @override
  Future<RecurringTemplate> createTemplate(RecurringDraft draft) async {
    await Future.delayed(MockData.latency);
    final category = MockData.txCategories
            .where((c) => c.id == draft.categoryId)
            .firstOrNull ??
        MockData.txCategories.first;
    final start = DateTime.tryParse(draft.startDate) ?? DateTime.now();
    final end = draft.endDate == null ? null : DateTime.tryParse(draft.endDate!);
    final schedule = _computeSchedule(
      start: start,
      frequency: draft.frequency,
      end: end,
      today: DateTime.now(),
    );
    final template = RecurringTemplate(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      businessId: _businessId,
      type: draft.type,
      amount: draft.amount,
      category: category,
      description: draft.description,
      paymentMethod: draft.paymentMethod,
      frequency: draft.frequency,
      startDate: draft.startDate,
      endDate: draft.endDate,
      nextDate: schedule.nextDate,
      isActive: schedule.isActive,
      createdAt: DateTime.now(),
    );
    _templates.insert(0, template);
    return template;
  }

  /// Menolak dengan 409 kalau template [id] sudah dihentikan.
  ///
  /// `next_date` hanya dihitung ulang dari nol kalau jadwalnya berubah
  /// (frekuensi atau tanggal mulai) — kalau tidak, `next_date` lama
  /// dipertahankan. Tapi `end_date` diperiksa pada SETIAP edit, bahkan yang
  /// tidak menyentuh jadwal: kalau `end_date` baru jatuh sebelum `next_date`
  /// (lama maupun yang baru dihitung), template langsung nonaktif dengan
  /// `next_date` kosong. Ini menyalin perilaku trigger SQL di Supabase, bukan
  /// aturan yang dikarang sendiri di sini.
  @override
  Future<RecurringTemplate> updateTemplate(
    String id,
    RecurringDraft draft,
  ) async {
    await Future.delayed(MockData.latency);
    final old = _templates.where((t) => t.id == id).firstOrNull;
    if (old == null) {
      throw const ApiException(
        statusCode: 404,
        message: 'Transaksi berulang tidak ditemukan.',
      );
    }
    if (!old.isActive) {
      throw const ApiException(
        statusCode: 409,
        message: 'Transaksi berulang ini sudah dihentikan. Buat yang baru.',
      );
    }
    final category = MockData.txCategories
            .where((c) => c.id == draft.categoryId)
            .firstOrNull ??
        old.category;
    final scheduleChanged =
        draft.frequency != old.frequency || draft.startDate != old.startDate;
    final end = draft.endDate == null ? null : DateTime.tryParse(draft.endDate!);
    final schedule = scheduleChanged
        ? _computeSchedule(
            start: DateTime.tryParse(draft.startDate) ?? DateTime.now(),
            frequency: draft.frequency,
            end: end,
            today: DateTime.now(),
          )
        : _applyEndDate(old.nextDate, end);
    final updated = RecurringTemplate(
      id: id,
      businessId: old.businessId,
      type: draft.type,
      amount: draft.amount,
      category: category,
      description: draft.description,
      paymentMethod: draft.paymentMethod,
      frequency: draft.frequency,
      startDate: draft.startDate,
      endDate: draft.endDate,
      nextDate: schedule.nextDate,
      isActive: schedule.isActive,
      createdAt: old.createdAt,
    );
    final index = _templates.indexWhere((t) => t.id == id);
    _templates[index] = updated;
    return updated;
  }

  /// Template yang sudah nonaktif dikembalikan apa adanya, tanpa galat.
  @override
  Future<RecurringTemplate> stopTemplate(String id) async {
    await Future.delayed(MockData.latency);
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw const ApiException(
        statusCode: 404,
        message: 'Transaksi berulang tidak ditemukan.',
      );
    }
    final old = _templates[index];
    if (!old.isActive) return old;
    final stopped = RecurringTemplate(
      id: old.id,
      businessId: old.businessId,
      type: old.type,
      amount: old.amount,
      category: old.category,
      description: old.description,
      paymentMethod: old.paymentMethod,
      frequency: old.frequency,
      startDate: old.startDate,
      endDate: old.endDate,
      nextDate: null,
      isActive: false,
      createdAt: old.createdAt,
    );
    _templates[index] = stopped;
    return stopped;
  }
}

/// `next_date`/`is_active` dari sebuah jadwal: kejadian pertama pada atau
/// setelah [today], atau nonaktif kalau kejadian itu sudah melewati [end]
/// (inklusif — pas di [end] masih aktif).
({bool isActive, String? nextDate}) _computeSchedule({
  required DateTime start,
  required String frequency,
  required DateTime? end,
  required DateTime today,
}) {
  final next = recurringFirstOnOrAfter(start, frequency, today);
  if (end != null && next.isAfter(end)) {
    return (isActive: false, nextDate: null);
  }
  return (isActive: true, nextDate: Tanggal.api(next));
}

/// Memeriksa [end] terhadap [nextDate] yang sudah ada (bukan dihitung ulang
/// dari jadwal) — dipakai saat mengedit template yang frekuensi/tanggal
/// mulainya tidak berubah, supaya edit yang hanya mengubah `end_date` tetap
/// bisa menghentikan template kalau `end_date` barunya jatuh sebelum
/// `next_date`.
({bool isActive, String? nextDate}) _applyEndDate(
  String? nextDate,
  DateTime? end,
) {
  if (nextDate == null) return (isActive: false, nextDate: null);
  if (end != null && DateTime.parse(nextDate).isAfter(end)) {
    return (isActive: false, nextDate: null);
  }
  return (isActive: true, nextDate: nextDate);
}

// ── Lampiran struk ────────────────────────────────────────────────────────────

class MockAttachmentRepository implements AttachmentRepository {
  /// Hidup di memori saja, satu daftar per transaksi — sama polanya dengan
  /// [MockRecurringRepository._templates].
  static final Map<String, List<TxAttachment>> _byTransaction = {};

  @override
  Future<List<TxAttachment>> getAttachments(String transactionId) async {
    await Future.delayed(MockData.latency);
    return [...?_byTransaction[transactionId]];
  }

  /// URL-nya adalah data URI berisi berkasnya sendiri — mode mock tidak
  /// punya Storage sungguhan untuk disimpan.
  @override
  Future<TxAttachment> uploadAttachment(
    String transactionId, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    checkAttachmentUpload(bytes: bytes, mimeType: mimeType);
    await Future.delayed(MockData.latency);
    final now = DateTime.now();
    final attachment = TxAttachment(
      id: 'local-${now.microsecondsSinceEpoch}',
      transactionId: transactionId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      url: 'data:$mimeType;base64,${base64Encode(bytes)}',
      urlExpiresAt: now.add(const Duration(hours: 1)),
      createdAt: now,
    );
    (_byTransaction[transactionId] ??= []).add(attachment);
    return attachment;
  }

  @override
  Future<void> deleteAttachment(String transactionId, String attachmentId) async {
    await Future.delayed(MockData.latency);
    final list = _byTransaction[transactionId];
    final index = list?.indexWhere((a) => a.id == attachmentId) ?? -1;
    if (index == -1) {
      throw const ApiException(
        statusCode: 404,
        message: 'Lampiran tidak ditemukan.',
      );
    }
    list!.removeAt(index);
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

  /// Dari agregat transaksi contoh, bukan angka tetap di [MockData] — jadi
  /// sama dengan tab Pembukuan, termasuk transaksi yang ditambah selama sesi.
  @override
  Future<MonthClose> getMonthClose({required int month, required int year}) async {
    checkMonthParam(month: month);
    final aggregate =
        await MockTransactionRepository().getAggregate(year: year);
    return MonthClose.fromAggregate(year, aggregate[month]);
  }
}

// ── Simulator ─────────────────────────────────────────────────────────────────

class MockSimulatorRepository implements SimulatorRepository {
  /// Dari agregat transaksi contoh dan profil usaha lokal — sumber yang sama
  /// dengan tab Pembukuan dan Pengaturan.
  @override
  Future<SimulatorInputs> getInputs({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;
    checkMonthParam(month: m);
    final tx = MockTransactionRepository();
    final (current, previous, business) = await (
      tx.getAggregate(year: y),
      m <= 3 ? tx.getAggregate(year: y - 1) : Future.value(null),
      MockBusinessRepository().getCurrent(),
    ).wait;
    return simulatorInputsFrom(
      month: m,
      year: y,
      current: current,
      previous: previous,
      business: business,
    );
  }
}
