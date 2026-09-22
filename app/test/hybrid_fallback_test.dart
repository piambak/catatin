// test/hybrid_fallback_test.dart
//
// T-16 & T-24. Mode `hybrid` dulu menangkap SETIAP ApiException lalu jatuh ke
// implementasi mock. Dua akibatnya:
//
//   * kata sandi salah → backend 401 → `mock.login()` yang menerima kredensial
//     apa pun → pengguna "masuk" sebagai pengguna demo;
//   * backend menolak transaksi (400/422) → ditulis ke mock in-memory → UI
//     bilang "berhasil" → transaksi hilang saat halaman dimuat ulang.
//
// Tes ini mengunci aturan barunya: fallback HANYA untuk statusCode 0/404/501
// ("endpoint belum ada / tidak terjangkau"), dan TIDAK PERNAH untuk auth.
//
// Yang diperiksa bukan sekadar "exception dilempar", tapi juga bahwa jalur mock
// sama sekali tidak tersentuh — dua hal yang berbeda.
//
// Jalankan: flutter test test/hybrid_fallback_test.dart

import 'package:catatin/core/data/hybrid_repositories.dart';
import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Palsu seperlunya ─────────────────────────────────────────────────────────
// noSuchMethod dipakai supaya tes tidak perlu mengimplementasikan seluruh
// antarmuka; metode yang tidak dipanggil akan melempar kalau tersentuh.

final _sesi = AuthResponse(
  accessToken: 'a',
  refreshToken: 'r',
  user: UserModel(
    id: 'u1',
    name: 'Uji',
    email: 'uji@contoh.id',
    createdAt: DateTime(2026, 1, 1),
  ),
);

class _FakeAuth implements AuthRepository {
  _FakeAuth({this.galat});

  final ApiException? galat;
  int loginDipanggil = 0;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    loginDipanggil++;
    if (galat != null) throw galat!;
    return _sesi;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeTx implements TransactionRepository {
  _FakeTx({this.galat});

  final ApiException? galat;
  int createDipanggil = 0;
  int getDipanggil = 0;

  @override
  Future<bool> createTransaction(TransactionDraft draft) async {
    createDipanggil++;
    if (galat != null) throw galat!;
    return true;
  }

  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) async {
    getDipanggil++;
    if (galat != null) throw galat!;
    return const <TxData>[];
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

const _draft = TransactionDraft(
  businessId: 'b1',
  date: '2026-09-18',
  type: 'INCOME',
  amount: 10000,
  categoryId: 'c1',
  paymentMethod: 'CASH',
);

void main() {
  group('Auth tidak pernah jatuh ke mock', () {
    test('401 dilempar, mock.login tidak disentuh', () async {
      final api = _FakeAuth(
          galat: const ApiException(statusCode: 401, message: 'salah'));
      final mock = _FakeAuth();
      final hybrid = HybridAuthRepository(api, mock);

      await expectLater(
        hybrid.login(email: 'a@b.id', password: 'salah'),
        throwsA(isA<ApiException>()),
      );
      expect(mock.loginDipanggil, 0,
          reason: 'kata sandi salah tidak boleh membuka sesi demo');
    });

    test('jaringan mati (statusCode 0) pun tetap dilempar', () async {
      final api = _FakeAuth(
          galat: const ApiException(statusCode: 0, message: 'offline'));
      final mock = _FakeAuth();
      final hybrid = HybridAuthRepository(api, mock);

      await expectLater(
        hybrid.login(email: 'a@b.id', password: 'x'),
        throwsA(isA<ApiException>()),
      );
      expect(mock.loginDipanggil, 0);
    });
  });

  group('Operasi tulis tidak menelan penolakan backend', () {
    test('422 dilempar, tidak ditulis ke mock', () async {
      final api = _FakeTx(
          galat: const ApiException(statusCode: 422, message: 'tidak valid'));
      final mock = _FakeTx();
      final hybrid = HybridTransactionRepository(api, mock);

      await expectLater(
        hybrid.createTransaction(_draft),
        throwsA(isA<ApiException>()),
      );
      expect(mock.createDipanggil, 0,
          reason: 'penolakan validasi tidak boleh dilaporkan berhasil');
    });

    test('404 (endpoint belum ada) memang jatuh ke mock', () async {
      final api = _FakeTx(
          galat: const ApiException(statusCode: 404, message: 'belum ada'));
      final mock = _FakeTx();
      final hybrid = HybridTransactionRepository(api, mock);

      expect(await hybrid.createTransaction(_draft), isTrue);
      expect(mock.createDipanggil, 1);
    });
  });

  group('Operasi baca', () {
    test('500 dilempar, bukan disamarkan data contoh', () async {
      final api = _FakeTx(
          galat: const ApiException(statusCode: 500, message: 'server'));
      final mock = _FakeTx();
      final hybrid = HybridTransactionRepository(api, mock);

      await expectLater(
        hybrid.getTransactions(),
        throwsA(isA<ApiException>()),
      );
      expect(mock.getDipanggil, 0);
    });

    test('jaringan mati jatuh ke mock', () async {
      final api = _FakeTx(
          galat: const ApiException(statusCode: 0, message: 'offline'));
      final mock = _FakeTx();
      final hybrid = HybridTransactionRepository(api, mock);

      expect(await hybrid.getTransactions(), isEmpty);
      expect(mock.getDipanggil, 1);
    });
  });
}
