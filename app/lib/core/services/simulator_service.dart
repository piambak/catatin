// lib/core/services/simulator_service.dart
// Pure deterministic tax math — no API calls, fully offline

import '../../core/constants/app_constants.dart';

// ─── PPh Final UMKM (PP 23/2018) ──────────────────────────────────────────────

class PPhFinalResult {
  final double omzetBulanan;
  final double omzetTahunanEst;
  final double pajakBulanan;
  final double pajakTahunanEst;
  final double rate;
  final double pkpThresholdPercent;
  final bool isPkpWarning;   // >= 80%
  final bool isPkpDanger;    // >= 95%
  final bool eligible;       // false if omzet > 4.8B

  const PPhFinalResult({
    required this.omzetBulanan,
    required this.omzetTahunanEst,
    required this.pajakBulanan,
    required this.pajakTahunanEst,
    required this.rate,
    required this.pkpThresholdPercent,
    required this.isPkpWarning,
    required this.isPkpDanger,
    required this.eligible,
  });
}

PPhFinalResult calculatePPhFinal(double omzetBulanan) {
  final omzetTahunan = omzetBulanan * 12;
  final eligible     = omzetTahunan <= AppConstants.pkpThreshold;
  const rate         = AppConstants.pphFinalRate;

  final pctRaw       = (omzetTahunan / AppConstants.pkpThreshold) * 100;
  final pct          = pctRaw.clamp(0.0, 100.0);

  return PPhFinalResult(
    omzetBulanan:        omzetBulanan,
    omzetTahunanEst:     omzetTahunan,
    pajakBulanan:        omzetBulanan * rate,
    pajakTahunanEst:     omzetTahunan * rate,
    rate:                rate,
    pkpThresholdPercent: pct,
    isPkpWarning:        pct >= 80,
    isPkpDanger:         pct >= 95,
    eligible:            eligible,
  );
}

// ─── PPh 21 Karyawan — TER Method (PMK 168/2023) ──────────────────────────────

enum PtkpStatus {
  tk0, tk1, tk2, tk3,
  k0,  k1,  k2,  k3,
}

extension PtkpLabel on PtkpStatus {
  String get label => const {
    PtkpStatus.tk0: 'TK/0 — Tidak Kawin, 0 tanggungan',
    PtkpStatus.tk1: 'TK/1 — Tidak Kawin, 1 tanggungan',
    PtkpStatus.tk2: 'TK/2 — Tidak Kawin, 2 tanggungan',
    PtkpStatus.tk3: 'TK/3 — Tidak Kawin, 3 tanggungan',
    PtkpStatus.k0:  'K/0  — Kawin, 0 tanggungan',
    PtkpStatus.k1:  'K/1  — Kawin, 1 tanggungan',
    PtkpStatus.k2:  'K/2  — Kawin, 2 tanggungan',
    PtkpStatus.k3:  'K/3  — Kawin, 3 tanggungan',
  }[this]!;

  String get shortLabel => const {
    PtkpStatus.tk0: 'TK/0', PtkpStatus.tk1: 'TK/1',
    PtkpStatus.tk2: 'TK/2', PtkpStatus.tk3: 'TK/3',
    PtkpStatus.k0:  'K/0',  PtkpStatus.k1:  'K/1',
    PtkpStatus.k2:  'K/2',  PtkpStatus.k3:  'K/3',
  }[this]!;

  /// Kunci status ini di [AppConstants.ptkp].
  ///
  /// Versi lama menurunkan kunci dari label tampilan
  /// (`shortLabel.replaceAll('/','')`) — rapuh, karena mengubah teks yang
  /// dibaca manusia diam-diam merusak pencarian nilainya. `switch` ini
  /// exhaustive, jadi menambah status baru tanpa memetakannya gagal saat
  /// compile, bukan crash di tangan pengguna. Lihat temuan T-5.
  String get ptkpKey => switch (this) {
        PtkpStatus.tk0 => 'TK0',
        PtkpStatus.tk1 => 'TK1',
        PtkpStatus.tk2 => 'TK2',
        PtkpStatus.tk3 => 'TK3',
        PtkpStatus.k0 => 'K0',
        PtkpStatus.k1 => 'K1',
        PtkpStatus.k2 => 'K2',
        PtkpStatus.k3 => 'K3',
      };

  /// Nilai PTKP setahun.
  ///
  /// Nilainya tetap tinggal di [AppConstants.ptkp] — itu konstanta pajak, dan
  /// menyalinnya ke sini akan mengulang persis masalah T-13 (dua daftar yang
  /// bisa menyimpang). Kelengkapan pemetaannya dijaga tes, bukan harapan.
  double get ptkpAmount => AppConstants.ptkp[ptkpKey]!;
}

class PPh21Result {
  final double gajiKotor;
  final double ptkp;
  final double pkp;
  final double pajakBulanan;
  final double pajakTahunanEst;
  final double terRate;
  final double netGaji;

  const PPh21Result({
    required this.gajiKotor,
    required this.ptkp,
    required this.pkp,
    required this.pajakBulanan,
    required this.pajakTahunanEst,
    required this.terRate,
    required this.netGaji,
  });
}

PPh21Result calculatePPh21(double gajiKotor, PtkpStatus status) {
  final ptkp    = status.ptkpAmount;
  final terEntry = AppConstants.terTableA.firstWhere(
    (t) => gajiKotor <= (t['max'] as num).toDouble(),
    orElse: () => AppConstants.terTableA.last,
  );
  final terRate      = (terEntry['rate'] as num).toDouble();
  final pajakBulanan = gajiKotor * terRate;
  final pkp          = ((gajiKotor * 12) - ptkp).clamp(0.0, double.infinity);

  return PPh21Result(
    gajiKotor:       gajiKotor,
    ptkp:            ptkp,
    pkp:             pkp,
    pajakBulanan:    pajakBulanan,
    pajakTahunanEst: pajakBulanan * 12,
    terRate:         terRate,
    netGaji:         gajiKotor - pajakBulanan,
  );
}

// ─── TER Table row (for display) ──────────────────────────────────────────────

class TerRow {
  final String rangeLabel;
  final double rate;
  final bool isActive;  // highlighted = matches current salary

  const TerRow({
    required this.rangeLabel,
    required this.rate,
    required this.isActive,
  });
}

/// Menyusun tabel TER untuk ditampilkan, **diturunkan dari
/// [AppConstants.terTableA]** — sumber yang sama dengan yang dibaca
/// [calculatePPh21].
///
/// Sebelumnya fungsi ini menyimpan daftar tarif kedua yang ditulis tangan, dan
/// daftar itu sudah menyimpang dari tabel hitungnya: gaji Rp 8.000.000
/// ditampilkan 1,5% padahal dihitung 2,0%, Rp 12.000.000 ditampilkan 5,0%
/// padahal dihitung 6,0%, dan lapisan tertinggi ditulis 19% padahal 34%.
/// Menurunkan keduanya dari satu sumber membuat divergensi itu tidak mungkin
/// terjadi lagi. Lihat temuan T-13 di docs/PROJECT_TIMELINE.md.
///
/// Lapisan berurutan yang bertarif sama digabung jadi satu rentang, supaya 32
/// baris mentah tidak semuanya tampil terpisah.
List<TerRow> buildTerTable(double gajiKotor) {
  final rows = <TerRow>[];

  double lowerBound = 0;
  double groupStart = 0;
  double? groupRate;

  void flush(double upperBound) {
    if (groupRate == null) return;
    rows.add(TerRow(
      rangeLabel: _rangeLabel(groupStart, upperBound),
      rate: groupRate,
      isActive: gajiKotor > groupStart &&
          (upperBound.isInfinite || gajiKotor <= upperBound),
    ));
  }

  for (final entry in AppConstants.terTableA) {
    final max = (entry['max'] as num).toDouble();
    final rate = (entry['rate'] as num).toDouble();

    if (groupRate == null) {
      groupStart = lowerBound;
      groupRate = rate;
    } else if (rate != groupRate) {
      flush(lowerBound);
      groupStart = lowerBound;
      groupRate = rate;
    }
    lowerBound = max;
  }
  flush(lowerBound);

  return rows;
}

/// `≤ Rp 5.400.000` · `Rp 5.400.001 – 6.300.000` · `> Rp 74.750.000`
String _rangeLabel(double from, double to) {
  if (from == 0) return '≤ ${_rupiah(to)}';
  if (to.isInfinite) return '> ${_rupiah(from)}';
  return '${_rupiah(from + 1)} – ${_thousands(to)}';
}

String _rupiah(double value) => 'Rp ${_thousands(value)}';

/// Pemisah ribuan bergaya Indonesia tanpa menarik `intl` ke berkas ini —
/// service ini sengaja tetap murni dan bebas dependensi.
String _thousands(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

// ─── Scenario Planner ─────────────────────────────────────────────────────────

class ScenarioInput {
  final double omzetBulanan;
  final int    employeeCount;
  final double avgGaji;
  final PtkpStatus ptkpStatus;
  final bool   isPkp;

  const ScenarioInput({
    required this.omzetBulanan,
    required this.employeeCount,
    required this.avgGaji,
    required this.ptkpStatus,
    required this.isPkp,
  });
}

class ScenarioResult {
  final String label;
  final double omzetBulanan;
  final double omzetTahunan;
  final double pphFinal;
  final double pph21Total;
  final double ppn;
  final double totalPajak;
  final double effectiveRate;
  final bool   isFeatured;

  const ScenarioResult({
    required this.label,
    required this.omzetBulanan,
    required this.omzetTahunan,
    required this.pphFinal,
    required this.pph21Total,
    required this.ppn,
    required this.totalPajak,
    required this.effectiveRate,
    required this.isFeatured,
  });
}

List<ScenarioResult> calculateScenarios(ScenarioInput base) {
  final multipliers = [
    ('Konservatif', 0.70, false),
    ('Base Case',   1.00, true),
    ('Optimistis',  1.40, false),
  ];

  return multipliers.map((m) {
    final (label, mul, featured) = m;
    final omzetBulanan  = base.omzetBulanan * mul;
    final omzetTahunan  = omzetBulanan * 12;
    final pphFinalRes   = calculatePPhFinal(omzetBulanan);
    final pphFinal      = pphFinalRes.eligible ? pphFinalRes.pajakTahunanEst : 0.0;

    final pph21PerKary  = calculatePPh21(base.avgGaji, base.ptkpStatus);
    final pph21Total    = pph21PerKary.pajakTahunanEst * base.employeeCount;

    final ppn           = base.isPkp ? omzetTahunan * AppConstants.ppnRate : 0.0;
    final totalPajak    = pphFinal + pph21Total + ppn;
    final effectiveRate = omzetTahunan > 0 ? totalPajak / omzetTahunan : 0.0;

    return ScenarioResult(
      label:         label,
      omzetBulanan:  omzetBulanan,
      omzetTahunan:  omzetTahunan,
      pphFinal:      pphFinal,
      pph21Total:    pph21Total,
      ppn:           ppn,
      totalPajak:    totalPajak,
      effectiveRate: effectiveRate,
      isFeatured:    featured,
    );
  }).toList();
}

// ─── Tax Deadline Calendar ─────────────────────────────────────────────────────

enum DeadlineStatus { urgent, warning, upcoming, overdue }

class TaxDeadlineItem {
  final String   id;
  final String   taxType;
  final String   label;
  final String   period;
  final DateTime deadline;
  final int      daysRemaining;

  const TaxDeadlineItem({
    required this.id,
    required this.taxType,
    required this.label,
    required this.period,
    required this.deadline,
    required this.daysRemaining,
  });

  DeadlineStatus get status {
    if (daysRemaining < 0)  return DeadlineStatus.overdue;
    if (daysRemaining <= 7) return DeadlineStatus.urgent;
    if (daysRemaining <= 30)return DeadlineStatus.warning;
    return DeadlineStatus.upcoming;
  }

  String get daysLabel {
    if (daysRemaining < 0)  return 'Terlambat!';
    if (daysRemaining == 0) return 'Hari ini!';
    return '${daysRemaining}h lagi';
  }
}

List<TaxDeadlineItem> generateCalendar({
  required int year,
  required bool isPkp,
  required bool hasEmployees,
}) {
  final items = <TaxDeadlineItem>[];
  final today = DateTime.now();

  String _monthName(int m) => [
    '','Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ][m];

  // PPh Final Masa — setiap bulan, jatuh tempo tgl 15 bulan berikutnya
  for (int m = 1; m <= 12; m++) {
    final deadline = DateTime(year, m + 1, 15);
    final days     = deadline.difference(today).inDays;
    items.add(TaxDeadlineItem(
      id:            'ppf-$year-$m',
      taxType:       'PPh Final',
      label:         'PPh Final Masa ${_monthName(m)} $year',
      period:        '$year-${m.toString().padLeft(2,'0')}',
      deadline:      deadline,
      daysRemaining: days,
    ));
  }

  // SPT Tahunan — 30 April tahun berikutnya
  final sptDeadline = DateTime(year + 1, 4, 30);
  items.add(TaxDeadlineItem(
    id:            'spt-$year',
    taxType:       'SPT Tahunan',
    label:         'SPT Tahunan PPh OP $year',
    period:        '$year',
    deadline:      sptDeadline,
    daysRemaining: sptDeadline.difference(today).inDays,
  ));

  // PPh 21 Masa — jatuh tempo tgl 10 bulan berikutnya (kalau ada karyawan)
  if (hasEmployees) {
    for (int m = 1; m <= 12; m++) {
      final deadline = DateTime(year, m + 1, 10);
      final days     = deadline.difference(today).inDays;
      items.add(TaxDeadlineItem(
        id:            'p21-$year-$m',
        taxType:       'PPh 21',
        label:         'PPh 21 Masa ${_monthName(m)} $year',
        period:        '$year-${m.toString().padLeft(2,'0')}',
        deadline:      deadline,
        daysRemaining: days,
      ));
    }
  }

  // PPN Masa — jatuh tempo akhir bulan berikutnya (kalau PKP)
  if (isPkp) {
    for (int m = 1; m <= 12; m++) {
      final deadline = DateTime(year, m + 1, 30);
      final days     = deadline.difference(today).inDays;
      items.add(TaxDeadlineItem(
        id:            'ppn-$year-$m',
        taxType:       'PPN',
        label:         'PPN Masa ${_monthName(m)} $year',
        period:        '$year-${m.toString().padLeft(2,'0')}',
        deadline:      deadline,
        daysRemaining: days,
      ));
    }
  }

  // Sort by deadline
  items.sort((a, b) => a.deadline.compareTo(b.deadline));
  return items;
}
