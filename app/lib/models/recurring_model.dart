// lib/models/recurring_model.dart
//
// Template transaksi berulang (issue #58). Bentuknya sengaja dekat dengan
// `TxData`/`TransactionDraft` di `transaction_model.dart`: kategori disematkan
// sama seperti transaksi, dan draft-nya cuma membawa `category_id`.

import 'transaction_model.dart';

// ── Frekuensi ─────────────────────────────────────────────────────────────────

/// Nilai kolom `frequency` yang dikenal kontrak REST dan Supabase.
class RecurringFrequency {
  RecurringFrequency._();

  static const weekly = 'WEEKLY';
  static const monthly = 'MONTHLY';
}

// ── Template ──────────────────────────────────────────────────────────────────

class RecurringTemplate {
  final String id;
  final String businessId;
  final String type; // INCOME | EXPENSE
  final double amount;
  final TxCategoryData category;
  final String? description;
  final String paymentMethod;
  final String frequency; // WEEKLY | MONTHLY

  /// Format `YYYY-MM-DD`.
  final String startDate;

  /// Format `YYYY-MM-DD`, atau `null` kalau pengulangan tidak berujung.
  final String? endDate;

  /// Format `YYYY-MM-DD`; `null` kalau template sudah tidak aktif.
  final String? nextDate;
  final bool isActive;
  final DateTime createdAt;

  const RecurringTemplate({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.nextDate,
    required this.isActive,
    required this.createdAt,
  });

  bool get isIncome => type == 'INCOME';

  factory RecurringTemplate.fromJson(Map<String, dynamic> j) =>
      RecurringTemplate(
        id: j['id'] as String,
        businessId: j['business_id'] as String,
        type: j['type'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: TxCategoryData.fromJson(
          j['category'] as Map<String, dynamic>,
        ),
        description: j['description'] as String?,
        paymentMethod: j['payment_method'] as String? ?? 'CASH',
        frequency: j['frequency'] as String,
        startDate: j['start_date'] as String,
        endDate: j['end_date'] as String?,
        nextDate: j['next_date'] as String?,
        isActive: j['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'type': type,
    'amount': amount,
    'category': {
      'id': category.id,
      'name': category.name,
      'type': category.type,
      'tax_relevant': category.taxRelevant,
      'is_cogs': category.isCogs,
      'icon': category.icon,
      'color': category.color,
    },
    'description': description,
    'payment_method': paymentMethod,
    'frequency': frequency,
    'start_date': startDate,
    'end_date': endDate,
    'next_date': nextDate,
    'is_active': isActive,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

// ── Input template ────────────────────────────────────────────────────────────

/// Data yang dikirim saat membuat atau mengganti template — bentuknya sama
/// untuk `POST /recurring` dan `PATCH /recurring/{id}` (body penuh, bukan
/// patch sebagian).
class RecurringDraft {
  final String type; // INCOME | EXPENSE
  final double amount;
  final String categoryId;
  final String? description;
  final String paymentMethod;
  final String frequency; // WEEKLY | MONTHLY

  /// Format `YYYY-MM-DD`.
  final String startDate;

  /// Format `YYYY-MM-DD`, atau `null` kalau pengulangan tidak berujung.
  final String? endDate;

  const RecurringDraft({
    required this.type,
    required this.amount,
    required this.categoryId,
    this.description,
    required this.paymentMethod,
    required this.frequency,
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'amount': amount,
    'category_id': categoryId,
    'description': description,
    'payment_method': paymentMethod,
    'frequency': frequency,
    'start_date': startDate,
    'end_date': endDate,
  };
}

// ── Jadwal pengulangan (murni, tanpa jaringan) ─────────────────────────────────

/// [date] tanpa jam, menit, dan detik.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Kejadian ke-[months] dari [anchor], dengan tanggal dijepit ke hari terakhir
/// bulan tujuan kalau bulan itu lebih pendek — 31 Jan + 1 bulan = 28/29 Feb,
/// bukan meluber ke Maret.
DateTime _addMonthsClamped(DateTime anchor, int months) {
  final total = anchor.month - 1 + months;
  final year = anchor.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = anchor.day > lastDayOfMonth ? lastDayOfMonth : anchor.day;
  return DateTime(year, month, day);
}

/// Kejadian pertama jadwal [frequency] berpatokan [start] yang jatuh pada atau
/// setelah [day].
///
/// Dipakai untuk menghitung `next_date`: tidak pernah mundur sebelum [start]
/// (kejadian pertama selalu [start] sendiri), dan tidak ada "backfill" — kalau
/// [day] sudah lewat beberapa kejadian, yang dikembalikan tetap kejadian
/// berikutnya yang belum lewat, bukan yang terlewat.
///
/// * `WEEKLY`: [start] + 7 hari × n.
/// * `MONTHLY`: [start] + n bulan, hari dijepit ke akhir bulan (lihat
///   [_addMonthsClamped]) — jadwal 31 Januari jatuh di 28 Februari (29 di
///   tahun kabisat), lalu 31 Maret, dihitung selalu dari 31 Januari, bukan
///   dari kejadian sebelumnya.
DateTime recurringFirstOnOrAfter(
  DateTime start,
  String frequency,
  DateTime day,
) {
  final anchor = _dateOnly(start);
  final target = _dateOnly(day);
  if (!target.isAfter(anchor)) return anchor;

  if (frequency == RecurringFrequency.weekly) {
    final diffDays = target.difference(anchor).inDays;
    final n = (diffDays + 6) ~/ 7;
    return anchor.add(Duration(days: n * 7));
  }

  // MONTHLY — mundur satu langkah dari tebakan supaya penjepitan hari (mis.
  // anchor tanggal 5 vs target tanggal 20 di bulan yang sama) tidak membuat
  // kejadian yang seharusnya masih memenuhi syarat terlewat.
  var n = (target.year - anchor.year) * 12 + (target.month - anchor.month);
  n = n > 0 ? n - 1 : 0;
  var occurrence = _addMonthsClamped(anchor, n);
  while (occurrence.isBefore(target)) {
    n++;
    occurrence = _addMonthsClamped(anchor, n);
  }
  return occurrence;
}
