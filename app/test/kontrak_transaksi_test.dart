// test/kontrak_transaksi_test.dart
//
// Kontrak transaksi yang ditambahkan untuk issue #19: filter rentang tanggal
// `from`/`to`, agregat tahunan `GET /transactions/aggregate`, dan bentuk galat
// REST yang seragam. Contoh JSON di sini sama dengan contoh di
// `wiki/arsitektur/backend-dan-api.md` — kalau salah satunya berubah, ubah
// keduanya.
//
// Tanpa jaringan: mode REST dites dengan Dio yang adapter HTTP-nya palsu.
//
// Jalankan: flutter test test/kontrak_transaksi_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:catatin/core/data/api_repositories.dart';
import 'package:catatin/core/data/mock_data.dart';
import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contoh item `GET /transactions` dari wiki.
const _sampleTransaction = {
  'id': 'trx_01',
  'business_id': 'biz_01',
  'date': '2026-08-05',
  'type': 'INCOME',
  'amount': 5200000,
  'category': {
    'id': 'ic1',
    'name': 'Penjualan Produk',
    'type': 'INCOME',
    'tax_relevant': true,
    'is_cogs': false,
    'icon': '🛍️',
    'color': '#059669',
  },
  'description': 'Penjualan produk online',
  'payment_method': 'QRIS',
  'receipt_note': null,
  'created_at': '2026-08-05T10:12:00Z',
};

/// Contoh `GET /transactions/aggregate?year=2026` dari wiki, dipotong ke tiga
/// bulan pertama supaya ringkas.
const _sampleAggregate = {
  'year': 2026,
  'months': [
    {
      'month': 1,
      'income': 19200000,
      'expense': 16300000,
      'cogs': 5800000,
      'tx_count': 6,
      'ytd_omzet': 19200000,
    },
    {
      'month': 2,
      'income': 21500000,
      'expense': 17000000,
      'cogs': 6500000,
      'tx_count': 6,
      'ytd_omzet': 40700000,
    },
    {
      'month': 3,
      'income': 38000000,
      'expense': 21900000,
      'cogs': 11400000,
      'tx_count': 6,
      'ytd_omzet': 78700000,
    },
  ],
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
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('checkTransactionFilter', () {
    test('from/to tidak boleh dicampur dengan month/year', () {
      expect(
        () => checkTransactionFilter(year: 2026, from: DateTime(2026, 1, 1)),
        throwsArgumentError,
      );
      expect(
        () => checkTransactionFilter(month: 8, to: DateTime(2026, 8, 31)),
        throwsArgumentError,
      );
    });

    test(
      'to sebelum from ditolak; hari yang sama boleh walau jamnya mundur',
      () {
        expect(
          () => checkTransactionFilter(
            from: DateTime(2026, 8, 2),
            to: DateTime(2026, 8, 1),
          ),
          throwsArgumentError,
        );
        checkTransactionFilter(
          from: DateTime(2026, 8, 1, 18),
          to: DateTime(2026, 8, 1, 7),
        );
      },
    );
  });

  group('YearAggregate', () {
    final aggregate = YearAggregate.fromMonthlyTotals(2026, [
      (
        month: 1,
        income: 19200000,
        expense: 12400000,
        cogs: 6100000,
        txCount: 9,
      ),
      (
        month: 3,
        income: 38000000,
        expense: 22800000,
        cogs: 12500000,
        txCount: 11,
      ),
    ]);

    test('selalu 12 bulan; bulan tanpa angka bernilai nol', () {
      expect(aggregate.months, hasLength(12));
      expect(aggregate[2].income, 0);
      expect(aggregate[2].txCount, 0);
      expect(aggregate[12].month, 12);
    });

    test('omzet YTD menjumlah pemasukan sampai bulan itu', () {
      expect(aggregate[1].ytdOmzet, 19200000);
      expect(aggregate[2].ytdOmzet, 19200000);
      expect(aggregate[3].ytdOmzet, 57200000);
      expect(aggregate[12].ytdOmzet, aggregate.totalIncome);
    });

    test('laba dan total diturunkan dari angka bulanan', () {
      expect(aggregate[3].profit, 15200000);
      expect(aggregate.totalExpense, 35200000);
      expect(aggregate.totalCogs, 18600000);
      expect(aggregate.totalTxCount, 20);
    });

    test('fromJson membaca contoh kontrak', () {
      final parsed = YearAggregate.fromJson(_sampleAggregate);
      expect(parsed.year, 2026);
      expect(parsed[2].income, 21500000);
      expect(parsed[2].ytdOmzet, 40700000);
      expect(parsed[3].cogs, 11400000);
    });
  });

  group('apiExceptionFromResponse', () {
    test('bentuk lengkap: pesan, kode, dan pesan per field', () {
      final e = apiExceptionFromResponse(400, {
        'error': 'Data tidak valid',
        'code': 'validation_failed',
        'details': {'to': 'harus sama dengan atau setelah from'},
      });
      expect(e.statusCode, 400);
      expect(e.code, 'validation_failed');
      expect(e.message, 'Data tidak valid');
      expect(e.userMessage, 'harus sama dengan atau setelah from');
    });

    test('message diterima sebagai alias error', () {
      final e = apiExceptionFromResponse(409, {
        'message': 'Email sudah terdaftar',
      });
      expect(e.message, 'Email sudah terdaftar');
      expect(e.code, isNull);
    });

    test('details kosong atau bukan objek dibuang', () {
      expect(
        apiExceptionFromResponse(400, {
          'error': 'x',
          'details': {},
        }).userMessage,
        'Data tidak valid.',
      );
      expect(
        apiExceptionFromResponse(400, {
          'error': 'x',
          'details': ['a'],
        }).errors,
        isNull,
      );
    });

    test('body bukan JSON objek tetap jadi ApiException', () {
      final e = apiExceptionFromResponse(502, '<html>Bad Gateway</html>');
      expect(e.statusCode, 502);
      expect(e.message, 'Error');
    });
  });

  group('MockTransactionRepository', () {
    final repo = MockTransactionRepository();

    test('rentang from/to inklusif per tanggal, jam diabaikan', () async {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day - 6, 23, 59);
      final to = DateTime(now.year, now.month, now.day - 2);
      final txs = await repo.getTransactions(from: from, to: to);
      final ids = txs.map((t) => t.id).toSet();
      // t2 = 2 hari lalu, t3 = 5 hari lalu, t4 = 6 hari lalu (lihat MockData).
      expect(ids, containsAll(['t2', 't3', 't4']));
      expect(ids, isNot(contains('t1')));
      expect(ids, isNot(contains('t5')));
    });

    test('campuran filter gagal juga di mode mock', () {
      expect(
        () => repo.getTransactions(month: 1, from: DateTime(2026)),
        throwsArgumentError,
      );
    });

    test('agregat tahunan konsisten dengan daftar transaksi', () async {
      final year = DateTime.now().year;
      final aggregate = await repo.getAggregate(year: year);
      final txs = MockData.transactions.where((t) => t.date.year == year);
      final income = txs
          .where((t) => t.isIncome)
          .fold<double>(0, (sum, t) => sum + t.amount);
      expect(aggregate.months, hasLength(12));
      expect(aggregate.totalIncome, income);
      expect(aggregate.totalTxCount, txs.length);
    });
  });

  group('ApiTransactionRepository (kontrak REST)', () {
    late _FakeAdapter adapter;

    void useFakeServer(Object body) {
      adapter = _FakeAdapter(body);
      ApiClient.instance = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;
    }

    tearDown(ApiClient.reset);

    test('tanpa filter tidak mengirim query apa pun', () async {
      useFakeServer({
        'transactions': [_sampleTransaction],
      });
      final txs = await ApiTransactionRepository().getTransactions();
      expect(adapter.requests.single.uri.queryParameters, isEmpty);
      expect(txs.single.category.name, 'Penjualan Produk');
      expect(txs.single.amount, 5200000);
    });

    test('from/to dikirim sebagai YYYY-MM-DD', () async {
      useFakeServer({'transactions': <Object>[]});
      await ApiTransactionRepository().getTransactions(
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 31, 17, 30),
      );
      expect(adapter.requests.single.uri.queryParameters, {
        'from': '2026-08-01',
        'to': '2026-08-31',
      });
    });

    test('agregat memanggil /transactions/aggregate?year=', () async {
      useFakeServer(_sampleAggregate);
      final aggregate = await ApiTransactionRepository().getAggregate(
        year: 2026,
      );
      final uri = adapter.requests.single.uri;
      expect(uri.path, '/api/v1/transactions/aggregate');
      expect(uri.queryParameters, {'year': '2026'});
      expect(aggregate[1].income, 19200000);
    });
  });
}
