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
  });

  test('isUuid menolak id data contoh', () {
    expect(isUuid('3f1c2a9e-8b7d-4c6e-9a5f-1b2c3d4e5f60'), isTrue);
    expect(isUuid('t1'), isFalse);
    expect(isUuid('local-1726200000000'), isFalse);
  });
}
