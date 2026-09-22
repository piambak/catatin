// test/tutup_bulan_test.dart
//
// Ringkasan tutup bulan (issue #74, `GET /dashboard/close?month&year`):
// model, helper Supabase murni, repository mock, kontrak REST lewat Dio
// dengan adapter palsu (pola `transaksi_berulang_test.dart`), dan fallback
// mode hybrid.
//
// Jalankan: flutter test test/tutup_bulan_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:catatin/core/data/api_repositories.dart';
import 'package:catatin/core/data/hybrid_repositories.dart';
import 'package:catatin/core/data/mock_data.dart';
import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/data/supabase_repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contoh balasan di `wiki/arsitektur/backend-dan-api.md` — Agustus data
/// contoh staging.
const _contoh = {
  'month': 8,
  'year': 2026,
  'income': 28500000,
  'expense': 18200000,
  'profit': 10300000,
  'cogs': 6200000,
  'tx_count': 12,
  'ytd_omzet': 285000000,
};

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Dashboard palsu yang hanya tahu [getMonthClose]; metode lain melempar.
class _FakeDashboard implements DashboardRepository {
  _FakeDashboard({this.galat});

  final ApiException? galat;
  int dipanggil = 0;

  @override
  Future<MonthClose> getMonthClose({required int month, required int year}) async {
    dipanggil++;
    if (galat != null) throw galat!;
    return MonthClose.fromJson(_contoh);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('MonthClose.fromJson', () {
    test('membaca contoh kontrak apa adanya', () {
      final c = MonthClose.fromJson(_contoh);
      expect(c.month, 8);
      expect(c.year, 2026);
      expect(c.income, 28500000);
      expect(c.expense, 18200000);
      expect(c.profit, 10300000);
      expect(c.cogs, 6200000);
      expect(c.txCount, 12);
      expect(c.ytdOmzet, 285000000);
    });

    test('profit yang tidak dikirim dihitung dari income − expense', () {
      final c = MonthClose.fromJson({
        'month': 1,
        'year': 2026,
        'income': 1000.5,
        'expense': 400,
      });
      expect(c.profit, 600.5);
      expect(c.cogs, 0);
      expect(c.txCount, 0);
    });
  });

  group('monthCloseFromMonthlyTotals', () {
    // Campuran int dan double, seperti hasil decode angka JSON dari PostgREST.
    final rows = <Map<String, dynamic>>[
      {'month': 1, 'income': 1000000, 'expense': 400000, 'hpp': 100000, 'tx_count': 3},
      {'month': 2, 'income': 2500000.5, 'expense': 1000000, 'hpp': 250000, 'tx_count': 4},
      {'month': 4, 'income': 700000, 'expense': 900000, 'hpp': 0, 'tx_count': 2},
    ];

    test('angka bulan terpilih; kolom hpp menjadi cogs', () {
      final c = monthCloseFromMonthlyTotals(rows, month: 2, year: 2026);
      expect(c.month, 2);
      expect(c.year, 2026);
      expect(c.income, 2500000.5);
      expect(c.expense, 1000000);
      expect(c.profit, 1500000.5);
      expect(c.cogs, 250000);
      expect(c.txCount, 4);
    });

    test('omzet YTD menjumlah pemasukan Januari sampai bulan terpilih', () {
      expect(monthCloseFromMonthlyTotals(rows, month: 2, year: 2026).ytdOmzet,
          3500000.5);
      expect(monthCloseFromMonthlyTotals(rows, month: 4, year: 2026).ytdOmzet,
          4200000.5);
    });

    test('laba boleh negatif', () {
      expect(monthCloseFromMonthlyTotals(rows, month: 4, year: 2026).profit,
          -200000);
    });

    test('bulan tanpa transaksi bernilai nol, bukan galat', () {
      final c = monthCloseFromMonthlyTotals(rows, month: 3, year: 2026);
      expect(c.income, 0);
      expect(c.expense, 0);
      expect(c.cogs, 0);
      expect(c.txCount, 0);
      expect(c.ytdOmzet, 3500000.5);
    });

    test('sama persis dengan summaryFromMonthlyTotals untuk bulan yang sama', () {
      final c = monthCloseFromMonthlyTotals(rows, month: 2, year: 2026);
      final s = summaryFromMonthlyTotals(rows, month: 2);
      expect(c.income, s.income);
      expect(c.expense, s.expense);
      expect(c.profit, s.profit);
      expect(c.ytdOmzet, s.ytdOmzet);
      expect(c.txCount, s.txCount);
    });
  });

  group('checkMonthParam', () {
    for (final month in [0, 13, -1]) {
      test('bulan $month → 400 validation_failed dengan details.month', () {
        expect(
          () => checkMonthParam(month: month),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'validation_failed')
              .having((e) => e.errors?['month'], 'errors.month', isNotNull)),
        );
      });
    }

    test('1 dan 12 diterima', () {
      checkMonthParam(month: 1);
      checkMonthParam(month: 12);
    });
  });

  group('MockDashboardRepository.getMonthClose', () {
    test('sama dengan agregat Pembukuan, termasuk transaksi baru sesi ini',
        () async {
      // Tahun jauh supaya data contoh tidak ikut terhitung.
      final income =
          MockData.txCategories.firstWhere((c) => c.type == 'INCOME');
      final cogs = MockData.txCategories
          .firstWhere((c) => c.type == 'EXPENSE' && c.isCogs);
      final tx = MockTransactionRepository();
      await tx.createTransaction(TransactionDraft(
        businessId: 'biz',
        date: '2031-01-10',
        type: 'INCOME',
        amount: 400000,
        categoryId: income.id,
        paymentMethod: 'CASH',
      ));
      await tx.createTransaction(TransactionDraft(
        businessId: 'biz',
        date: '2031-03-15',
        type: 'INCOME',
        amount: 1000000,
        categoryId: income.id,
        paymentMethod: 'CASH',
      ));
      await tx.createTransaction(TransactionDraft(
        businessId: 'biz',
        date: '2031-03-20',
        type: 'EXPENSE',
        amount: 300000,
        categoryId: cogs.id,
        paymentMethod: 'CASH',
      ));

      final c = await MockDashboardRepository()
          .getMonthClose(month: 3, year: 2031);
      expect(c.income, 1000000);
      expect(c.expense, 300000);
      expect(c.profit, 700000);
      expect(c.cogs, 300000);
      expect(c.txCount, 2);
      expect(c.ytdOmzet, 1400000);

      final agg = await tx.getAggregate(year: 2031);
      expect(c.income, agg[3].income);
      expect(c.ytdOmzet, agg[3].ytdOmzet);
    });

    test('bulan tidak valid ditolak juga di mode mock', () {
      expect(
        MockDashboardRepository().getMonthClose(month: 13, year: 2026),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('ApiDashboardRepository.getMonthClose (kontrak REST)', () {
    late _FakeAdapter adapter;

    void useFakeServer(Object body) {
      adapter = _FakeAdapter(body);
      ApiClient.instance = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;
    }

    tearDown(ApiClient.reset);

    test('GET /dashboard/close?month&year membaca ringkasan', () async {
      useFakeServer(_contoh);
      final c =
          await ApiDashboardRepository().getMonthClose(month: 8, year: 2026);
      final req = adapter.requests.single;
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/v1/dashboard/close');
      expect(req.uri.queryParameters, {'month': '8', 'year': '2026'});
      expect(c.profit, 10300000);
      expect(c.cogs, 6200000);
    });

    test('bulan tidak valid gagal SEBELUM permintaan dikirim', () async {
      useFakeServer(_contoh);
      await expectLater(
        ApiDashboardRepository().getMonthClose(month: 0, year: 2026),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    });
    // Galat 4xx dari server dipetakan interceptor ApiClient, sudah dites
    // lewat apiExceptionFromResponse di kontrak_transaksi_test.dart.
  });

  group('HybridDashboardRepository.getMonthClose', () {
    test('404 (endpoint belum ada) → jatuh ke mock', () async {
      final api = _FakeDashboard(
          galat: const ApiException(statusCode: 404, message: 'x'));
      final mock = _FakeDashboard();
      await HybridDashboardRepository(api, mock)
          .getMonthClose(month: 8, year: 2026);
      expect(api.dipanggil, 1);
      expect(mock.dipanggil, 1);
    });

    test('400 (jawaban backend) → naik, mock tidak tersentuh', () async {
      final api = _FakeDashboard(
          galat: const ApiException(statusCode: 400, message: 'x'));
      final mock = _FakeDashboard();
      await expectLater(
        HybridDashboardRepository(api, mock)
            .getMonthClose(month: 8, year: 2026),
        throwsA(isA<ApiException>()),
      );
      expect(mock.dipanggil, 0);
    });
  });
}
