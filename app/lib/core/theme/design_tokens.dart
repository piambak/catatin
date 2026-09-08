// lib/core/theme/design_tokens.dart
//
// Token yang diturunkan langsung dari mockup Claude Design (Catatin.dc.html).
//
// Lapisan ini SENGAJA hidup berdampingan dengan `AppColors` di app_theme.dart.
// Layar yang sudah didesain ulang memakai `DS`; layar lama tetap memakai
// `AppColors` sampai gilirannya tiba. Lihat docs/PRD-REDESAIN-UI.md.
//
// Mockup-nya hanya menggambar mode terang. Nilai gelap di bawah adalah
// turunan yang menjaga peran dan urutan kontras yang sama — BELUM diukur
// terhadap WCAG. Lihat DESIGN-TOKENS.md B.6.

import 'package:flutter/material.dart';
import '../services/theme_notifier.dart';

/// Design tokens. Semua getter supaya ikut berganti saat [themeNotifier]
/// berubah, sama seperti pola `AppColors` yang sudah ada.
class DS {
  DS._();

  static bool get _dark => themeNotifier.isDark;

  // ── Netral ────────────────────────────────────────────────────────────────
  // Nama mengikuti peran, bukan nilai — `ink` selalu teks paling kuat.

  /// Teks utama, angka besar.
  static Color get ink => _dark ? const Color(0xFFEDF2F7) : const Color(0xFF0D1B2A);

  /// Teks isi paragraf.
  static Color get body => _dark ? const Color(0xFFC8D3DF) : const Color(0xFF334455);

  /// Teks sekunder, keterangan.
  static Color get muted => _dark ? const Color(0xFF9AAABB) : const Color(0xFF667788);

  /// Label huruf kecil, satuan.
  static Color get faint => _dark ? const Color(0xFF8494A6) : const Color(0xFF8898AA);

  /// Teks di atas permukaan gelap.
  static Color get soft => _dark ? const Color(0xFF8494A6) : const Color(0xFFAAB8CC);

  /// Garis pemisah utama.
  static Color get border => _dark ? const Color(0xFF454B55) : const Color(0xFFCDD8E8);

  /// Garis pemisah halus — dipakai jauh lebih sering di mockup.
  static Color get hairline => _dark ? const Color(0xFF3A3F47) : const Color(0xFFE3EBF6);

  /// Latar bar progres, isian tenang.
  static Color get tint => _dark ? const Color(0xFF363A3F) : const Color(0xFFE8F2FF);

  /// Latar halaman / bidang cekung.
  static Color get sunken => _dark ? const Color(0xFF232528) : const Color(0xFFF4F9FF);

  /// Permukaan utama.
  static Color get surface => _dark ? const Color(0xFF2D3035) : const Color(0xFFFFFFFF);

  // ── Merek ─────────────────────────────────────────────────────────────────

  static const brand = Color(0xFFFFA400);

  /// Latar pil "8 hari lagi", tab aktif.
  static Color get brandMuted => _dark ? const Color(0xFF3A3320) : const Color(0xFFFFF3CC);

  /// Teks di atas [brandMuted].
  static Color get brandInk => _dark ? const Color(0xFFFFCC70) : const Color(0xFF633806);

  /// Titik penanda, aksen tenang.
  static Color get brandDeep => _dark ? const Color(0xFFE0A845) : const Color(0xFFB07D2A);

  /// Teks di atas [brand] — mockup memakai ink, bukan putih.
  static const onBrand = Color(0xFF0D1B2A);

  // ── Semantik ──────────────────────────────────────────────────────────────

  static Color get income => _dark ? const Color(0xFF3FBF75) : const Color(0xFF1B8A4B);
  static Color get expense => _dark ? const Color(0xFFFF6B6B) : const Color(0xFFD92B2B);

  /// Tautan teks.
  static Color get link => _dark ? const Color(0xFF5CBBF0) : const Color(0xFF0A6FB0);

  /// Warna wordmark "Catat".
  static Color get wordmark => _dark ? const Color(0xFFAEAEE8) : const Color(0xFF2A2A72);

  /// Permukaan gelap panel hasil simulator — tetap gelap di kedua mode,
  /// itu memang maksudnya di mockup.
  static const invSurface = Color(0xFF0D1B2A);
  static const invInk = Color(0xFFFFFFFF);
  static const invMuted = Color(0xFF8898AA);
  static const invBody = Color(0xFFE8F2FF);
}

/// Skala spasi 4pt. Mockup memakai banyak nilai ganjil (34, 38, 44) untuk
/// komposisi web; nilai itu dipakai langsung di layar terkait, bukan
/// dipaksakan masuk skala ini.
class Space {
  Space._();
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 24.0;
  static const x6 = 32.0;
  static const x7 = 44.0;
}

class Radii {
  Radii._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 14.0;
  static const xl = 18.0;

  /// Pil — tombol utama dan item navigasi di mockup semuanya membulat penuh.
  static const pill = 999.0;
}

/// Gaya teks. Dua keluarga + satu fallback angka.
///
/// Mockup memakai 'DM Mono' untuk angka, tapi berkas fontnya tidak ikut
/// di-bundle di `assets/fonts/` — hanya DM Sans dan DM Serif Display. Sampai
/// DM Mono ditambahkan ke pubspec, [mono] memakai `monospace` bawaan sistem,
/// sama seperti kode lama.
class Typo {
  Typo._();

  static TextStyle serif(double size, {Color? color, double? height, double? spacing}) =>
      TextStyle(
        fontFamily: 'DMSerif',
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? DS.ink,
        height: height ?? 1.2,
        letterSpacing: spacing,
      );

  static TextStyle sans(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? spacing,
  }) =>
      TextStyle(
        fontFamily: 'DMSans',
        fontSize: size,
        fontWeight: weight,
        color: color ?? DS.body,
        height: height ?? 1.5,
        letterSpacing: spacing,
      );

  static TextStyle mono(double size, {Color? color, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: weight,
        color: color ?? DS.ink,
        letterSpacing: -0.3,
      );

  /// Label huruf besar berjarak lebar — pola paling khas di mockup.
  static TextStyle label({Color? color, double size = 11}) => TextStyle(
        fontFamily: 'DMSans',
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? DS.faint,
        letterSpacing: 2.2,
        height: 1.3,
      );
}
