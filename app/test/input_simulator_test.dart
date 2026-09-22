// test/input_simulator_test.dart
//
// Nilai awal Simulator (issue #89, `GET /simulator/inputs`): aturan jendela
// tiga bulan di simulatorInputsFrom, helper Supabase, repository mock,
// kontrak REST lewat Dio dengan adapter palsu, dan fallback mode hybrid.
//
// Jalankan: flutter test test/input_simulator_test.dart

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
import 'package:shared_preferences/shared_preferences.dart';

/// Baris `monthly_totals` data contoh staging (supabase/staging/data_contoh.sql)
/// Januari–September 2026 — dicek langsung di staging 22 Sep 2026.
const _baris2026 = <Map<String, dynamic>>[
  {'month': 1, 'income': 19200000, 'expense': 16300000, 'hpp': 5800000, 'tx_count': 6},
  {'month': 2, 'income': 21500000, 'expense': 17000000, 'hpp': 6500000, 'tx_count': 6},
  {'month': 3, 'income': 38000000, 'expense': 21900000, 'hpp': 11400000, 'tx_count': 6},
  {'month': 4, 'income': 41300000, 'expense': 22900000, 'hpp': 12400000, 'tx_count': 6},
  {'month': 5, 'income': 44000000, 'expense': 23700000, 'hpp': 13200000, 'tx_count': 6},
  {'month': 6, 'income': 45500000, 'expense': 24200000, 'hpp': 13700000, 'tx_count': 6},
  {'month': 7, 'income': 47000000, 'expense': 24600000, 'hpp': 14100000, 'tx_count': 6},
  {'month': 8, 'income': 28500000, 'expense': 18200000, 'hpp': 6200000, 'tx_count': 12},
  {'month': 9, 'income': 15400000, 'expense': 4750000, 'hpp': 2600000, 'tx_count': 6},
];

/// Contoh balasan di wiki/arsitektur/backend-dan-api.md — hasil aturan di atas
/// untuk September 2026.
const _contoh = {
  'month': 9,
  'year': 2026,
  'average': {
    'from_month': 6,
    'from_year': 2026,
    'to_month': 8,
    'to_year': 2026,
    'months_with_data': 3,
    'tx_count': 24,
    'income': 40333333,
    'expense': 22333333,
    'cogs': 11333333,
  },
  'current_month': {
    'income': 15400000,
    'expense': 4750000,
    'cogs': 2600000,
    'tx_count': 6,
  },
  'ytd_omzet': 300400000,
  'business': {
    'pkp_status': false,
    'employee_count': 3,
    'business_type': 'DAGANG',
  },
};

final _profil = BusinessProfile(
  id: 'biz_01',
  userId: 'usr_01',
  businessName: 'Batik Kencana',
  businessType: 'DAGANG',
  pkpStatus: false,
  employeeCount: 3,
  isActive: true,
  createdAt: DateTime(2026, 1, 15),
);

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

class _FakeSimulator implements SimulatorRepository {
  _FakeSimulator({this.galat});

  final ApiException? galat;
  int dipanggil = 0;

  @override
  Future<SimulatorInputs> getInputs({int? month, int? year}) async {
    dipanggil++;
    if (galat != null) throw galat!;
    return SimulatorInputs.fromJson(_contoh);
  }
}

void main() {
  group('simulatorInputsFromMonthlyTotals — data contoh staging', () {
    final s = simulatorInputsFromMonthlyTotals(
      month: 9,
      year: 2026,
      current: _baris2026,
      business: _profil,
    );

    test('jendela = tiga bulan PENUH sebelum bulan acuan (Jun–Agu)', () {
      expect(s.average.fromMonth, 6);
      expect(s.average.fromYear, 2026);
      expect(s.average.toMonth, 8);
      expect(s.average.toYear, 2026);
      expect(s.average.monthsWithData, 3);
      expect(s.average.txCount, 24);
    });

    test('rata-rata dibulatkan ke rupiah terdekat', () {
      expect(s.average.income, 40333333); // 121.000.000 / 3
      expect(s.average.expense, 22333333);
      expect(s.average.cogs, 11333333);
    });

    test('bulan acuan dan omzet YTD terpisah dari rata-rata', () {
      expect(s.currentMonth.income, 15400000);
      expect(s.currentMonth.expense, 4750000);
      expect(s.currentMonth.cogs, 2600000);
      expect(s.currentMonth.txCount, 6);
      expect(s.ytdOmzet, 300400000);
    });

    test('profil usaha ikut; tanpa profil → null', () {
      expect(s.business?.employeeCount, 3);
      expect(s.business?.pkpStatus, isFalse);
      expect(s.business?.businessType, 'DAGANG');
      final tanpa = simulatorInputsFromMonthlyTotals(
          month: 9, year: 2026, current: _baris2026);
      expect(tanpa.business, isNull);
    });

    test('sama persis dengan contoh kontrak di wiki', () {
      final c = SimulatorInputs.fromJson(_contoh);
      expect(s.average.income, c.average.income);
      expect(s.average.expense, c.average.expense);
      expect(s.average.cogs, c.average.cogs);
      expect(s.average.txCount, c.average.txCount);
      expect(s.currentMonth.income, c.currentMonth.income);
      expect(s.ytdOmzet, c.ytdOmzet);
    });
  });

  group('simulatorInputsFrom — kasus tepi', () {
    YearAggregate agg(int year, List<MonthTotals> totals) =>
        YearAggregate.fromMonthlyTotals(year, totals);

    test('baru satu bulan berdata → dibagi satu, bukan tiga', () {
      final s = simulatorInputsFrom(
        month: 9,
        year: 2026,
        current: agg(2026, [
          (month: 8, income: 9000000, expense: 3000000, cogs: 0, txCount: 4),
        ]),
      );
      expect(s.average.monthsWithData, 1);
      expect(s.average.income, 9000000);
      expect(s.average.txCount, 4);
    });

    test('belum ada data sama sekali → semua nol, bukan galat', () {
      final s = simulatorInputsFrom(month: 9, year: 2026, current: agg(2026, []));
      expect(s.average.monthsWithData, 0);
      expect(s.average.income, 0);
      expect(s.currentMonth.txCount, 0);
      expect(s.ytdOmzet, 0);
    });

    test('Februari: jendela Nov–Jan menyeberang tahun', () {
      final s = simulatorInputsFrom(
        month: 2,
        year: 2027,
        current: agg(2027, [
          (month: 1, income: 3000000, expense: 0, cogs: 0, txCount: 1),
          (month: 2, income: 500000, expense: 0, cogs: 0, txCount: 1),
        ]),
        previous: agg(2026, [
          (month: 11, income: 1000000, expense: 0, cogs: 0, txCount: 1),
          (month: 12, income: 2000000, expense: 0, cogs: 0, txCount: 1),
          (month: 10, income: 99000000, expense: 0, cogs: 0, txCount: 9),
        ]),
      );
      expect((s.average.fromMonth, s.average.fromYear), (11, 2026));
      expect((s.average.toMonth, s.average.toYear), (1, 2027));
      expect(s.average.income, 2000000); // (1 + 2 + 3) juta / 3; Oktober tidak ikut
      expect(s.average.txCount, 3);
      expect(s.ytdOmzet, 3500000); // YTD hanya tahun acuan
    });

    test('Januari: seluruh jendela di tahun sebelumnya', () {
      final s = simulatorInputsFrom(
        month: 1,
        year: 2027,
        current: agg(2027, []),
        previous: agg(2026, [
          (month: 10, income: 3000000, expense: 0, cogs: 0, txCount: 1),
        ]),
      );
      expect((s.average.fromMonth, s.average.fromYear), (10, 2026));
      expect((s.average.toMonth, s.average.toYear), (12, 2026));
      expect(s.average.income, 3000000);
    });

    test('jendela menyeberang tahun tanpa agregat tahun lalu → ArgumentError',
        () {
      expect(
        () => simulatorInputsFrom(month: 3, year: 2027, current: agg(2027, [])),
        throwsArgumentError,
      );
    });
  });

  group('MockSimulatorRepository', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('dari agregat transaksi contoh, termasuk transaksi baru sesi ini',
        () async {
      final income =
          MockData.txCategories.firstWhere((c) => c.type == 'INCOME');
      final tx = MockTransactionRepository();
      for (final (date, amount) in [
        ('2032-11-10', 1000000.0),
        ('2032-12-10', 2000000.0),
        ('2033-01-10', 3000000.0),
        ('2033-02-05', 500000.0),
      ]) {
        await tx.createTransaction(TransactionDraft(
          businessId: 'biz',
          date: date,
          type: 'INCOME',
          amount: amount,
          categoryId: income.id,
          paymentMethod: 'CASH',
        ));
      }

      final s =
          await MockSimulatorRepository().getInputs(month: 2, year: 2033);
      expect(s.average.income, 2000000);
      expect(s.average.monthsWithData, 3);
      expect(s.currentMonth.income, 500000);
      expect(s.ytdOmzet, 3500000);
      expect(s.business, isNull); // belum ada profil di SharedPreferences
    });

    test('bulan tidak valid ditolak juga di mode mock', () {
      expect(
        MockSimulatorRepository().getInputs(month: 0, year: 2026),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('ApiSimulatorRepository (kontrak REST)', () {
    late _FakeAdapter adapter;

    void useFakeServer(Object body) {
      adapter = _FakeAdapter(body);
      ApiClient.instance = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;
    }

    tearDown(ApiClient.reset);

    test('GET /simulator/inputs?month&year membaca contoh kontrak', () async {
      useFakeServer(_contoh);
      final s =
          await ApiSimulatorRepository().getInputs(month: 9, year: 2026);
      final req = adapter.requests.single;
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/v1/simulator/inputs');
      expect(req.uri.queryParameters, {'month': '9', 'year': '2026'});
      expect(s.average.income, 40333333);
      expect(s.average.fromMonth, 6);
      expect(s.currentMonth.txCount, 6);
      expect(s.business?.employeeCount, 3);
    });

    test('business null dibaca sebagai belum punya profil', () async {
      useFakeServer({..._contoh, 'business': null});
      final s =
          await ApiSimulatorRepository().getInputs(month: 9, year: 2026);
      expect(s.business, isNull);
    });

    test('bulan tidak valid gagal SEBELUM permintaan dikirim', () async {
      useFakeServer(_contoh);
      await expectLater(
        ApiSimulatorRepository().getInputs(month: 13, year: 2026),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });

  group('HybridSimulatorRepository', () {
    test('404 (endpoint belum ada) → jatuh ke mock', () async {
      final api = _FakeSimulator(
          galat: const ApiException(statusCode: 404, message: 'x'));
      final mock = _FakeSimulator();
      await HybridSimulatorRepository(api, mock).getInputs(month: 9, year: 2026);
      expect(api.dipanggil, 1);
      expect(mock.dipanggil, 1);
    });

    test('400 (jawaban backend) → naik, mock tidak tersentuh', () async {
      final api = _FakeSimulator(
          galat: const ApiException(statusCode: 400, message: 'x'));
      final mock = _FakeSimulator();
      await expectLater(
        HybridSimulatorRepository(api, mock).getInputs(month: 9, year: 2026),
        throwsA(isA<ApiException>()),
      );
      expect(mock.dipanggil, 0);
    });
  });
}
