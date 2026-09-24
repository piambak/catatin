// test/lapisan_data_test.dart
//
// T-37 & T-28 — kebersihan lapisan data:
//
//   * `ApiException.userMessage` dulu memanggil `.first` pada `errors` —
//     map kosong membuat penanganan galatnya sendiri melempar StateError.
//   * Mode mock dulu mengembalikan transaksi PERTAMA untuk id tak dikenal,
//     sehingga layar detail — dan tombol hapusnya — mengenai transaksi lain.
//   * Log jaringan dulu mencetak `Authorization`, kata sandi, dan token apa
//     adanya; sekarang disamarkan, dan hanya menyala di build debug.
//
// Jalankan: flutter test test/lapisan_data_test.dart

import 'package:catatin/core/config/app_config.dart';
import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.userMessage (400)', () {
    test('errors kosong tidak melempar, jatuh ke pesan umum', () {
      const e = ApiException(statusCode: 400, message: 'x', errors: {});
      expect(e.userMessage, 'Data tidak valid.');
    });

    test('errors berisi → pesan field pertama', () {
      const e = ApiException(
        statusCode: 400,
        message: 'x',
        errors: {'amount': 'Nominal harus lebih dari 0.'},
      );
      expect(e.userMessage, 'Nominal harus lebih dari 0.');
    });
  });

  group('MockTransactionRepository.getTransaction', () {
    test('id tak dikenal → null, bukan transaksi lain', () async {
      final repo = MockTransactionRepository();
      expect(await repo.getTransaction('tidak-ada'), isNull);
    });

    test('id dikenal → transaksi itu sendiri', () async {
      final repo = MockTransactionRepository();
      final tx = await repo.getTransaction('t1');
      expect(tx?.id, 't1');
    });
  });

  group('redactForLog', () {
    test('header & body sensitif disamarkan, sisanya utuh', () {
      final out = redactForLog({
        'Authorization': 'Bearer rahasia',
        'Content-Type': 'application/json',
        'email': 'a@b.c',
        'password': 'rahasia123',
        'user': {'refresh_token': 'rt', 'name': 'Rizal'},
        'list': [
          {'access_token': 'at'},
        ],
      });
      expect(out, {
        'Authorization': '***',
        'Content-Type': 'application/json',
        'email': 'a@b.c',
        'password': '***',
        'user': {'refresh_token': '***', 'name': 'Rizal'},
        'list': [
          {'access_token': '***'},
        ],
      });
    });

    test('nilai bukan map/list dikembalikan apa adanya', () {
      expect(redactForLog('teks'), 'teks');
      expect(redactForLog(null), isNull);
    });
  });

  test('log jaringan mati tanpa ENABLE_API_LOG', () {
    // Tes berjalan tanpa --dart-define, jadi flag-nya false.
    expect(AppConfig.apiLogEnabled, isFalse);
  });
}
