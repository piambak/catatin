// lib/core/utils/formatters.dart

import 'package:intl/intl.dart';

// ── Currency ──────────────────────────────────────────────────────────────────

class Rupiah {
  Rupiah._();

  static final _full = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _compact = NumberFormat.compact(locale: 'id_ID');

  static final _desimal = NumberFormat.decimalPattern('id_ID');

  /// Rp 28.500.000
  static String format(num amount) => _full.format(amount);

  /// 28,5 Jt  /  4,8 M
  static String compact(num amount) => 'Rp ${_compact.format(amount)}';

  /// Rp 4,8 Miliar — untuk ambang yang lazim ditulis panjang di teks aturan.
  static String miliar(num amount) =>
      'Rp ${_desimal.format(amount / 1000000000)} Miliar';

  static final _plain = NumberFormat('#,###', 'id_ID');

  /// 28.500.000 — tanpa awalan "Rp", nilai absolut.
  ///
  /// Dipakai di kolom angka yang sudah punya label atau tanda sendiri, seperti
  /// ringkasan "Bulan ini" dan daftar "Terakhir dicatat" di dashboard.
  static String plain(num amount) => _plain.format(amount.abs());

  /// Parse "28.500.000" → 28500000
  static double parse(String value) {
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format while typing — adds thousand separators
  static String typing(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final num = int.parse(digits);
    return NumberFormat('#,###', 'id_ID').format(num);
  }
}

// ── Percentage ────────────────────────────────────────────────────────────────

class Pct {
  Pct._();

  /// 0,005 → `0,5%`
  ///
  /// Memakai koma desimal sesuai penulisan Indonesia. Sebelumnya kedua fungsi
  /// ini memakai `toStringAsFixed`, yang selalu menghasilkan titik — jadi
  /// seluruh persentase di aplikasi tampil sebagai "6.0%" dan "5.9%", padahal
  /// mockup dan teks peraturan menulis "6,0%" dan "5,9%".
  static String format(double rate, {int decimals = 1}) =>
      formatValue(rate * 100, decimals: decimals);

  /// 5,9 → `5,9%`
  static String formatValue(double pct, {int decimals = 1}) =>
      '${_fixed(decimals).format(pct)}%';

  /// 0,5% — alias lama, dipertahankan untuk pemanggil yang sudah ada.
  static String id(double rate) => format(rate);

  static final _formats = <int, NumberFormat>{};

  static NumberFormat _fixed(int decimals) => _formats.putIfAbsent(
        decimals,
        () => NumberFormat.decimalPattern('id_ID')
          ..minimumFractionDigits = decimals
          ..maximumFractionDigits = decimals,
      );
}

// ── Date ──────────────────────────────────────────────────────────────────────

class Tanggal {
  Tanggal._();

  static final _long  = DateFormat('d MMMM yyyy', 'id_ID');
  static final _short = DateFormat('d MMM', 'id_ID');
  static final _api   = DateFormat('yyyy-MM-dd');
  static final _month = DateFormat('MMMM yyyy', 'id_ID');

  /// 14 Oktober 2025
  static String long(DateTime date) => _long.format(date);

  /// 14 Okt
  static String short(DateTime date) => _short.format(date);

  /// October 2025
  static String month(DateTime date) => _month.format(date);

  /// 2025-10-14  (for API)
  static String api(DateTime date) => _api.format(date);

  /// Parse API date string
  static DateTime fromApi(String s) => DateTime.parse(s).toLocal();

  /// Days remaining from today
  static int daysUntil(DateTime date) =>
      date.difference(DateTime.now()).inDays;
}

// ── Number ────────────────────────────────────────────────────────────────────

class Num {
  Num._();

  static String format(num n) =>
      NumberFormat('#,###', 'id_ID').format(n);
}
