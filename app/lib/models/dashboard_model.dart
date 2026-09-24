// lib/models/dashboard_model.dart

import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';

// ── Ringkasan bulanan untuk dashboard ─────────────────────────────────────────

class MonthlySummary {
  final double income;
  final double expense;
  final double profit;
  final double ytdOmzet;
  final double pkpPercent;
  final int txCount;

  const MonthlySummary({
    required this.income,
    required this.expense,
    required this.profit,
    required this.ytdOmzet,
    required this.pkpPercent,
    required this.txCount,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> j) {
    final ytd = (j['ytd_omzet'] as num?)?.toDouble() ?? 0;
    return MonthlySummary(
      income: (j['monthly_income'] as num?)?.toDouble() ?? 0,
      expense: (j['monthly_expense'] as num?)?.toDouble() ?? 0,
      profit: (j['monthly_profit'] as num?)?.toDouble() ?? 0,
      ytdOmzet: ytd,
      pkpPercent: (ytd / AppConstants.pkpThreshold) * 100,
      txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Agregat tahunan (`GET /transactions/aggregate`) ───────────────────────────

/// Angka mentah satu bulan sebelum diolah [monthAggregates]: pemasukan,
/// pengeluaran, bagian pengeluaran yang HPP, dan jumlah transaksi.
typedef MonthTotals = ({
  int month,
  double income,
  double expense,
  double cogs,
  int txCount,
});

/// Angka satu bulan di [YearAggregate].
class MonthAggregate {
  /// 1 (Januari) sampai 12 (Desember).
  final int month;
  final double income;
  final double expense;

  /// Bagian [expense] dari kategori HPP (`is_cogs`).
  final double cogs;
  final int txCount;

  /// Pemasukan Januari sampai bulan ini — omzet berjalan untuk ambang PKP.
  final double ytdOmzet;

  const MonthAggregate({
    required this.month,
    required this.income,
    required this.expense,
    required this.cogs,
    required this.txCount,
    required this.ytdOmzet,
  });

  double get profit => income - expense;

  factory MonthAggregate.fromJson(Map<String, dynamic> j) => MonthAggregate(
    month: (j['month'] as num).toInt(),
    income: (j['income'] as num?)?.toDouble() ?? 0,
    expense: (j['expense'] as num?)?.toDouble() ?? 0,
    cogs: (j['cogs'] as num?)?.toDouble() ?? 0,
    txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
    ytdOmzet: (j['ytd_omzet'] as num?)?.toDouble() ?? 0,
  );
}

/// Dua belas bulan [MonthAggregate], Januari di indeks 0. Bulan yang tidak ada
/// di [totals] bernilai nol.
///
/// Omzet YTD dijumlahkan di sini dan hanya di sini — ringkasan dashboard,
/// grafik KPI, dan agregat tahunan semuanya lewat fungsi ini supaya aturannya
/// tidak bercabang (pelajaran T-13).
List<MonthAggregate> monthAggregates(Iterable<MonthTotals> totals) {
  final byMonth = {for (final t in totals) t.month: t};
  final result = <MonthAggregate>[];
  var ytd = 0.0;
  for (var m = 1; m <= 12; m++) {
    final t = byMonth[m];
    ytd += t?.income ?? 0;
    result.add(
      MonthAggregate(
        month: m,
        income: t?.income ?? 0,
        expense: t?.expense ?? 0,
        cogs: t?.cogs ?? 0,
        txCount: t?.txCount ?? 0,
        ytdOmzet: ytd,
      ),
    );
  }
  return result;
}

/// Pemasukan, pengeluaran, dan HPP per bulan dalam satu tahun — bahan Simulator
/// dan ringkasan tutup bulan.
class YearAggregate {
  final int year;

  /// Selalu 12 bulan, Januari di indeks 0.
  final List<MonthAggregate> months;

  const YearAggregate({required this.year, required this.months});

  factory YearAggregate.fromMonthlyTotals(
    int year,
    Iterable<MonthTotals> totals,
  ) => YearAggregate(year: year, months: monthAggregates(totals));

  factory YearAggregate.fromJson(Map<String, dynamic> j) => YearAggregate(
    year: (j['year'] as num).toInt(),
    months: (j['months'] as List)
        .map((e) => MonthAggregate.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Angka bulan [month] (1–12).
  MonthAggregate operator [](int month) => months[month - 1];

  double get totalIncome => months.fold(0, (sum, m) => sum + m.income);
  double get totalExpense => months.fold(0, (sum, m) => sum + m.expense);
  double get totalCogs => months.fold(0, (sum, m) => sum + m.cogs);
  int get totalTxCount => months.fold(0, (sum, m) => sum + m.txCount);
}

// ── Ringkasan tutup bulan (`GET /dashboard/close`, #74) ───────────────────────

/// Angka satu bulan yang siap dipakai kartu "Bulan ini" di Dashboard dan
/// Simulator.
///
/// Sengaja dibangun dari [MonthAggregate] — sumber yang sama dengan
/// [YearAggregate] — jadi bulan yang sama selalu memberi angka yang sama di
/// mana pun ditampilkan.
class MonthClose {
  /// 1 (Januari) sampai 12 (Desember).
  final int month;
  final int year;
  final double income;
  final double expense;

  /// `income − expense`.
  final double profit;

  /// Bagian [expense] dari kategori HPP (`is_cogs`).
  final double cogs;
  final int txCount;

  /// Pemasukan Januari sampai [month].
  final double ytdOmzet;

  const MonthClose({
    required this.month,
    required this.year,
    required this.income,
    required this.expense,
    required this.profit,
    required this.cogs,
    required this.txCount,
    required this.ytdOmzet,
  });

  factory MonthClose.fromAggregate(int year, MonthAggregate m) => MonthClose(
    month: m.month,
    year: year,
    income: m.income,
    expense: m.expense,
    profit: m.profit,
    cogs: m.cogs,
    txCount: m.txCount,
    ytdOmzet: m.ytdOmzet,
  );

  factory MonthClose.fromJson(Map<String, dynamic> j) {
    final income = (j['income'] as num?)?.toDouble() ?? 0;
    final expense = (j['expense'] as num?)?.toDouble() ?? 0;
    return MonthClose(
      month: (j['month'] as num).toInt(),
      year: (j['year'] as num).toInt(),
      income: income,
      expense: expense,
      profit: (j['profit'] as num?)?.toDouble() ?? income - expense,
      cogs: (j['cogs'] as num?)?.toDouble() ?? 0,
      txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
      ytdOmzet: (j['ytd_omzet'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Menolak bulan di luar 1–12 SEBELUM permintaan dikirim, sama dengan balasan
/// 400 `validation_failed` di kontrak `GET /dashboard/close` dan
/// `GET /simulator/inputs`. Dipanggil setiap implementasi
/// `DashboardRepository.getMonthClose` dan `SimulatorRepository.getInputs`,
/// jadi gagal di semua mode.
void checkMonthParam({required int month}) {
  if (month < 1 || month > 12) {
    throw ApiException(
      statusCode: 400,
      message: 'Bulan harus 1–12.',
      errors: const {'month': 'Bulan harus 1–12.'},
      code: 'validation_failed',
    );
  }
}

/// Satu titik pada grafik riwayat KPI (`{month, value}`).
class KpiPoint {
  final String month;
  final double value;

  const KpiPoint({required this.month, required this.value});

  factory KpiPoint.fromJson(Map<String, dynamic> j) => KpiPoint(
    month: j['month'] as String,
    value: (j['value'] as num).toDouble(),
  );
}

// ── Transaksi ringkas untuk kartu "Transaksi Terakhir" ────────────────────────

class RecentTx {
  final String id;
  final String categoryName;
  final String? categoryIcon;
  final String categoryColor;
  final String type; // INCOME | EXPENSE
  final double amount;
  final String? description;
  final DateTime date;

  const RecentTx({
    required this.id,
    required this.categoryName,
    this.categoryIcon,
    required this.categoryColor,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
  });

  bool get isIncome => type == 'INCOME';

  factory RecentTx.fromJson(Map<String, dynamic> j) => RecentTx(
    id: j['id'] as String,
    categoryName: j['category']['name'] as String,
    categoryIcon: j['category']['icon'] as String?,
    categoryColor: j['category']['color'] as String? ?? '#6B7280',
    type: j['type'] as String,
    amount: (j['amount'] as num).toDouble(),
    description: j['description'] as String?,
    date: DateTime.parse(j['date'] as String),
  );
}

// ── Tenggat pajak ─────────────────────────────────────────────────────────────

class TaxDeadline {
  final String id;
  final String label;
  final String taxType;
  final DateTime deadline;
  final String status; // PENDING | PAID | LATE

  const TaxDeadline({
    required this.id,
    required this.label,
    required this.taxType,
    required this.deadline,
    required this.status,
  });

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  bool get isUrgent => daysRemaining >= 0 && daysRemaining <= 7;
  bool get isWarning => daysRemaining > 7 && daysRemaining <= 30;
  bool get isOverdue => daysRemaining < 0;

  factory TaxDeadline.fromJson(Map<String, dynamic> j) => TaxDeadline(
    id: j['id'] as String,
    label: j['label'] as String,
    taxType: j['tax_type'] as String,
    deadline: DateTime.parse(j['deadline'] as String).toLocal(),
    status: j['status'] as String,
  );
}
