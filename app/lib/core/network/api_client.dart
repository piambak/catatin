// lib/core/network/api_client.dart
//
// Satu-satunya tempat Dio dikonfigurasi. Di luar `core/data/api_repositories.dart`
// tidak ada yang perlu memanggil kelas ini langsung.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';

// ── Error API ─────────────────────────────────────────────────────────────────

/// Error tunggal yang dilempar seluruh lapisan data.
///
/// `statusCode == 0` berarti gagal di level jaringan (timeout, DNS, offline),
/// bukan respons dari server.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Pesan per field dari `details` galat REST, mis. `{'amount': 'harus > 0'}`.
  final Map<String, dynamic>? errors;

  /// Kode mesin dari galat REST, mis. `validation_failed` — lihat bagian
  /// "Bentuk error" di `wiki/arsitektur/backend-dan-api.md`. `null` untuk galat
  /// jaringan dan mode Supabase.
  final String? code;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
    this.code,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Pesan siap tampil ke pengguna, dalam Bahasa Indonesia.
  String get userMessage {
    switch (statusCode) {
      case 400:
        return errors?.values.first?.toString() ?? 'Data tidak valid.';
      case 401:
        return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
      case 403:
        return 'Anda tidak memiliki akses ke fitur ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return message;
      case 422:
        return 'Data yang dikirim tidak valid.';
      case 429:
        return 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.';
      case 500:
        return 'Terjadi kesalahan server. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Periksa koneksi internet Anda.';
    }
  }
}

// ── Dio ───────────────────────────────────────────────────────────────────────

class ApiClient {
  ApiClient._();

  /// Dipanggil saat server menolak refresh token — sesi benar-benar berakhir.
  ///
  /// Dipasang `AuthService` supaya penjaga rute ikut bereaksi dan pengguna
  /// dibawa ke layar masuk, bukan ditinggal di layar yang semua request-nya
  /// gagal (T-23). Lapisan jaringan tidak mengimpor `AuthService` langsung
  /// supaya arah ketergantungannya tetap satu: layanan → jaringan.
  static Future<void> Function()? onSessionEnded;

  static Dio? _instance;

  static Dio get instance => _instance ??= _createDio();

  /// Dipakai tes untuk memasang Dio tiruan.
  static set instance(Dio dio) => _instance = dio;

  static void reset() => _instance = null;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(AuthInterceptor(
      dio,
      onSessionEnded: () =>
          (ApiClient.onSessionEnded ?? StorageService.clearSession)(),
    ));

    if (AppConfig.enableApiLog) {
      dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }

    return dio;
  }

  static Future<Response<T>> get<T>(String path,
          {Map<String, dynamic>? params}) =>
      instance.get<T>(path, queryParameters: params);

  static Future<Response<T>> post<T>(String path, {dynamic data}) =>
      instance.post<T>(path, data: data);

  static Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      instance.patch<T>(path, data: data);

  static Future<Response<T>> delete<T>(String path) => instance.delete<T>(path);
}

// ── Interceptor auth — menyisipkan JWT dan menangani 401 ──────────────────────

/// Menyisipkan access token ke setiap request dan memperbarui sesi saat 401.
///
/// Tiga aturan, masing-masing menutup satu lapis T-23:
///
/// 1. **Satu refresh untuk semua.** Dashboard menembak beberapa request
///    sekaligus; kalau semuanya kena 401, hanya satu yang memanggil
///    `/auth/refresh`. Sisanya MENUNGGU hasil refresh itu lalu diulang — dulu
///    mereka langsung ditolak "Sesi berakhir" walau refresh-nya berhasil.
/// 2. **Refresh tanpa Bearer.** Request refresh ditandai
///    `extra[skipAuthKey] = true`; [onRequest] lalu tidak menyisipkan (dan
///    membuang) header `Authorization`. Server menolak refresh yang membawa
///    Bearer — lihat `wiki/arsitektur/backend-dan-api.md` bagian
///    `POST /auth/refresh`.
/// 3. **Rotasi dihormati (D-14).** Refresh token baru dari respons disimpan
///    menggantikan yang lama; yang lama sudah hangus begitu ditukar.
///
/// Sesi hanya diakhiri ([onSessionEnded]) kalau SERVER menolak refresh.
/// Gagal jaringan saat refresh dilaporkan sebagai galat jaringan biasa —
/// pengguna yang sebentar offline tidak boleh ikut dikeluarkan.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.dio, {Future<void> Function()? onSessionEnded})
      : _onSessionEnded = onSessionEnded ?? StorageService.clearSession;

  /// Tandai request yang tidak boleh membawa access token (mis. refresh).
  static const skipAuthKey = 'skipAuth';

  /// Request yang sudah diulang sekali sesudah refresh — tidak diulang lagi.
  static const _retriedKey = 'authRetried';

  final Dio dio;
  final Future<void> Function() _onSessionEnded;

  /// Refresh yang sedang berjalan; `null` kalau tidak ada.
  Completer<_Refresh>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null) {
      // Gagal di level jaringan.
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const ApiException(
            statusCode: 0,
            message: 'Tidak dapat terhubung ke server.',
          ),
        ),
      );
      return;
    }

    final statusCode = response.statusCode ?? 0;
    final options = err.requestOptions;
    if (statusCode == 401 &&
        options.extra[skipAuthKey] != true &&
        options.extra[_retriedKey] != true) {
      switch (await _renewSession(options)) {
        case _Refresh.renewed:
          options.extra[_retriedKey] = true;
          try {
            // Header diisi ulang onRequest dari token yang baru disimpan.
            handler.resolve(await dio.fetch<dynamic>(options));
          } on DioException catch (e) {
            handler.reject(e);
          }
          return;
        case _Refresh.offline:
          // Sesinya mungkin masih sah; yang gagal jaringannya.
          handler.reject(
            DioException(
              requestOptions: options,
              error: const ApiException(
                statusCode: 0,
                message: 'Tidak dapat terhubung ke server.',
              ),
            ),
          );
          return;
        case _Refresh.rejected:
          break;
      }
    }

    handler.reject(
      DioException(
        requestOptions: options,
        response: response,
        error: apiExceptionFromResponse(statusCode, response.data),
      ),
    );
  }

  /// Memastikan ada access token yang lebih baru dari yang dipakai [failed]:
  /// hasil refresh yang dijalankan request ini, refresh milik request lain
  /// yang ditunggu, atau refresh yang sudah selesai sebelum 401 ini tiba.
  ///
  /// Request yang dikirim TANPA token (mis. `/auth/login` dengan kata sandi
  /// salah) tidak punya sesi untuk diperbarui: 401-nya diteruskan apa adanya.
  Future<_Refresh> _renewSession(RequestOptions failed) async {
    final used = failed.headers['Authorization'];
    if (used == null) return _Refresh.rejected;
    final current = await StorageService.getAccessToken();
    if (_refreshing == null &&
        current != null &&
        used != 'Bearer $current') {
      return _Refresh.renewed;
    }
    return _refreshOnce();
  }

  Future<_Refresh> _refreshOnce() {
    final running = _refreshing;
    if (running != null) return running.future;

    final completer = Completer<_Refresh>();
    _refreshing = completer;
    unawaited(_refresh().then(
      completer.complete,
      onError: (Object _) => completer.complete(_Refresh.rejected),
    ).whenComplete(() {
      _refreshing = null;
    }));
    return completer.future;
  }

  Future<_Refresh> _refresh() async {
    final refreshToken = await StorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _onSessionEnded();
      return _Refresh.rejected;
    }
    try {
      final res = await dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {skipAuthKey: true}),
      );
      final data = res.data;
      final access = data is Map ? data['access_token'] : null;
      if (access is! String || access.isEmpty) {
        throw const FormatException('respons /auth/refresh tanpa access_token');
      }
      final rotated = data['refresh_token'];
      await StorageService.saveTokens(
        accessToken: access,
        refreshToken:
            rotated is String && rotated.isNotEmpty ? rotated : refreshToken,
      );
      return _Refresh.renewed;
    } on DioException catch (e) {
      // Tanpa jawaban server (offline, timeout) → biarkan sesinya; request
      // aslinya gagal sebagai galat jaringan. Server menjawab dan menolak →
      // sesi memang habis.
      if (e.response == null) return _Refresh.offline;
      await _onSessionEnded();
      return _Refresh.rejected;
    } on FormatException catch (e) {
      debugPrint('[Catatin] refresh gagal: ${e.message}');
      await _onSessionEnded();
      return _Refresh.rejected;
    }
  }
}

/// Hasil satu upaya memperbarui sesi.
enum _Refresh {
  /// Token baru tersimpan; request boleh diulang.
  renewed,

  /// Server menolak (atau tidak ada refresh token) — sesi berakhir.
  rejected,

  /// Server tidak terjangkau; sesi dibiarkan apa adanya.
  offline,
}

// ── Helper ────────────────────────────────────────────────────────────────────

/// Body galat REST → [ApiException], mengikuti bentuk
/// `{ "error": …, "code": …, "details": { field: pesan } }`.
///
/// `message` diterima sebagai alias `error`. `details` yang bukan objek atau
/// kosong dibuang, supaya [ApiException.errors] hanya pernah berisi pesan per
/// field yang benar-benar ada.
ApiException apiExceptionFromResponse(int statusCode, Object? data) {
  if (data is! Map) {
    return ApiException(statusCode: statusCode, message: 'Error');
  }
  final details = data['details'];
  final code = data['code'];
  return ApiException(
    statusCode: statusCode,
    message: (data['error'] ?? data['message'] ?? 'Error').toString(),
    errors: details is Map<String, dynamic> && details.isNotEmpty
        ? details
        : null,
    code: code is String ? code : null,
  );
}

/// Mengambil [ApiException] dari error apa pun yang keluar dari Dio.
ApiException apiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return const ApiException(
      statusCode: 0, message: 'Terjadi kesalahan tak terduga.');
}
