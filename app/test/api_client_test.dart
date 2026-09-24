// test/api_client_test.dart
//
// T-23 — tiga bug berlapis di alur perpanjangan sesi mode REST:
//
//   * Dashboard menembak beberapa request sekaligus. Saat semuanya kena 401,
//     hanya request pertama yang boleh me-refresh; sisanya dulu langsung
//     ditolak "Sesi berakhir" walau refresh-nya berhasil.
//   * Request refresh tetap membawa Bearer kedaluwarsa, padahal server menolak
//     refresh yang membawa Bearer.
//   * Refresh gagal → `clearAll()` = `prefs.clear()`, ikut menghapus tema.
//
// Ditambah D-14: refresh token dirotasi, jadi token baru dari respons wajib
// disimpan — yang lama hangus begitu ditukar.
//
// Server tiruan di bawah menerima Bearer `baru` saja, sehingga setiap request
// dengan token `lama` kena 401 sampai refresh berhasil.
//
// Jalankan: flutter test test/api_client_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:catatin/core/constants/app_constants.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/core/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _RefreshReply { ok, rejected, unavailable, offline }

class _FakeServer implements HttpClientAdapter {
  _FakeServer({this.refreshReply = _RefreshReply.ok});

  final _RefreshReply refreshReply;
  final requests = <RequestOptions>[];
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Jeda kecil supaya request yang ditembak bersamaan benar-benar tumpang
    // tindih saat refresh berjalan.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    if (options.path == ApiEndpoints.refresh) {
      refreshCalls++;
      switch (refreshReply) {
        case _RefreshReply.ok:
          return _json({
            'access_token': 'baru',
            'refresh_token': 'refresh-2',
          }, 200);
        case _RefreshReply.rejected:
          return _json({'error': 'refresh token tidak dikenal'}, 401);
        case _RefreshReply.unavailable:
          return _json({'error': 'bad gateway'}, 502);
        case _RefreshReply.offline:
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
      }
    }

    if (options.headers['Authorization'] == 'Bearer baru') {
      return _json({'ok': true, 'path': options.path}, 200);
    }
    return _json({'error': 'unauthorized'}, 401);
  }

  static ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secure;
  late _FakeServer server;
  late Dio dio;
  late int sessionEnded;

  void useServer(_FakeServer s) {
    server = s;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = server;
    dio.interceptors.add(
      AuthInterceptor(
        dio,
        onSessionEnded: () async {
          sessionEnded++;
        },
      ),
    );
  }

  setUp(() {
    secure = {
      StorageKeys.accessToken: 'lama',
      StorageKeys.refreshToken: 'refresh-1',
    };
    FlutterSecureStorage.setMockInitialValues(secure);
    SharedPreferences.setMockInitialValues({});
    sessionEnded = 0;
  });

  group('AuthInterceptor', () {
    test('401 → refresh → request diulang dan berhasil', () async {
      useServer(_FakeServer());

      final res = await dio.get<dynamic>('/dashboard');

      expect(res.statusCode, 200);
      expect(server.refreshCalls, 1);
      expect(secure[StorageKeys.accessToken], 'baru');
      expect(sessionEnded, 0);
    });

    test('refresh token hasil rotasi disimpan (D-14)', () async {
      useServer(_FakeServer());

      await dio.get<dynamic>('/dashboard');

      expect(secure[StorageKeys.refreshToken], 'refresh-2');
    });

    test(
      'request refresh tidak membawa Bearer, membawa refresh token',
      () async {
        useServer(_FakeServer());

        await dio.get<dynamic>('/dashboard');

        final refresh = server.requests.singleWhere(
          (r) => r.path == ApiEndpoints.refresh,
        );
        expect(refresh.headers.containsKey('Authorization'), isFalse);
        expect(refresh.data, {'refresh_token': 'refresh-1'});
      },
    );

    test(
      'tiga request bersamaan kena 401 → SATU refresh, tiga berhasil',
      () async {
        useServer(_FakeServer());

        final results = await Future.wait([
          dio.get<dynamic>('/dashboard'),
          dio.get<dynamic>('/transactions'),
          dio.get<dynamic>('/business'),
        ]);

        expect(server.refreshCalls, 1);
        expect(results.map((r) => r.statusCode), everyElement(200));
        expect(sessionEnded, 0);
      },
    );

    test(
      'refresh ditolak server → sesi diakhiri sekali, request gagal 401',
      () async {
        useServer(_FakeServer(refreshReply: _RefreshReply.rejected));

        final errors = await Future.wait([
          _errorOf(dio.get<dynamic>('/dashboard')),
          _errorOf(dio.get<dynamic>('/transactions')),
          _errorOf(dio.get<dynamic>('/business')),
        ]);

        expect(server.refreshCalls, 1);
        expect(sessionEnded, 1);
        expect(errors.map((e) => e.statusCode), everyElement(401));
      },
    );

    test(
      'offline saat refresh → sesi TIDAK diakhiri, galat jaringan',
      () async {
        useServer(_FakeServer(refreshReply: _RefreshReply.offline));

        final error = await _errorOf(dio.get<dynamic>('/dashboard'));

        expect(error.statusCode, 0);
        expect(sessionEnded, 0);
        expect(secure[StorageKeys.refreshToken], 'refresh-1');
      },
    );

    test('502 dari gateway saat refresh → sesi TIDAK diakhiri', () async {
      useServer(_FakeServer(refreshReply: _RefreshReply.unavailable));

      final error = await _errorOf(dio.get<dynamic>('/dashboard'));

      expect(error.statusCode, 0);
      expect(sessionEnded, 0);
    });

    test(
      '401 pada request tanpa token (kata sandi salah) → tanpa refresh',
      () async {
        secure.clear();
        useServer(_FakeServer());

        final error = await _errorOf(
          dio.post<dynamic>(
            ApiEndpoints.login,
            data: {'email': 'a@b.c', 'password': 'salah'},
          ),
        );

        expect(error.statusCode, 401);
        expect(server.refreshCalls, 0);
        expect(sessionEnded, 0);
      },
    );
  });

  group('StorageService.clearSession', () {
    test('menghapus sesi dan data akun, mempertahankan tema', () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.themeMode: 'dark',
        StorageKeys.userId: 'u1',
        StorageKeys.businessId: 'b1',
        StorageKeys.onboarded: true,
        StorageKeys.demoMode: false,
      });

      await StorageService.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.themeMode), 'dark');
      expect(prefs.getString(StorageKeys.userId), isNull);
      expect(prefs.getString(StorageKeys.businessId), isNull);
      expect(prefs.getBool(StorageKeys.onboarded), isNull);
      expect(secure, isEmpty);
    });

    test('tanpa tema tersimpan tetap bersih', () async {
      SharedPreferences.setMockInitialValues({StorageKeys.userId: 'u1'});

      await StorageService.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });
  });
}

/// Menunggu request yang diharapkan gagal, lalu mengembalikan galatnya dalam
/// bentuk yang dilihat lapisan data.
Future<ApiException> _errorOf(Future<Object?> request) async {
  try {
    await request;
  } catch (e) {
    return apiException(e);
  }
  fail('request seharusnya gagal');
}
