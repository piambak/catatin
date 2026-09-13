// lib/core/network/browser_url_web.dart

import 'package:web/web.dart' as web;

/// Membuang query dari alamat tanpa memuat ulang halaman; rute di fragment
/// (`#/login`) dipertahankan.
///
/// Dipakai setelah kembalian masuk dengan Google yang gagal. Supabase hanya
/// membersihkan `?code=` saat penukaran berhasil, jadi tanpa ini `?error=…`
/// tertinggal dan pesan galatnya muncul lagi setiap halaman dimuat ulang.
void clearUrlQuery() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    '',
    '${location.origin}${location.pathname}${location.hash}',
  );
}
