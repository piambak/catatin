// lib/models/dashboard_model.dart

import '../core/constants/app_constants.dart';

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
        deadline: DateTime.parse(j['deadline'] as String),
        status: j['status'] as String,
      );
}
