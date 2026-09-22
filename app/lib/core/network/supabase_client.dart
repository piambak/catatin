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
import 'browser_url.dart';

class SupabaseBackend {
  SupabaseBackend._();

  /// Hanya boleh dipakai setelah [init] selesai.
  static sb.SupabaseClient get client => sb.Supabase.instance.client;

  /// Menyiapkan klien. Dipanggil `main.dart` sebelum repository pertama dibuat,
  /// dan hanya bila `AppConfig.dataSource == DataSource.supabase` — mode lain
  /// tidak memuat Supabase sama sekali.
  static Future<void> init() async {
    // Dibaca sebelum initialize: Supabase membersihkan parameter callback dari
    // alamat begitu kodenya ditukar.
    final startUri = Uri.base;

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
        // Wajib untuk masuk dengan Google. Di web, initialize menunggu `?code=`
        // di alamat awal ditukar jadi sesi; di Android, deep link callback
        // ditukar saat aplikasi menerimanya.
        detectSessionInUri: true,
      ),
      debug: AppConfig.enableApiLog,
    );

    if (kIsWeb) {
      oauthError = oauthCallbackError(startUri, hasSession: hasSession);
      if (oauthError != null) clearUrlQuery();
    }
  }

  /// Pesan untuk pengguna kalau halaman ini dibuka sebagai kembalian masuk
  /// dengan Google yang gagal atau dibatalkan. Diisi [init] (web).
  static String? oauthError;

  /// Apakah klien Supabase sedang memegang sesi.
  static bool get hasSession => client.auth.currentSession != null;

  /// Mendengarkan perubahan sesi dari sisi Supabase.
  ///
  /// * [onSignedIn] — sesi baru terbentuk saat aplikasi berjalan, mis.
  ///   kembalian masuk dengan Google lewat deep link di Android.
  /// * [onSignedOut] — Supabase mengakhiri sesi, termasuk karena refresh token
  ///   dicabut atau kedaluwarsa, bukan hanya saat pengguna menekan "Keluar".
  /// * [onAuthError] — galat Auth di stream, mis. kode callback Google yang
  ///   gagal ditukar lewat deep link. Tidak dipanggil di web: di sana galat
  ///   callback sudah dibaca [init] dari alamat halaman.
  ///
  /// Stream ini memutar ulang seluruh event dan galat sebelumnya ke pendengar
  /// baru, termasuk yang terjadi selama [init] — callback harus tahan dipanggil
  /// untuk keadaan yang sudah ditangani.
  static StreamSubscription<sb.AuthState> listenAuthChanges({
    required void Function(sb.Session session) onSignedIn,
    required void Function() onSignedOut,
    required void Function(sb.AuthException error) onAuthError,
  }) {
    return client.auth.onAuthStateChange.listen(
      (state) {
        switch (state.event) {
          case sb.AuthChangeEvent.signedIn:
            final session = state.session;
            if (session != null) onSignedIn(session);
          case sb.AuthChangeEvent.signedOut:
            onSignedOut();
          default:
            break;
        }
      },
      // Tanpa onError, galat di stream ini (mis. refresh gagal karena offline)
      // naik sebagai exception yang tidak tertangani.
      onError: (Object error, StackTrace _) {
        if (kDebugMode) debugPrint('[Catatin] auth Supabase: $error');
        if (!kIsWeb && error is sb.AuthException) onAuthError(error);
      },
    );
  }
}

/// Pesan galat kalau [uri] adalah kembalian masuk dengan Google yang tidak
/// menghasilkan sesi, atau `null` kalau bukan.
///
/// Parameter dibaca dari query maupun fragment — bentuk yang dipakai Supabase
/// untuk alur PKCE dan implicit.
String? oauthCallbackError(Uri uri, {required bool hasSession}) {
  final fragment = uri.fragment.contains('=')
      ? Uri.splitQueryString(uri.fragment.replaceFirst(RegExp(r'^.*\?'), ''))
      : const <String, String>{};
  String? param(String key) => uri.queryParameters[key] ?? fragment[key];

  final error = param('error');
  if (error != null) {
    return error == 'access_denied'
        ? 'Masuk dengan Google dibatalkan.'
        : _oauthFailed;
  }
  if (param('code') != null && !hasSession) return _oauthFailed;
  return null;
}

const _oauthFailed = 'Masuk dengan Google gagal. Coba lagi.';

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
  if (error is sb.StorageException) {
    return _fromStorage(error, hasSession: hasSession);
  }
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
    case 'same_password':
      return const ApiException(
        statusCode: 400,
        message: 'Kata sandi baru harus berbeda.',
        errors: {'password': 'Kata sandi baru harus berbeda dari yang lama.'},
      );
    case 'current_password_required':
      return const ApiException(
        statusCode: 400,
        message: 'Masukkan kata sandi saat ini.',
        errors: {'current_password': 'Masukkan kata sandi saat ini.'},
      );
    case 'current_password_invalid':
      return const ApiException(
        statusCode: 400,
        message: 'Kata sandi saat ini salah.',
        errors: {'current_password': 'Kata sandi saat ini salah.'},
      );
    case 'reauthentication_needed':
    case 'reauthentication_not_valid':
      // Verifikasi ulang Supabase dikirim lewat email, yang belum bisa terkirim
      // ke pengunjung umum. Sesi yang baru dibuat tidak memerlukannya.
      return const ApiException(
        statusCode: 409,
        message: 'Demi keamanan, kata sandi hanya bisa dipasang tidak lama '
            'setelah masuk. Keluar, masuk lagi dengan Google, lalu coba lagi.',
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

const _attachmentTooLarge = ApiException(
  statusCode: 400,
  message: 'Ukuran foto maksimal 5 MB.',
  errors: {'file': 'Ukuran foto maksimal 5 MB.'},
);

const _attachmentWrongType = ApiException(
  statusCode: 400,
  message: 'Format foto harus JPEG, PNG, atau WebP.',
  errors: {'file': 'Format foto harus JPEG, PNG, atau WebP.'},
);

/// Galat Storage (unggah/hapus lampiran struk, issue #59) → [ApiException].
///
/// `statusCode` di [sb.StorageException] adalah teks (mis. `'413'`), bukan
/// `int`. Ukuran dan tipe berkas dicek dua kali — lewat `statusCode` KALAU
/// server mengirimnya, ATAU lewat kata kunci di [sb.StorageException.message]
/// kalau tidak — supaya galat yang sama tetap tampil sebagai pesan form untuk
/// pengguna walau proxy di antara klien dan Storage tidak meneruskan status
/// aslinya.
ApiException _fromStorage(sb.StorageException e, {required bool hasSession}) {
  final message = e.message.toLowerCase();
  if (e.statusCode == '413' || message.contains('size')) {
    return _attachmentTooLarge;
  }
  if (e.statusCode == '415' ||
      message.contains('mime') ||
      message.contains('type')) {
    return _attachmentWrongType;
  }
  switch (e.statusCode) {
    case '401':
      return _sessionEnded;
    case '403':
      return hasSession
          ? const ApiException(statusCode: 403, message: 'Akses ditolak.')
          : _sessionEnded;
    case '404':
      return const ApiException(statusCode: 404, message: 'Data tidak ditemukan.');
    case '409':
      return const ApiException(
        statusCode: 409,
        message: 'Berkas yang sama sudah ada.',
      );
  }
  _debugUnmapped(e);
  return ApiException(statusCode: 500, message: e.message);
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
    case '23503': // foreign key violation
      return _constraintViolation(e) ??
          const ApiException(statusCode: 400, message: 'Data tidak valid.');
    case '23502': // not null violation
      final column = _notNullColumn.firstMatch(e.message)?.group(1);
      return column == null
          ? const ApiException(statusCode: 400, message: 'Data tidak valid.')
          : ApiException(
              statusCode: 400,
              message: 'Data tidak valid.',
              errors: {column: 'Data wajib belum diisi.'},
            );
    case '22007': // format tanggal tidak valid
    case '22008': // tanggal yang tidak ada, mis. 30 Februari
      // Satu-satunya kolom tanggal yang ditulis klien: transactions.date.
      return const ApiException(
        statusCode: 400,
        message: 'Tanggal tidak valid.',
        errors: {'date': 'Tanggal tidak valid.'},
      );
    case '22P02': // format teks tidak valid, mis. UUID
      return const ApiException(statusCode: 400, message: 'Data tidak valid.');
  }
  _debugUnmapped(e);
  return ApiException(statusCode: 500, message: e.message);
}

/// Nama constraint di pesan Postgres, mis.
/// `new row for relation "transactions" violates check constraint "transactions_amount_check"`.
final _constraintName = RegExp(r'constraint "([^"]+)"');

/// Kolom di pesan not-null, mis.
/// `null value in column "business_name" of relation "business_profiles" violates not-null constraint`.
final _notNullColumn = RegExp(r'column "([^"]+)"');

/// Constraint skema → (field form, pesan untuk pengguna). Namanya berasal dari
/// migrasi di `supabase/migrations/` dan dijaga persis oleh
/// `supabase/tests/database/04_validasi_transaksi.test.sql`; mengganti nama
/// constraint berarti mengganti peta ini juga.
const _constraintFields = <String, (String, String)>{
  'transactions_amount_check': ('amount', 'Nominal harus lebih dari 0.'),
  'transactions_date_range_check': (
    'date',
    'Tanggal harus antara 1 Januari 2000 dan 31 Desember 2099.',
  ),
  'transactions_category_id_fkey': ('category_id', 'Kategori tidak ditemukan.'),
  'transactions_category_type_fkey': (
    'category_id',
    'Kategori tidak cocok dengan jenis transaksi.',
  ),
  'transactions_type_check': (
    'type',
    'Jenis transaksi harus pemasukan atau pengeluaran.',
  ),
  'transactions_payment_method_check': (
    'payment_method',
    'Metode pembayaran tidak dikenal.',
  ),
  'transactions_business_id_fkey': (
    'business_id',
    'Profil usaha tidak ditemukan. Muat ulang halaman.',
  ),
  'business_profiles_business_name_check': (
    'business_name',
    'Nama usaha wajib diisi.',
  ),
  'business_profiles_employee_count_check': (
    'employee_count',
    'Jumlah karyawan tidak boleh negatif.',
  ),
  'recurring_templates_type_check': (
    'type',
    'Jenis transaksi harus pemasukan atau pengeluaran.',
  ),
  'recurring_templates_amount_check': ('amount', 'Nominal harus lebih dari 0.'),
  'recurring_templates_payment_method_check': (
    'payment_method',
    'Metode pembayaran tidak dikenal.',
  ),
  'recurring_templates_frequency_check': (
    'frequency',
    'Frekuensi harus mingguan atau bulanan.',
  ),
  'recurring_templates_start_date_check': (
    'start_date',
    'Tanggal harus antara 1 Januari 2000 dan 31 Desember 2099.',
  ),
  'recurring_templates_end_date_check': (
    'end_date',
    'Tanggal harus antara 1 Januari 2000 dan 31 Desember 2099.',
  ),
  'recurring_templates_end_after_start_check': (
    'end_date',
    'Tanggal berakhir tidak boleh sebelum tanggal mulai.',
  ),
  'recurring_templates_category_id_fkey': (
    'category_id',
    'Kategori tidak ditemukan.',
  ),
  'recurring_templates_category_type_fkey': (
    'category_id',
    'Kategori tidak cocok dengan jenis transaksi.',
  ),
  'transaction_attachments_mime_type_check': (
    'file',
    'Format foto harus JPEG, PNG, atau WebP.',
  ),
  'transaction_attachments_size_bytes_check': (
    'file',
    'Ukuran foto maksimal 5 MB.',
  ),
  'transaction_attachments_file_name_check': (
    'file',
    'Nama berkas tidak valid.',
  ),
  'transaction_attachments_path_check': (
    'file',
    'Lokasi berkas tidak valid.',
  ),
};

/// Galat 400 dengan pesan per field untuk constraint yang dikenal, supaya
/// [ApiException.userMessage] menyebut apa yang salah — bukan sekadar
/// "Data tidak valid.". `null` untuk constraint yang tidak ada di peta.
ApiException? _constraintViolation(sb.PostgrestException e) {
  final name = _constraintName.firstMatch(e.message)?.group(1);
  final field = _constraintFields[name];
  if (field == null) return null;
  final (key, message) = field;
  return ApiException(statusCode: 400, message: message, errors: {key: message});
}

/// Galat yang tidak dikenali jatuh ke pesan umum di UI; di mode debug pesan
/// aslinya dicetak supaya penyebabnya — mis. migrasi yang belum di-push —
/// tidak hilang.
void _debugUnmapped(Object error) {
  if (kDebugMode) debugPrint('[Catatin] galat Supabase tak dipetakan: $error');
}
