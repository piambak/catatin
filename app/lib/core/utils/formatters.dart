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

  /// Rp 28.500.000
  static String format(num amount) => _full.format(amount);

  /// 28,5 Jt  /  4,8 M
  static String compact(num amount) => 'Rp ${_compact.format(amount)}';

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

  static String format(double rate, {int decimals = 1}) =>
      '${(rate * 100).toStringAsFixed(decimals)}%';

  static String formatValue(double pct, {int decimals = 1}) =>
      '${pct.toStringAsFixed(decimals)}%';
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
