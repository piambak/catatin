// lib/core/data/supabase_repositories.dart
//
// Implementasi kontrak `repositories.dart` di atas Supabase — dipilih lewat
// `DATA_SOURCE=supabase`.
//
// Bedanya dengan `api_repositories.dart`: tidak ada server REST buatan sendiri.
// Klien bicara langsung ke Postgres lewat PostgREST, dan yang memastikan
// pengguna hanya melihat datanya sendiri adalah Row Level Security di
// `supabase/migrations/` — bukan kode di berkas ini. Skema dan kebijakannya
// dijelaskan di `wiki/arsitektur/backend-dan-api.md`.
//
// Nama kolom sengaja sama dengan kunci JSON kontrak REST, jadi `fromJson` di
// `models/` dipakai apa adanya.
//
// Kontrak galat sama dengan REST: setiap method melempar [ApiException]
// (lewat `runSupabase`).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../models/models.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/supabase_client.dart';
import '../services/simulator_service.dart' show generateCalendar;
import '../utils/formatters.dart';
import 'repositories.dart';

sb.SupabaseClient get _db => SupabaseBackend.client;

const _businessTable = 'business_profiles';
const _txTable = 'transactions';

/// Transaksi beserta kategorinya, disematkan dengan nama kunci `category`
/// seperti yang diharapkan `TxData.fromJson` dan `RecentTx.fromJson`.
const _txWithCategory = '*, category:tx_categories(*)';

// ── Auth ──────────────────────────────────────────────────────────────────────

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) =>
      runSupabase(() async {
        final res = await _db.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        final session = res.session;
        if (session == null) {
          // "Confirm email" menyala di dashboard Supabase: akunnya dibuat,
          // tapi sesi baru ada setelah tautan di email diklik.
          throw const ApiException(
            statusCode: 409,
            message: 'Akun dibuat. Buka tautan konfirmasi di email Anda, '
                'lalu masuk.',
          );
        }
        return _authResponse(session);
      });

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      runSupabase(() async {
        final res = await _db.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final session = res.session;
        if (session == null) {
          throw const ApiException(statusCode: 401, message: 'Sesi tidak terbentuk.');
        }
        return _authResponse(session);
      });

  @override
  Future<UserModel> me() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw const ApiException(statusCode: 401, message: 'Belum masuk.');
    }
    return userFromMetadata(
      id: user.id,
      email: user.email,
      metadata: user.userMetadata,
      createdAt: user.createdAt,
    );
  }

  @override
  Future<void> logout() => runSupabase(() => _db.auth.signOut());

  @override
  Future<void> signInWithGoogle() => runSupabase(() async {
        // Web: halaman ini sendiri pindah ke Google (PKCE), lalu kembali ke
        // alamat yang sama dengan `?code=`; `SupabaseBackend.init` menukarnya
        // jadi sesi sebelum frame pertama. Android: browser eksternal kembali
        // lewat deep link [AppConfig.oauthRedirectMobile].
        final opened = await _db.auth.signInWithOAuth(
          sb.OAuthProvider.google,
          redirectTo:
              kIsWeb ? oauthRedirectUrl(Uri.base) : AppConfig.oauthRedirectMobile,
        );
        if (!opened) {
          throw const ApiException(
            statusCode: 0,
            message: 'Halaman masuk Google tidak bisa dibuka.',
          );
        }
      });

  @override
  Future<AuthResponse?> currentSession() async {
    final session = _db.auth.currentSession;
    return session == null ? null : _authResponse(session);
  }

  /// Provider dari identitas akun, ditambah `email` kalau akun punya kata sandi.
  ///
  /// Kata sandi dicek lewat `rpc('has_password')`, bukan dari identitas:
  /// Supabase Auth hanya membuat identitas `email` saat kata sandi pertama
  /// dipasang bila flag eksperimentalnya menyala, dan di proyek ini tidak —
  /// akun Google yang sudah memasang kata sandi tetap hanya punya identitas
  /// `google`.
  @override
  Future<Set<String>> signInProviders() => runSupabase(() async {
        final providers = {
          for (final identity
              in _db.auth.currentUser?.identities ?? const <sb.UserIdentity>[])
            identity.provider,
        };
        if (await _db.rpc<dynamic>('has_password') == true) {
          providers.add('email');
        }
        return providers;
      });

  /// Akun Google boleh memasang kata sandi pertamanya tanpa kata sandi lama.
  /// Kalau "Secure password change" menyala di proyek, sesi yang umurnya lebih
  /// dari 24 jam ditolak dengan `reauthentication_needed` — pesannya meminta
  /// pengguna masuk ulang, karena verifikasi lewat email belum bisa terkirim.
  @override
  Future<void> setPassword({
    required String newPassword,
    String? currentPassword,
  }) =>
      runSupabase(() => _db.auth.updateUser(sb.UserAttributes(
            password: newPassword,
            currentPassword: currentPassword,
          )));

  AuthResponse _authResponse(sb.Session session) => AuthResponse(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
        user: userFromMetadata(
          id: session.user.id,
          email: session.user.email,
          metadata: session.user.userMetadata,
          createdAt: session.user.createdAt,
        ),
      );
}

/// Alamat kembali setelah masuk dengan Google di web: halaman aplikasi ini
/// tanpa query dan fragment, mis. `https://piambak.github.io/catatin/`.
///
/// Diturunkan dari alamat yang sedang dibuka, bukan di-hardcode, supaya build
/// lokal (`http://localhost:8012/catatin/`) kembali ke dirinya sendiri. Alamat
/// ini wajib cocok dengan Redirect URLs di dashboard Supabase; kalau tidak,
/// Supabase mengirim pengguna ke Site URL.
String oauthRedirectUrl(Uri page) => Uri(
      scheme: page.scheme,
      host: page.host,
      port: page.hasPort ? page.port : null,
      path: page.path.isEmpty ? '/' : page.path,
    ).toString();

/// Profil pengguna dari data akun Supabase.
///
/// Pendaftar email menyimpan `name` saat daftar; akun Google membawa `name`
/// atau `full_name` dan foto di `avatar_url` atau `picture`. Tanpa nama sama
/// sekali, bagian depan alamat email dipakai.
UserModel userFromMetadata({
  required String id,
  required String? email,
  required Map<String, dynamic>? metadata,
  required String createdAt,
}) {
  final meta = metadata ?? const <String, dynamic>{};
  String? text(String key) {
    final value = meta[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  final address = email ?? '';
  return UserModel(
    id: id,
    name: text('name') ?? text('full_name') ?? address.split('@').first,
    email: address,
    image: text('avatar_url') ?? text('picture'),
    createdAt: DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now(),
  );
}

// ── Profil usaha ──────────────────────────────────────────────────────────────

class SupabaseBusinessRepository implements BusinessRepository {
  @override
  Future<BusinessProfile?> getCurrent() => runSupabase(() async {
        // RLS hanya mengembalikan baris milik pengguna yang sedang masuk, dan
        // `unique (user_id)` menjamin paling banyak satu.
        final row = await _db.from(_businessTable).select().maybeSingle();
        return row == null ? null : BusinessProfile.fromJson(row);
      });

  /// Upsert, bukan insert: kalau profilnya ternyata sudah ada (form onboarding
  /// terbuka di dua perangkat), baris yang sama diperbarui alih-alih gagal.
  @override
  Future<BusinessProfile> create(BusinessDraft draft) => runSupabase(() async {
        final row = await _db
            .from(_businessTable)
            .upsert(
              {...draft.toJson(), 'user_id': _currentUserId()},
              onConflict: 'user_id',
            )
            .select()
            .single();
        return BusinessProfile.fromJson(row);
      });

  @override
  Future<BusinessProfile> update(String id, BusinessDraft draft) =>
      runSupabase(() async {
        final row = await _db
            .from(_businessTable)
            .update(draft.toJson())
            .eq('id', id)
            .select()
            .maybeSingle();
        if (row == null) {
          throw const ApiException(
            statusCode: 404,
            message: 'Profil usaha tidak ditemukan.',
          );
        }
        return BusinessProfile.fromJson(row);
      });
}

// ── Transaksi ─────────────────────────────────────────────────────────────────

class SupabaseTransactionRepository implements TransactionRepository {
  /// Sama dengan batas bawaan "Max rows" di pengaturan API Supabase. Halaman
  /// yang terisi kurang dari ini dianggap halaman terakhir, jadi pengaturan
  /// itu tidak boleh diturunkan di bawah angka ini.
  static const _pageSize = 1000;

  static const _notFound = ApiException(
    statusCode: 404,
    message: 'Transaksi tidak ditemukan.',
  );

  @override
  Future<List<TxCategoryData>> getCategories() => runSupabase(() async {
        final rows = await _db
            .from('tx_categories')
            .select()
            .order('sort_order', ascending: true);
        return rows.map(TxCategoryData.fromJson).toList();
      });

  /// Tanpa filter, seluruh transaksi dikembalikan — layar Pencatatan menggulir
  /// bulan dan tahun sendiri.
  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) {
    checkTransactionFilter(month: month, year: year, from: from, to: to);
    return runSupabase(() async {
      final range = dateRangeFor(
        month: month,
        year: year,
        from: from,
        to: to,
        now: DateTime.now(),
      );
      final result = <TxData>[];
      for (var offset = 0;; offset += _pageSize) {
        var query = _db.from(_txTable).select(_txWithCategory);
        if (range?.from case final start?) query = query.gte('date', start);
        if (range?.until case final end?) query = query.lt('date', end);
        if (businessId != null && isUuid(businessId)) {
          query = query.eq('business_id', businessId);
        }
        final page = await query
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .range(offset, offset + _pageSize - 1);
        result.addAll(page.map(TxData.fromJson));
        if (page.length < _pageSize) break;
      }
      return result;
    });
  }

  @override
  Future<TxData?> getTransaction(String id) async {
    // Id non-UUID (mis. sisa data contoh) tidak mungkin ada di tabel ini.
    if (!isUuid(id)) return null;
    return runSupabase(() async {
      final row = await _db
          .from(_txTable)
          .select(_txWithCategory)
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : TxData.fromJson(row);
    });
  }

  /// `business_id` selalu diambil dari server, bukan dari [TransactionDraft]:
  /// id yang tersimpan lokal bisa sisa akun lain di perangkat yang sama.
  @override
  Future<bool> createTransaction(TransactionDraft draft) =>
      runSupabase(() async {
        final businessId = await _currentBusinessId();
        await _db
            .from(_txTable)
            .insert({...draft.toJson(), 'business_id': businessId});
        return true;
      });

  @override
  Future<bool> updateTransaction(String id, TransactionDraft draft) async {
    if (!isUuid(id)) throw _notFound;
    return runSupabase(() async {
      final payload = draft.toJson()..remove('business_id');
      // RLS menyembunyikan baris milik orang lain tanpa galat — hasil kosong
      // berarti tidak ada yang diubah.
      final rows =
          await _db.from(_txTable).update(payload).eq('id', id).select('id');
      if (rows.isEmpty) throw _notFound;
      return true;
    });
  }

  @override
  Future<bool> deleteTransaction(String id) async {
    if (!isUuid(id)) throw _notFound;
    return runSupabase(() async {
      final rows = await _db.from(_txTable).delete().eq('id', id).select('id');
      if (rows.isEmpty) throw _notFound;
      return true;
    });
  }

  /// Fungsi Postgres yang sama dengan ringkasan dashboard — tidak ada tabel
  /// atau fungsi agregat kedua di database.
  @override
  Future<YearAggregate> getAggregate({required int year}) =>
      runSupabase(() async {
        final rows = await _monthlyTotals(year);
        return YearAggregate.fromMonthlyTotals(year, monthTotalsFromRows(rows));
      });

  Future<String> _currentBusinessId() async {
    final row = await _db.from(_businessTable).select('id').maybeSingle();
    final id = row?['id'] as String?;
    if (id == null) {
      throw const ApiException(
        statusCode: 409,
        message: 'Lengkapi profil usaha dulu sebelum mencatat transaksi.',
      );
    }
    return id;
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

class SupabaseDashboardRepository implements DashboardRepository {
  @override
  Future<MonthlySummary> getSummary({int? month, int? year}) =>
      runSupabase(() async {
        final now = DateTime.now();
        final rows = await _monthlyTotals(year ?? now.year);
        return summaryFromMonthlyTotals(rows, month: month ?? now.month);
      });

  @override
  Future<List<RecentTx>> getRecentTransactions({int limit = 5}) =>
      runSupabase(() async {
        final rows = await _db
            .from(_txTable)
            .select(_txWithCategory)
            .order('date', ascending: false)
            .order('created_at', ascending: false)
            .limit(limit);
        return rows.map(RecentTx.fromJson).toList();
      });

  /// Tenggat dihitung dari aturan kalender yang sama dengan tab Kalender di
  /// Simulator (`generateCalendar`), bukan disalin ke SQL — dua salinan aturan
  /// pasti menyimpang (pelajaran T-13).
  @override
  Future<List<TaxDeadline>> getDeadlines({int limit = 3}) =>
      runSupabase(() async {
        final business = await _db
            .from(_businessTable)
            .select('pkp_status, employee_count')
            .maybeSingle();
        return upcomingDeadlines(
          now: DateTime.now(),
          isPkp: business?['pkp_status'] as bool? ?? false,
          hasEmployees: numValue(business?['employee_count']) > 0,
          limit: limit,
        );
      });

  @override
  Future<List<KpiPoint>> getKpiHistory(KpiMetric metric) =>
      runSupabase(() async {
        final now = DateTime.now();
        final rows = await _monthlyTotals(now.year);
        return kpiFromMonthlyTotals(rows, metric, upToMonth: now.month);
      });
}

/// Satu baris per bulan dari fungsi Postgres `monthly_totals`.
Future<List<Map<String, dynamic>>> _monthlyTotals(int year) async {
  final data = await _db.rpc('monthly_totals', params: {'p_year': year});
  return (data as List).cast<Map<String, dynamic>>();
}

// ── Helper murni (dites di test/supabase_mapping_test.dart) ───────────────────

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isUuid(String value) => _uuidPattern.hasMatch(value);

String _currentUserId() {
  final id = _db.auth.currentUser?.id;
  if (id == null) {
    throw const ApiException(statusCode: 401, message: 'Belum masuk.');
  }
  return id;
}

/// Angka dari PostgREST: `numeric` datang sebagai angka JSON, yang bisa
/// ter-decode jadi `int` maupun `double`.
double numValue(Object? value) => switch (value) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

/// Rentang tanggal `[from, until)` berformat `YYYY-MM-DD`, atau `null` kalau
/// tidak ada filter sama sekali.
///
/// [month]/[year] menghasilkan rentang tertutup satu bulan atau satu tahun.
/// [from]/[to] inklusif, jadi `until` adalah sehari setelah [to]; ujung yang
/// tidak diisi dibiarkan `null` (terbuka). Campuran keduanya ditolak lebih dulu
/// oleh `checkTransactionFilter`.
({String? from, String? until})? dateRangeFor({
  int? month,
  int? year,
  DateTime? from,
  DateTime? to,
  required DateTime now,
}) {
  if (from != null || to != null) {
    return (
      from: from == null ? null : Tanggal.api(dateOnly(from)),
      until: to == null
          ? null
          : Tanggal.api(DateTime(to.year, to.month, to.day + 1)),
    );
  }
  if (month == null && year == null) return null;
  final y = year ?? now.year;
  return month == null
      ? (from: Tanggal.api(DateTime(y)), until: Tanggal.api(DateTime(y + 1)))
      : (
          from: Tanggal.api(DateTime(y, month)),
          until: Tanggal.api(DateTime(y, month + 1)),
        );
}

/// Baris `monthly_totals` → angka mentah per bulan. Kolom `hpp` di database
/// adalah `cogs` di kontrak.
List<MonthTotals> monthTotalsFromRows(List<Map<String, dynamic>> rows) => [
      for (final row in rows)
        (
          month: numValue(row['month']).toInt(),
          income: numValue(row['income']),
          expense: numValue(row['expense']),
          cogs: numValue(row['hpp']),
          txCount: numValue(row['tx_count']).toInt(),
        ),
    ];

/// Baris `monthly_totals` → ringkasan satu bulan. Omzet YTD adalah pemasukan
/// Januari sampai [month].
MonthlySummary summaryFromMonthlyTotals(
  List<Map<String, dynamic>> rows, {
  required int month,
}) {
  final m = monthAggregates(monthTotalsFromRows(rows))[month - 1];
  // Lewat fromJson supaya persentase ambang PKP tetap dihitung di satu tempat.
  return MonthlySummary.fromJson({
    'monthly_income': m.income,
    'monthly_expense': m.expense,
    'monthly_profit': m.profit,
    'ytd_omzet': m.ytdOmzet,
    'tx_count': m.txCount,
  });
}

/// Baris `monthly_totals` → titik grafik KPI Januari sampai [upToMonth],
/// berlabel bulan pendek Bahasa Indonesia ("Jan", "Mei", "Agu", …).
List<KpiPoint> kpiFromMonthlyTotals(
  List<Map<String, dynamic>> rows,
  KpiMetric metric, {
  required int upToMonth,
}) {
  final label = DateFormat.MMM('id_ID');
  return [
    for (final m in monthAggregates(monthTotalsFromRows(rows)).take(upToMonth))
      KpiPoint(
        month: label.format(DateTime(2000, m.month)),
        value: switch (metric) {
          KpiMetric.income => m.income,
          KpiMetric.expense => m.expense,
          KpiMetric.profit => m.profit,
          KpiMetric.ytd => m.ytdOmzet,
        },
      ),
  ];
}

/// Tenggat pajak mulai hari ini, paling banyak [limit].
///
/// Kalender tahun lalu ikut dihitung: SPT Tahunan-nya jatuh tempo 30 April
/// tahun ini, dan kewajiban masa Desember jatuh tempo di Januari.
List<TaxDeadline> upcomingDeadlines({
  required DateTime now,
  required bool isPkp,
  required bool hasEmployees,
  required int limit,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final items = [
    for (final year in [now.year - 1, now.year])
      ...generateCalendar(year: year, isPkp: isPkp, hasEmployees: hasEmployees),
  ].where((d) => !d.deadline.isBefore(today)).toList()
    ..sort((a, b) => a.deadline.compareTo(b.deadline));

  return [
    for (final d in items.take(limit))
      TaxDeadline(
        id: d.id,
        label: d.label,
        taxType: _taxTypeCode(d.taxType),
        deadline: d.deadline,
        status: 'PENDING',
      ),
  ];
}

/// Label jenis pajak di kalender → kode `tax_type` di kontrak API.
String _taxTypeCode(String taxType) => switch (taxType) {
      'PPh Final' => 'PPH_FINAL',
      'PPh 21' => 'PPH21',
      'SPT Tahunan' => 'SPT',
      'PPN' => 'PPN',
      _ => taxType,
    };
