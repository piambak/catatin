// lib/core/network/api_client.dart
//
// Satu-satunya tempat Dio dikonfigurasi. Di luar `core/data/api_repositories.dart`
// tidak ada yang perlu memanggil kelas ini langsung.

import 'package:dio/dio.dart';
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

    dio.interceptors.add(_AuthInterceptor(dio));

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

class _AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;

      // Coba perpanjang sesi sekali saat 401.
      if (statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await StorageService.getRefreshToken();
          if (refreshToken != null) {
            final res = await dio.post(
              ApiEndpoints.refresh,
              data: {'refresh_token': refreshToken},
              options: Options(headers: {'Authorization': null}),
            );
            final newToken = res.data['access_token'] as String;
            await StorageService.saveTokens(
              accessToken: newToken,
              refreshToken: refreshToken,
            );
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retry = await dio.fetch(err.requestOptions);
            _isRefreshing = false;
            handler.resolve(retry);
            return;
          }
        } catch (_) {
          await StorageService.clearAll();
        }
        _isRefreshing = false;
      }

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: apiExceptionFromResponse(statusCode, err.response!.data),
        ),
      );
      return;
    }

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
  }
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
