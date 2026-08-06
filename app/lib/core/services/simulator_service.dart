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

  double get ptkpAmount => AppConstants.ptkp[shortLabel.replaceAll('/','')]! ;
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
  final ptkp    = AppConstants.ptkp[status.shortLabel.replaceAll('/','')]!;
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

List<TerRow> buildTerTable(double gajiKotor) {
  final displayRows = [
    ('≤ Rp 5.400.000',           5400000.0,   0.000),
    ('Rp 5.401.000 – 6.300.000', 6300000.0,   0.005),
    ('Rp 6.301.000 – 7.500.000', 7500000.0,   0.010),
    ('Rp 7.501.000 – 9.650.000', 9650000.0,   0.015),
    ('Rp 9.651.000 – 10.050.000',10050000.0,  0.020),
    ('Rp 10.051.000 – 10.700.000',10700000.0, 0.030),
    ('Rp 10.701.000 – 11.050.000',11050000.0, 0.040),
    ('Rp 11.051.000 – 12.500.000',12500000.0, 0.050),
    ('Rp 12.501.000 – 15.100.000',15100000.0, 0.075),
    ('Rp 15.101.000 – 19.750.000',19750000.0, 0.100),
    ('Rp 19.751.000 – 26.450.000',26450000.0, 0.125),
    ('Rp 26.451.000 – 30.050.000',30050000.0, 0.150),
    ('> Rp 30.050.000',          double.infinity, 0.190),
  ];

  return displayRows.map((r) {
    final (label, max, rate) = r;
    return TerRow(
      rangeLabel: label,
      rate: rate,
      isActive: gajiKotor > 0 && gajiKotor <= max &&
          displayRows.indexOf(r) ==
              displayRows.indexWhere((x) => gajiKotor <= x.$2),
    );
  }).toList();
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
