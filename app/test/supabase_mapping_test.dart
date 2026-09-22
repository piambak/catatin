// test/supabase_mapping_test.dart
//
// Bagian lapisan Supabase yang bisa dites tanpa jaringan dan tanpa proyek
// Supabase: galat klien → ApiException (pesan yang dilihat pengguna), baris
// fungsi `monthly_totals` → ringkasan dan grafik KPI, kalender pajak → tenggat
// dashboard, dan filter tanggal.
//
// Jalankan: flutter test test/supabase_mapping_test.dart

import 'dart:async';

import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/data/supabase_repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/core/network/supabase_client.dart';
import 'package:catatin/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() {
  setUpAll(() => initializeDateFormatting('id_ID', null));

  group('supabaseException — Auth', () {
    ApiException map(Object error) =>
        supabaseException(error, hasSession: false)!;

    test('kredensial salah tampil sebagai pesan form, bukan "data tidak valid"', () {
      final e = map(const sb.AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      ));
      expect(e.statusCode, 400);
      expect(e.userMessage, 'Email atau kata sandi salah.');
    });

    test('email yang sudah terdaftar → 409 berbahasa Indonesia', () {
      final e = map(const sb.AuthApiException(
        'User already registered',
        statusCode: '422',
        code: 'user_already_exists',
      ));
      expect(e.statusCode, 409);
      expect(e.userMessage, 'Email sudah terdaftar. Silakan masuk.');
    });

    test('kata sandi lemah → pesan per field', () {
      final e = map(sb.AuthWeakPasswordException(
        message: 'Password should be at least 6 characters',
        statusCode: '422',
        reasons: const ['length'],
      ));
      expect(e.statusCode, 400);
      expect(e.userMessage, startsWith('Kata sandi terlalu lemah'));
    });

    test('sesi hilang atau refresh token dicabut → 401', () {
      expect(map(sb.AuthSessionMissingException()).statusCode, 401);
      expect(
        map(const sb.AuthApiException('x', code: 'refresh_token_not_found'))
            .statusCode,
        401,
      );
      expect(map(sb.AuthInvalidJwtException('x')).statusCode, 401);
    });

    test('gagal jaringan tanpa status → 0, galat server → 500', () {
      expect(map(sb.AuthRetryableFetchException()).statusCode, 0);
      expect(
        map(sb.AuthRetryableFetchException(statusCode: '503')).statusCode,
        500,
      );
    });

    test('rate limit dikenali dari statusCode string maupun kode', () {
      final byStatus = map(const sb.AuthApiException('slow', statusCode: '429'));
      expect(byStatus.statusCode, 429);
      expect(byStatus.userMessage, startsWith('Terlalu banyak percobaan'));
      expect(
        map(const sb.AuthApiException('x', code: 'over_email_send_rate_limit'))
            .statusCode,
        429,
      );
    });

    test('pasang/ganti kata sandi: galat per field dalam Bahasa Indonesia', () {
      final same = map(const sb.AuthApiException('x', code: 'same_password'));
      expect(same.statusCode, 400);
      expect(same.errors, containsPair('password', startsWith('Kata sandi baru')));

      final wrong =
          map(const sb.AuthApiException('x', code: 'current_password_invalid'));
      expect(wrong.userMessage, 'Kata sandi saat ini salah.');

      expect(
        map(const sb.AuthApiException('x', code: 'current_password_required'))
            .userMessage,
        'Masukkan kata sandi saat ini.',
      );
    });

    test('verifikasi ulang (sesi > 24 jam) meminta masuk ulang, bukan email', () {
      final e =
          map(const sb.AuthApiException('x', code: 'reauthentication_needed'));
      expect(e.statusCode, 409);
      expect(e.userMessage, contains('masuk lagi dengan Google'));
    });

    test('409 tak dikenal tidak membocorkan pesan server berbahasa Inggris', () {
      final e = map(const sb.AuthApiException(
        'Conflict happened',
        statusCode: '409',
        code: 'kode_baru',
      ));
      expect(e.userMessage, isNot(contains('Conflict')));
    });
  });

  group('supabaseException — PostgREST', () {
    ApiException map(String code, {bool hasSession = true}) =>
        supabaseException(
          sb.PostgrestException(message: 'pesan asli server', code: code),
          hasSession: hasSession,
        )!;

    test('penolakan RLS: 403 kalau bersesi, 401 kalau sesi sudah habis', () {
      expect(map('42501').statusCode, 403);
      expect(map('42501', hasSession: false).statusCode, 401);
    });

    test('JWT kedaluwarsa → 401', () {
      expect(map('PGRST301').statusCode, 401);
      expect(map('PGRST303').statusCode, 401);
    });

    test('kode umum dipetakan ke pesan yang bisa dibaca', () {
      expect(map('PGRST116').statusCode, 404);
      expect(map('23505').statusCode, 409);
      expect(map('23505').userMessage, 'Data yang sama sudah tersimpan.');
      expect(map('22003').userMessage, 'Nominal terlalu besar.');
      expect(map('23514').userMessage, 'Data tidak valid.');
      expect(map('22P02').statusCode, 400);
    });

    test('kode tak dikenal → 500', () {
      expect(map('PGRST205').statusCode, 500);
    });
  });

  // Pesan persis seperti yang dikirim PostgREST — sama dengan yang dicocokkan
  // supabase/tests/database/04_validasi_transaksi.test.sql.
  group('supabaseException — validasi per field (#40)', () {
    ApiException map(String code, String message) => supabaseException(
          sb.PostgrestException(message: message, code: code),
          hasSession: true,
        )!;

    String check(String table, String constraint) =>
        'new row for relation "$table" violates check constraint "$constraint"';
    String fk(String constraint) =>
        'insert or update on table "transactions" violates foreign key '
        'constraint "$constraint"';

    test('nominal ≤ 0 → field amount', () {
      final e = map('23514', check('transactions', 'transactions_amount_check'));
      expect(e.statusCode, 400);
      expect(e.errors, {'amount': 'Nominal harus lebih dari 0.'});
      expect(e.userMessage, 'Nominal harus lebih dari 0.');
    });

    test('tanggal di luar 2000–2099 → field date', () {
      final e =
          map('23514', check('transactions', 'transactions_date_range_check'));
      expect(e.errors?.keys, ['date']);
      expect(e.userMessage, contains('2000'));
    });

    test('kategori tidak ada dan kategori salah jenis dibedakan', () {
      final hilang = map('23503', fk('transactions_category_id_fkey'));
      final salahJenis = map('23503', fk('transactions_category_type_fkey'));
      expect(hilang.statusCode, 400);
      expect(hilang.userMessage, 'Kategori tidak ditemukan.');
      expect(salahJenis.statusCode, 400);
      expect(salahJenis.userMessage,
          'Kategori tidak cocok dengan jenis transaksi.');
      expect(salahJenis.errors?.keys, ['category_id']);
    });

    test('metode pembayaran dan nama usaha', () {
      expect(
        map('23514',
                check('transactions', 'transactions_payment_method_check'))
            .errors
            ?.keys,
        ['payment_method'],
      );
      expect(
        map('23514', check('business_profiles',
                'business_profiles_business_name_check'))
            .userMessage,
        'Nama usaha wajib diisi.',
      );
    });

    test('tanggal kalender yang tidak ada (22008) → field date', () {
      final e =
          map('22008', 'date/time field value out of range: "2026-02-30"');
      expect(e.statusCode, 400);
      expect(e.errors?.keys, ['date']);
    });

    test('not-null → kolomnya wajib diisi', () {
      final e = map(
        '23502',
        'null value in column "business_name" of relation "business_profiles" '
            'violates not-null constraint',
      );
      expect(e.errors, {'business_name': 'Data wajib belum diisi.'});
    });

    test('constraint tak dikenal tetap 400 umum, tanpa errors', () {
      final e = map('23514', check('transactions', 'constraint_baru_lain'));
      expect(e.statusCode, 400);
      expect(e.userMessage, 'Data tidak valid.');
      expect(e.errors, isNull);
    });
  });

  // Pesan persis seperti di supabase/tests/database/07_pengerasan_validasi.test.sql.
  group('supabaseException — pengerasan validasi (#115)', () {
    ApiException map(String code, String message) => supabaseException(
          sb.PostgrestException(message: message, code: code),
          hasSession: true,
        )!;

    String check(String table, String constraint) =>
        'new row for relation "$table" violates check constraint "$constraint"';

    final panjang = {
      ('transactions', 'transactions_description_length_check'): (
        'description',
        'Keterangan maksimal 500 karakter.',
      ),
      ('transactions', 'transactions_receipt_note_length_check'): (
        'receipt_note',
        'Catatan struk maksimal 500 karakter.',
      ),
      ('recurring_templates', 'recurring_templates_description_length_check'): (
        'description',
        'Keterangan maksimal 500 karakter.',
      ),
      ('business_profiles', 'business_profiles_business_name_length_check'): (
        'business_name',
        'Nama usaha maksimal 100 karakter.',
      ),
      ('business_profiles', 'business_profiles_owner_name_length_check'): (
        'owner_name',
        'Nama pemilik maksimal 100 karakter.',
      ),
      ('business_profiles', 'business_profiles_business_type_length_check'): (
        'business_type',
        'Jenis usaha maksimal 100 karakter.',
      ),
    };

    for (final MapEntry(key: (table, constraint), value: (field, pesan))
        in panjang.entries) {
      test('$constraint → field $field', () {
        final e = map('23514', check(table, constraint));
        expect(e.statusCode, 400);
        expect(e.errors, {field: pesan});
        expect(e.userMessage, pesan);
      });
    }

    test('NPWP berkarakter asing → field npwp', () {
      final e = map('23514',
          check('business_profiles', 'business_profiles_npwp_format_check'));
      expect(e.errors?.keys, ['npwp']);
      expect(e.userMessage, contains('NPWP'));
    });

    test('usaha milik akun lain (FK komposit) → field business_id', () {
      for (final (table, constraint) in [
        ('transactions', 'transactions_business_owner_fkey'),
        ('recurring_templates', 'recurring_templates_business_owner_fkey'),
      ]) {
        final e = map(
          '23503',
          'insert or update on table "$table" violates foreign key '
              'constraint "$constraint"',
        );
        expect(e.statusCode, 400);
        expect(e.errors?.keys, ['business_id']);
      }
    });
  });

  group('supabaseException — lain-lain', () {
    test('ClientException dan TimeoutException → gagal jaringan', () {
      expect(
        supabaseException(
          http.ClientException('XMLHttpRequest error.'),
          hasSession: true,
        )!.statusCode,
        0,
      );
      expect(
        supabaseException(TimeoutException('lambat'), hasSession: true)!
            .statusCode,
        0,
      );
    });

    test('ApiException diteruskan apa adanya', () {
      const original = ApiException(statusCode: 409, message: 'Lengkapi profil');
      expect(supabaseException(original, hasSession: true), same(original));
    });

    test('bug pemrograman TIDAK ditelan jadi galat jaringan', () {
      expect(supabaseException(StateError('bug'), hasSession: true), isNull);
      expect(supabaseException(const FormatException('x'), hasSession: true),
          isNull);
    });
  });

  group('summaryFromMonthlyTotals', () {
    // Campuran int dan double, seperti hasil decode angka JSON dari PostgREST.
    final rows = <Map<String, dynamic>>[
      {'month': 1, 'income': 1000000, 'expense': 400000, 'hpp': 0, 'tx_count': 3},
      {'month': 2, 'income': 2500000.5, 'expense': 1000000, 'hpp': 0, 'tx_count': 4},
      {'month': 3, 'income': 700000, 'expense': 0, 'hpp': 0, 'tx_count': 1},
    ];

    test('angka bulan terpilih dan laba', () {
      final s = summaryFromMonthlyTotals(rows, month: 2);
      expect(s.income, 2500000.5);
      expect(s.expense, 1000000);
      expect(s.profit, 1500000.5);
      expect(s.txCount, 4);
    });

    test('omzet YTD menjumlah Januari sampai bulan terpilih saja', () {
      expect(summaryFromMonthlyTotals(rows, month: 2).ytdOmzet, 3500000.5);
      expect(summaryFromMonthlyTotals(rows, month: 3).ytdOmzet, 4200000.5);
    });

    test('bulan tanpa baris menghasilkan nol, bukan crash', () {
      final s = summaryFromMonthlyTotals(rows, month: 7);
      expect(s.income, 0);
      expect(s.txCount, 0);
      expect(s.ytdOmzet, 4200000.5);
    });

    test('persentase ambang PKP tetap dihitung model', () {
      final s = summaryFromMonthlyTotals(rows, month: 3);
      expect(s.pkpPercent, closeTo(4200000.5 / 4800000000 * 100, 1e-9));
    });
  });

  group('kpiFromMonthlyTotals', () {
    final rows = <Map<String, dynamic>>[
      {'month': 1, 'income': 1000, 'expense': 400},
      {'month': 3, 'income': 500.5, 'expense': 100},
    ];

    test('satu titik per bulan sampai upToMonth, bulan kosong bernilai nol', () {
      final points = kpiFromMonthlyTotals(rows, KpiMetric.income, upToMonth: 3);
      expect(points.map((p) => p.value), [1000, 0, 500.5]);
    });

    test('profit dan ytd diturunkan dari pemasukan & pengeluaran', () {
      expect(
        kpiFromMonthlyTotals(rows, KpiMetric.profit, upToMonth: 3)
            .map((p) => p.value),
        [600, 0, 400.5],
      );
      expect(
        kpiFromMonthlyTotals(rows, KpiMetric.ytd, upToMonth: 3)
            .map((p) => p.value),
        [1000, 1000, 1500.5],
      );
    });

    test('label bulan pendek Bahasa Indonesia, sama dengan data contoh', () {
      final labels = kpiFromMonthlyTotals(const [], KpiMetric.income,
              upToMonth: 12)
          .map((p) => p.month);
      expect(labels, [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ]);
    });
  });

  group('upcomingDeadlines', () {
    test('Februari masih memuat SPT Tahunan tahun lalu (30 April)', () {
      final result = upcomingDeadlines(
        now: DateTime(2026, 2, 10),
        isPkp: false,
        hasEmployees: false,
        limit: 10,
      );
      final spt = result.singleWhere((d) => d.id == 'spt-2025');
      expect(spt.taxType, 'SPT');
      expect(spt.deadline, DateTime(2026, 4, 30));
    });

    test('urut dari yang terdekat, kode tax_type sesuai kontrak API', () {
      final result = upcomingDeadlines(
        now: DateTime(2026, 2, 10),
        isPkp: false,
        hasEmployees: false,
        limit: 3,
      );
      expect(result, hasLength(3));
      expect(result.first.id, 'ppf-2026-1');
      expect(result.first.taxType, 'PPH_FINAL');
      expect(result.first.deadline, DateTime(2026, 2, 15));
      expect(result.first.status, 'PENDING');
    });

    test('Desember: tenggat masa Desember jatuh di Januari tahun depan', () {
      final result = upcomingDeadlines(
        now: DateTime(2026, 12, 20),
        isPkp: false,
        hasEmployees: true,
        limit: 2,
      );
      expect(result.map((d) => d.id), ['p21-2026-12', 'ppf-2026-12']);
      expect(result.first.taxType, 'PPH21');
      expect(result.first.deadline, DateTime(2027, 1, 10));
    });

    test('tenggat hari ini masih ditampilkan, yang kemarin tidak', () {
      final result = upcomingDeadlines(
        now: DateTime(2026, 3, 15, 10, 30),
        isPkp: false,
        hasEmployees: false,
        limit: 1,
      );
      expect(result.single.id, 'ppf-2026-2');
    });
  });

  group('dateRangeFor', () {
    final now = DateTime(2026, 9, 13);

    test('tanpa filter → null (layar Pencatatan butuh semua transaksi)', () {
      expect(dateRangeFor(now: now), isNull);
    });

    test('bulan & tahun → rentang setengah terbuka', () {
      final r = dateRangeFor(month: 2, year: 2026, now: now)!;
      expect(r.from, '2026-02-01');
      expect(r.until, '2026-03-01');
    });

    test('Desember menyeberang ke Januari tahun berikutnya', () {
      final r = dateRangeFor(month: 12, year: 2026, now: now)!;
      expect(r.until, '2027-01-01');
    });

    test('tahun saja → setahun penuh; bulan saja → tahun berjalan', () {
      expect(dateRangeFor(year: 2025, now: now)!.until, '2026-01-01');
      expect(dateRangeFor(month: 5, now: now)!.from, '2026-05-01');
    });

    test('from/to inklusif: until sehari setelah to, jam diabaikan', () {
      final r = dateRangeFor(
        from: DateTime(2026, 8, 1, 23, 59),
        to: DateTime(2026, 8, 31, 8),
        now: now,
      )!;
      expect(r.from, '2026-08-01');
      expect(r.until, '2026-09-01');
    });

    test('from atau to saja → ujung lainnya terbuka', () {
      expect(dateRangeFor(from: DateTime(2026, 3, 5), now: now)!.until, isNull);
      final r = dateRangeFor(to: DateTime(2026, 12, 31), now: now)!;
      expect(r.from, isNull);
      expect(r.until, '2027-01-01');
    });
  });

  group('monthTotalsFromRows', () {
    test('kolom hpp database jadi cogs kontrak', () {
      final totals = monthTotalsFromRows([
        {'month': 8, 'income': 28500000, 'expense': 18200000.0, 'hpp': 9100000, 'tx_count': 12},
      ]);
      expect(totals.single.month, 8);
      expect(totals.single.cogs, 9100000);
      expect(totals.single.txCount, 12);
    });
  });

  group('oauthRedirectUrl', () {
    test('situs publik: fragment rute dan query dibuang', () {
      expect(
        oauthRedirectUrl(Uri.parse('https://piambak.github.io/catatin/#/login')),
        'https://piambak.github.io/catatin/',
      );
    });

    test('build lokal berport kembali ke dirinya sendiri', () {
      expect(
        oauthRedirectUrl(
            Uri.parse('http://localhost:8012/catatin/?code=abc#/register')),
        'http://localhost:8012/catatin/',
      );
    });

    test('tanpa path tetap berakhir garis miring', () {
      expect(oauthRedirectUrl(Uri.parse('https://catatin.id')),
          'https://catatin.id/');
    });
  });

  group('oauthCallbackError', () {
    test('pengguna menekan batal di halaman Google', () {
      final uri = Uri.parse(
          'https://piambak.github.io/catatin/?error=access_denied&error_description=x');
      expect(oauthCallbackError(uri, hasSession: false),
          'Masuk dengan Google dibatalkan.');
    });

    test('galat lain, termasuk yang dikirim lewat fragment', () {
      final uri = Uri.parse(
          'https://piambak.github.io/catatin/#error=server_error&error_code=500');
      expect(oauthCallbackError(uri, hasSession: false),
          'Masuk dengan Google gagal. Coba lagi.');
    });

    test('kode callback yang gagal ditukar jadi sesi', () {
      final uri = Uri.parse('https://piambak.github.io/catatin/?code=abc');
      expect(oauthCallbackError(uri, hasSession: false),
          'Masuk dengan Google gagal. Coba lagi.');
      expect(oauthCallbackError(uri, hasSession: true), isNull);
    });

    test('halaman biasa tidak dianggap kembalian Google', () {
      expect(
        oauthCallbackError(Uri.parse('https://piambak.github.io/catatin/#/login'),
            hasSession: false),
        isNull,
      );
    });
  });

  group('userFromMetadata', () {
    UserModel user(Map<String, dynamic>? meta, {String? email = 'budi@usaha.com'}) =>
        userFromMetadata(
          id: 'u1',
          email: email,
          metadata: meta,
          createdAt: '2026-09-13T01:00:00Z',
        );

    test('nama dari pendaftaran email', () {
      expect(user({'name': ' Budi '}).name, 'Budi');
    });

    test('akun Google: full_name dan picture', () {
      final u = user({'full_name': 'Budi Santoso', 'picture': 'https://x/p.png'});
      expect(u.name, 'Budi Santoso');
      expect(u.image, 'https://x/p.png');
    });

    test('tanpa nama memakai bagian depan email', () {
      expect(user(null).name, 'budi');
      expect(user({'name': ''}, email: null).name, '');
    });
  });

  test('isUuid menolak id data contoh', () {
    expect(isUuid('3f1c2a9e-8b7d-4c6e-9a5f-1b2c3d4e5f60'), isTrue);
    expect(isUuid('t1'), isFalse);
    expect(isUuid('local-1726200000000'), isFalse);
  });
}
