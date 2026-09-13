// lib/core/network/supabase_client.dart
//
// Satu-satunya tempat klien Supabase dikonfigurasi — padanan `api_client.dart`
// untuk `DATA_SOURCE=supabase`. Di luar `core/data/supabase_repositories.dart`
// dan penyiapan sesi di `AuthService`, tidak ada yang perlu menyentuhnya.
//
// Kenapa galatnya diterjemahkan: seluruh lapisan di atas `core/data/` hanya
// mengenal [ApiException]. Dengan begitu layar yang sudah menangani galat mode
// `api` langsung bekerja untuk Supabase tanpa disunting.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_config.dart';
import 'api_client.dart';

class SupabaseBackend {
  SupabaseBackend._();

  /// Hanya boleh dipakai setelah [init] selesai.
  static sb.SupabaseClient get client => sb.Supabase.instance.client;

  /// Menyiapkan klien. Dipanggil `main.dart` sebelum repository pertama dibuat,
  /// dan hanya bila `AppConfig.dataSource == DataSource.supabase` — mode lain
  /// tidak memuat Supabase sama sekali.
  static Future<void> init() async {
    await sb.Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      postgrestOptions: const sb.PostgrestClientOptions(
        requestTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
        // Bawaannya mengulang 3 kali dengan jeda 1/2/4 detik, jadi pengguna
        // menunggu lama sebelum melihat pesan "periksa koneksi".
        retryCount: 1,
      ),
      authOptions: const sb.FlutterAuthClientOptions(
        // Tidak ada alur masuk lewat tautan (magic link, OAuth), jadi pengamat
        // deep link tidak perlu dinyalakan.
        detectSessionInUri: false,
      ),
      debug: AppConfig.enableApiLog,
    );
  }

  /// Apakah klien Supabase sedang memegang sesi.
  static bool get hasSession => client.auth.currentSession != null;

  /// Memanggil [onSignedOut] setiap Supabase mengakhiri sesi dari sisinya
  /// sendiri — refresh token dicabut atau kedaluwarsa, bukan hanya saat
  /// pengguna menekan "Keluar".
  static StreamSubscription<sb.AuthState> listenSignedOut(
    void Function() onSignedOut,
  ) {
    return client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == sb.AuthChangeEvent.signedOut) onSignedOut();
      },
      // Tanpa onError, galat di stream ini (mis. refresh gagal karena offline)
      // naik sebagai exception yang tidak tertangani.
      onError: (Object error, StackTrace _) {
        if (kDebugMode) debugPrint('[Catatin] auth Supabase: $error');
      },
    );
  }
}

/// Menjalankan [call], menerjemahkan galat Supabase jadi [ApiException].
///
/// Galat yang bukan urusan jaringan atau server — mis. `TypeError` dari
/// `fromJson` — dilempar apa adanya supaya bug pemrograman tetap kelihatan.
Future<T> runSupabase<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (error) {
    final mapped = supabaseException(
      error,
      hasSession: SupabaseBackend.hasSession,
    );
    if (mapped == null) rethrow;
    throw mapped;
  }
}

// ── Penerjemah galat ──────────────────────────────────────────────────────────

const _offline = ApiException(
  statusCode: 0,
  message: 'Tidak dapat terhubung ke server.',
);

const _sessionEnded = ApiException(
  statusCode: 401,
  message: 'Sesi berakhir.',
);

/// Menerjemahkan galat klien Supabase jadi [ApiException].
///
/// Mengembalikan `null` untuk galat yang tidak dikenal. Pesan untuk status 409
/// ditulis dalam Bahasa Indonesia karena [ApiException.userMessage]
/// menampilkannya apa adanya; status 400 membawa pesan per field di `errors`.
///
/// [hasSession] membedakan "tidak punya izin" dari "sesi sudah habis": tanpa
/// sesi, penolakan RLS (`42501`) berarti pengguna perlu masuk lagi.
ApiException? supabaseException(Object error, {required bool hasSession}) {
  if (error is ApiException) return error;
  if (error is sb.AuthException) return _fromAuth(error);
  if (error is sb.PostgrestException) {
    return _fromPostgrest(error, hasSession: hasSession);
  }
  if (error is http.ClientException || error is TimeoutException) {
    return _offline;
  }
  return null;
}

ApiException _fromAuth(sb.AuthException e) {
  if (e is sb.AuthSessionMissingException) return _sessionEnded;
  if (e is sb.AuthRetryableFetchException) {
    // Tanpa status berarti request tidak pernah sampai ke server.
    return e.statusCode == null
        ? _offline
        : ApiException(statusCode: 500, message: e.message);
  }

  switch (e.code) {
    case 'invalid_credentials':
      return const ApiException(
        statusCode: 400,
        message: 'Email atau kata sandi salah.',
        errors: {'email': 'Email atau kata sandi salah.'},
      );
    case 'user_already_exists':
    case 'email_exists':
      return const ApiException(
        statusCode: 409,
        message: 'Email sudah terdaftar. Silakan masuk.',
      );
    case 'email_not_confirmed':
      return const ApiException(
        statusCode: 409,
        message: 'Email belum dikonfirmasi. Buka tautan di email Anda, '
            'lalu masuk.',
      );
    case 'signup_disabled':
      return const ApiException(
        statusCode: 409,
        message: 'Pendaftaran akun baru sedang ditutup.',
      );
    case 'weak_password':
      return const ApiException(
        statusCode: 400,
        message: 'Kata sandi terlalu lemah.',
        errors: {'password': 'Kata sandi terlalu lemah. Pakai yang lebih panjang.'},
      );
    case 'email_address_invalid':
      return const ApiException(
        statusCode: 400,
        message: 'Format email tidak valid.',
        errors: {'email': 'Format email tidak valid.'},
      );
    case 'validation_failed':
      return const ApiException(statusCode: 400, message: 'Data tidak valid.');
    case 'session_not_found':
    case 'session_expired':
    case 'refresh_token_not_found':
    case 'refresh_token_already_used':
    case 'bad_jwt':
    case 'invalid_jwt':
      return _sessionEnded;
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return const ApiException(
        statusCode: 429,
        message: 'Terlalu banyak percobaan.',
      );
  }

  final status = int.tryParse(e.statusCode ?? '');
  if (status == 429) {
    return const ApiException(statusCode: 429, message: 'Terlalu banyak percobaan.');
  }
  if (status == 409) {
    return const ApiException(
      statusCode: 409,
      message: 'Permintaan bentrok dengan data yang sudah ada.',
    );
  }
  _debugUnmapped(e);
  return ApiException(statusCode: status ?? 500, message: e.message);
}

ApiException _fromPostgrest(
  sb.PostgrestException e, {
  required bool hasSession,
}) {
  switch (e.code) {
    // JWT tidak valid / kedaluwarsa, atau request anonim ditolak.
    case 'PGRST301':
    case 'PGRST302':
    case 'PGRST303':
      return _sessionEnded;
    case '42501':
      // Penolakan RLS atau GRANT. Tanpa sesi, penyebabnya hampir pasti sesi
      // yang sudah habis, bukan data orang lain.
      return hasSession
          ? const ApiException(statusCode: 403, message: 'Akses ditolak.')
          : _sessionEnded;
    case 'PGRST116':
      return const ApiException(statusCode: 404, message: 'Data tidak ditemukan.');
    case '23505':
      return const ApiException(
        statusCode: 409,
        message: 'Data yang sama sudah tersimpan.',
      );
    case '22003':
      return const ApiException(
        statusCode: 400,
        message: 'Nominal terlalu besar.',
        errors: {'amount': 'Nominal terlalu besar.'},
      );
    case '23514': // check violation
    case '23502': // not null violation
    case '23503': // foreign key violation
    case '22P02': // format teks tidak valid, mis. UUID
    case '22007': // format tanggal tidak valid
    case '22008': // tanggal di luar rentang
      return const ApiException(statusCode: 400, message: 'Data tidak valid.');
  }
  _debugUnmapped(e);
  return ApiException(statusCode: 500, message: e.message);
}

/// Galat yang tidak dikenali jatuh ke pesan umum di UI; di mode debug pesan
/// aslinya dicetak supaya penyebabnya — mis. migrasi yang belum di-push —
/// tidak hilang.
void _debugUnmapped(Object error) {
  if (kDebugMode) debugPrint('[Catatin] galat Supabase tak dipetakan: $error');
}
