// lib/models/simulator_model.dart
//
// Nilai awal Simulator dari data Pembukuan (#89, `GET /simulator/inputs`):
// rata-rata tiga bulan penuh sebelum bulan acuan, angka bulan acuan sejauh
// ini, omzet YTD, dan profil usaha. Tidak ada satu pun hitungan pajak di sini —
// tarif dan rumusnya tetap di `core/services/simulator_service.dart`; model
// ini hanya bahan mentahnya.

import 'business_model.dart';
import 'dashboard_model.dart';

/// Total satu bulan: pemasukan, pengeluaran, bagian pengeluaran yang HPP, dan
/// jumlah transaksi.
class PeriodTotals {
  final double income;
  final double expense;
  final double cogs;
  final int txCount;

  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.cogs,
    required this.txCount,
  });

  factory PeriodTotals.fromJson(Map<String, dynamic> j) => PeriodTotals(
    income: (j['income'] as num?)?.toDouble() ?? 0,
    expense: (j['expense'] as num?)?.toDouble() ?? 0,
    cogs: (j['cogs'] as num?)?.toDouble() ?? 0,
    txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
  );
}

/// Rata-rata per bulan dalam jendela tiga bulan penuh sebelum bulan acuan.
class SimulatorAverage {
  final int fromMonth;
  final int fromYear;
  final int toMonth;
  final int toYear;

  /// Bulan di jendela yang punya paling sedikit satu transaksi — pembagi
  /// rata-rata. `0` berarti belum ada data sama sekali; semua angka nol.
  final int monthsWithData;

  /// Jumlah transaksi di seluruh jendela (bukan rata-rata), untuk baris
  /// sumber "Dihitung dari 24 transaksi (Jun–Agu)".
  final int txCount;

  /// Rata-rata per bulan, dibulatkan ke rupiah terdekat.
  final double income;
  final double expense;
  final double cogs;

  const SimulatorAverage({
    required this.fromMonth,
    required this.fromYear,
    required this.toMonth,
    required this.toYear,
    required this.monthsWithData,
    required this.txCount,
    required this.income,
    required this.expense,
    required this.cogs,
  });

  factory SimulatorAverage.fromJson(Map<String, dynamic> j) => SimulatorAverage(
    fromMonth: (j['from_month'] as num).toInt(),
    fromYear: (j['from_year'] as num).toInt(),
    toMonth: (j['to_month'] as num).toInt(),
    toYear: (j['to_year'] as num).toInt(),
    monthsWithData: (j['months_with_data'] as num?)?.toInt() ?? 0,
    txCount: (j['tx_count'] as num?)?.toInt() ?? 0,
    income: (j['income'] as num?)?.toDouble() ?? 0,
    expense: (j['expense'] as num?)?.toDouble() ?? 0,
    cogs: (j['cogs'] as num?)?.toDouble() ?? 0,
  );
}

/// Bagian profil usaha yang dipakai Simulator.
class SimulatorBusiness {
  final bool pkpStatus;
  final int employeeCount;
  final String businessType;

  const SimulatorBusiness({
    required this.pkpStatus,
    required this.employeeCount,
    required this.businessType,
  });

  factory SimulatorBusiness.fromProfile(BusinessProfile p) => SimulatorBusiness(
    pkpStatus: p.pkpStatus,
    employeeCount: p.employeeCount,
    businessType: p.businessType,
  );

  factory SimulatorBusiness.fromJson(Map<String, dynamic> j) =>
      SimulatorBusiness(
        pkpStatus: j['pkp_status'] as bool? ?? false,
        employeeCount: (j['employee_count'] as num?)?.toInt() ?? 0,
        businessType: j['business_type'] as String? ?? '',
      );
}

class SimulatorInputs {
  /// Bulan acuan, 1–12.
  final int month;
  final int year;
  final SimulatorAverage average;

  /// Bulan acuan sejauh ini — belum penuh kalau itu bulan berjalan.
  final PeriodTotals currentMonth;

  /// Pemasukan Januari sampai bulan acuan.
  final double ytdOmzet;

  /// `null` kalau pengguna belum punya profil usaha.
  final SimulatorBusiness? business;

  const SimulatorInputs({
    required this.month,
    required this.year,
    required this.average,
    required this.currentMonth,
    required this.ytdOmzet,
    required this.business,
  });

  factory SimulatorInputs.fromJson(Map<String, dynamic> j) {
    final business = j['business'];
    return SimulatorInputs(
      month: (j['month'] as num).toInt(),
      year: (j['year'] as num).toInt(),
      average: SimulatorAverage.fromJson(j['average'] as Map<String, dynamic>),
      currentMonth: PeriodTotals.fromJson(
        j['current_month'] as Map<String, dynamic>,
      ),
      ytdOmzet: (j['ytd_omzet'] as num?)?.toDouble() ?? 0,
      business: business is Map<String, dynamic>
          ? SimulatorBusiness.fromJson(business)
          : null,
    );
  }
}

/// Satu-satunya tempat aturan nilai awal Simulator — dipakai mock dan
/// Supabase, supaya keduanya tidak bisa menyimpang (pelajaran T-13).
///
/// [previous] adalah agregat tahun [year] − 1 dan wajib ada kalau jendela tiga
/// bulan menyeberang tahun ([month] ≤ 3).
///
/// Rata-rata dibagi jumlah bulan yang punya transaksi, bukan selalu tiga: di
/// Catatin bulan kosong lebih mungkin berarti "belum dicatat" daripada "tidak
/// ada penjualan", dan usaha yang baru mulai bulan lalu tidak boleh tampak
/// beromzet sepertiganya.
SimulatorInputs simulatorInputsFrom({
  required int month,
  required int year,
  required YearAggregate current,
  YearAggregate? previous,
  BusinessProfile? business,
}) {
  final window = <MonthAggregate>[];
  for (var k = 3; k >= 1; k--) {
    final m = month - k;
    if (m >= 1) {
      window.add(current[m]);
    } else {
      if (previous == null) {
        throw ArgumentError.notNull('previous');
      }
      window.add(previous[m + 12]);
    }
  }

  final withData = window.where((m) => m.txCount > 0).toList();
  final divisor = withData.isEmpty ? 1 : withData.length;
  double avg(double Function(MonthAggregate) pick) =>
      (withData.fold<double>(0, (sum, m) => sum + pick(m)) / divisor)
          .roundToDouble();

  final from = month - 3;
  final to = month - 1;
  final now = current[month];

  return SimulatorInputs(
    month: month,
    year: year,
    average: SimulatorAverage(
      fromMonth: from >= 1 ? from : from + 12,
      fromYear: from >= 1 ? year : year - 1,
      toMonth: to >= 1 ? to : to + 12,
      toYear: to >= 1 ? year : year - 1,
      monthsWithData: withData.length,
      txCount: window.fold(0, (sum, m) => sum + m.txCount),
      income: avg((m) => m.income),
      expense: avg((m) => m.expense),
      cogs: avg((m) => m.cogs),
    ),
    currentMonth: PeriodTotals(
      income: now.income,
      expense: now.expense,
      cogs: now.cogs,
      txCount: now.txCount,
    ),
    ytdOmzet: now.ytdOmzet,
    business: business == null ? null : SimulatorBusiness.fromProfile(business),
  );
}
