// lib/widgets/dashboard/kpi_card.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';

// ── KPI Types ─────────────────────────────────────────────────────────────────

enum KpiType { margin, income, expense, profit, ytd }

class KpiHistory {
  final String month;
  final double value;
  const KpiHistory({required this.month, required this.value});
}


// ─── KPI Grid (5-card layout) ─────────────────────────────────────────────────

class KpiGrid extends StatelessWidget {
  final double income, expense, profit, ytdOmzet;
  final bool isLoading;
  final List<KpiHistory> incomeHistory, expenseHistory, profitHistory, ytdHistory;
  final double marginPercent;
  final double barPercent;

  const KpiGrid({
    super.key,
    required this.income,
    required this.expense,
    required this.profit,
    required this.ytdOmzet,
    this.isLoading = false,
    this.incomeHistory  = const [],
    this.expenseHistory = const [],
    this.profitHistory  = const [],
    this.ytdHistory     = const [],
    this.marginPercent  = 0,
    this.barPercent     = 0,
  });

  @override
  Widget build(BuildContext context) {
    final margin = income > 0 ? profit / income * 100 : 0.0;
    final ytdBar = ytdOmzet / 4800000000; // vs PKP threshold

    return LayoutBuilder(builder: (_, box) {
      final wide = box.maxWidth > 600;
      if (wide) {
        return IntrinsicHeight(child: Row(children: [
          Expanded(flex: 135, child: _WideKpiCard(
            type: KpiType.margin,
            value: margin,
            isLoading: isLoading,
            badgeLabel: profit >= 0 ? 'Untung' : 'Rugi',
            badgePositive: profit >= 0,
            subLeft: 'Laba: ${Rupiah.compact(profit)}',
            subRight: 'Omzet: ${Rupiah.compact(income)}',
            barPercent: (margin / 100).clamp(0, 1),
            history: incomeHistory,
          )),
          const SizedBox(width: 8),
          Expanded(flex: 100, child: _NormalKpiCard(
            type: KpiType.income,
            value: income,
            isLoading: isLoading,
            change: 0,
            history: incomeHistory,
          )),
          const SizedBox(width: 8),
          Expanded(flex: 100, child: _NormalKpiCard(
            type: KpiType.expense,
            value: expense,
            isLoading: isLoading,
            change: 0,
            history: expenseHistory,
          )),
          const SizedBox(width: 8),
          Expanded(flex: 100, child: _NormalKpiCard(
            type: KpiType.profit,
            value: profit,
            isLoading: isLoading,
            change: 0,
            history: profitHistory,
          )),
          const SizedBox(width: 8),
          Expanded(flex: 135, child: _WideKpiCard(
            type: KpiType.ytd,
            value: ytdOmzet,
            isLoading: isLoading,
            badgeLabel: ytdBar >= 1 ? 'PKP' : 'Non-PKP',
            badgePositive: ytdBar < 1,
            subLeft: '${(ytdBar * 100).toStringAsFixed(1)}% threshold',
            subRight: 'Target Rp 4,8 M',
            barPercent: ytdBar.clamp(0, 1),
            history: ytdHistory,
          )),
        ]));
      }
      // Narrow: 2-row layout
      return Column(children: [
        Row(children: [
          Expanded(child: _WideKpiCard(
            type: KpiType.margin, value: margin,
            isLoading: isLoading, badgeLabel: profit >= 0 ? 'Untung' : 'Rugi',
            badgePositive: profit >= 0,
            subLeft: 'Laba: ${Rupiah.compact(profit)}',
            subRight: 'Omzet: ${Rupiah.compact(income)}',
            barPercent: (margin / 100).clamp(0, 1),
            history: incomeHistory,
          )),
          const SizedBox(width: 8),
          Expanded(child: _WideKpiCard(
            type: KpiType.ytd, value: ytdOmzet,
            isLoading: isLoading,
            badgeLabel: ytdBar >= 1 ? 'PKP' : 'Non-PKP',
            badgePositive: ytdBar < 1,
            subLeft: '${(ytdBar * 100).toStringAsFixed(1)}% threshold',
            subRight: 'Target Rp 4,8 M',
            barPercent: ytdBar.clamp(0, 1),
            history: ytdHistory,
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _NormalKpiCard(type: KpiType.income,
            value: income, isLoading: isLoading, change: 0,
            history: incomeHistory)),
          const SizedBox(width: 8),
          Expanded(child: _NormalKpiCard(type: KpiType.expense,
            value: expense, isLoading: isLoading, change: 0,
            history: expenseHistory)),
          const SizedBox(width: 8),
          Expanded(child: _NormalKpiCard(type: KpiType.profit,
            value: profit, isLoading: isLoading, change: 0,
            history: profitHistory)),
        ]),
      ]);
    });
  }
}

class _WideKpiCard extends StatefulWidget {
  final KpiType type;
  final double  value;
  final bool    isLoading;
  final String  badgeLabel;
  final bool    badgePositive;
  final String  subLeft;
  final String  subRight;
  final double  barPercent;
  final List<KpiHistory> history;

  const _WideKpiCard({
    required this.type,
    required this.value,
    required this.isLoading,
    required this.badgeLabel,
    required this.badgePositive,
    required this.subLeft,
    required this.subRight,
    required this.barPercent,
    required this.history,
  });

  _KpiStyle get _s => _styleFor(type);

  String get _valueStr {
    if (type == KpiType.margin) return '${value.toStringAsFixed(1)}%';
    return Rupiah.compact(value);
  }


  @override
  State<_WideKpiCard> createState() => _WideKpiCardState();
}

class _WideKpiCardState extends State<_WideKpiCard> {
  bool _hovered = false;
  _KpiStyle get _s         => widget._s;
  String    get _valueStr  => widget._valueStr;
  double    get barPercent => widget.barPercent;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
      onTap: widget.isLoading ? null : () =>
          _KpiHistorySheet.show(context, type: widget.type, history: widget.history,
            currentValue: widget.value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? _s.cardBg : _s.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppColors.stone300 : _s.border,
            width: 1.5),
          boxShadow: _hovered ? [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: widget.isLoading
            ? const ShimmerBox(width: double.infinity, height: 80)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _s.iconBg,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(_s.icon, size: 14, color: _s.color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _s.iconBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.badgeLabel,
                          style: AppTextStyles.body(9,
                            color: _s.badgeText, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(_valueStr,
                    style: AppTextStyles.mono(14,
                      color: _s.color, weight: FontWeight.w600)),
                  Text(_s.label,
                    style: AppTextStyles.body(10, color: AppColors.stone400)),
                  // Progress bar
                  Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _s.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: barPercent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _s.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(widget.subLeft,
                        style: AppTextStyles.body(9, color: _s.color),
                        overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      Flexible(child: Text(widget.subRight,
                        style: AppTextStyles.body(9,
                          color: AppColors.stone400),
                        overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
      ),
    ),
    );
  }
}

// ─── Normal KPI card ──────────────────────────────────────────────────────────

class _NormalKpiCard extends StatefulWidget {
  final KpiType type;
  final double value;
  final bool isLoading;
  final double  change;
  final List<KpiHistory> history;

  const _NormalKpiCard({
    required this.type,
    required this.value,
    required this.isLoading,
    required this.change,
    required this.history,
  });

  _KpiStyle get _s => _styleFor(type);
  bool get _isPositive => change >= 0;
  bool get _badgeGood => type == KpiType.expense ? !_isPositive : _isPositive;


  @override
  State<_NormalKpiCard> createState() => _NormalKpiCardState();
}

class _NormalKpiCardState extends State<_NormalKpiCard> {
  bool _hovered = false;
  _KpiStyle get _s          => widget._s;
  bool      get _badgeGood  => widget._badgeGood;
  bool      get _isPositive => widget._isPositive;
  double    get change      => widget.change;

  @override
  Widget build(BuildContext context) {
    final badgeBg   = _badgeGood ? AppColors.incomeLight : AppColors.expenseLight;
    final badgeFg   = _badgeGood ? AppColors.income : AppColors.expense;
    final changeStr = '${_isPositive ? '+' : ''}${change.toStringAsFixed(1)}%';

    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
      onTap: widget.isLoading ? null : () =>
          _KpiHistorySheet.show(context, type: widget.type, history: widget.history,
            currentValue: widget.value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget._s.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppColors.stone300 : widget._s.border,
            width: _hovered ? 1.0 : 0.5),
          boxShadow: _hovered ? [BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: widget.isLoading
            ? const ShimmerBox(width: double.infinity, height: 72)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _s.iconBg,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(_s.icon, size: 14, color: _s.color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(changeStr,
                          style: AppTextStyles.body(9,
                            color: badgeFg, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(Rupiah.compact(widget.value),
                    style: AppTextStyles.mono(14,
                      color: _s.color, weight: FontWeight.w600)),
                  Text(_s.label,
                    style: AppTextStyles.body(10, color: AppColors.stone400)),
                ],
              ),
        ),
      ),
    );
  }
}

// ─── History Bottom Sheet ─────────────────────────────────────────────────────

class _KpiHistorySheet extends StatelessWidget {
  final KpiType type;
  final List<KpiHistory> history;
  final double currentValue;

  const _KpiHistorySheet({
    required this.type,
    required this.history,
    required this.currentValue,
  });

  static void show(BuildContext context, {
    required KpiType type,
    required List<KpiHistory> history,
    required double currentValue,
  }) {
    showDialog(
      context:          context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: _KpiHistorySheet(
            type: type, history: history, currentValue: currentValue),
        ),
      ),
    );
  }

  _KpiStyle get _s => _styleFor(type);
  bool get _isPercent => type == KpiType.margin;

  String _fmt(double v) =>
      _isPercent ? '${v.toStringAsFixed(1)}%' : Rupiah.compact(v);

  String _fmtFull(double v) =>
      _isPercent ? '${v.toStringAsFixed(2)}%' : Rupiah.format(v);

  double get _avg => history.isEmpty ? 0
      : history.map((h) => h.value).reduce((a, b) => a + b) / history.length;

  double get _max => history.isEmpty ? 0
      : history.map((h) => h.value).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final maxVal = history.isEmpty ? 1.0
        : history.map((h) => h.value).reduce((a, b) => a > b ? a : b);

    return Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone200,
              borderRadius: BorderRadius.circular(2)),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(_s.sheetTitle,
                    style: AppTextStyles.display(16)),
                  const SizedBox(height: 2),
                  Text('10 bulan terakhir',
                    style: AppTextStyles.body(12, color: AppColors.stone400)),
                  const SizedBox(height: 16),

                  // Bar chart
                  if (history.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: BarChart(
                        BarChartData(
                          maxY: maxVal * 1.2,
                          barTouchData: BarTouchData(enabled: false),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles:   AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            rightTitles:  AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            topTitles:    AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= history.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(history[i].month,
                                    style: AppTextStyles.body(8,
                                      color: AppColors.stone400));
                                },
                              ),
                            ),
                          ),
                          barGroups: history.asMap().entries.map((e) {
                            final isLast = e.key == history.length - 1;
                            return BarChartGroupData(x: e.key, barRods: [
                              BarChartRodData(
                                toY: e.value.value,
                                color: isLast
                                    ? _s.color
                                    : _s.color.withOpacity(0.25),
                                width: 18,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3 stat chips
                  Row(children: [
                    _StatChip(label: 'Bulan Ini',
                      value: _fmt(currentValue), color: _s.color),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Rata-rata',
                      value: _fmt(_avg), color: AppColors.stone500),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Tertinggi',
                      value: _fmt(_max), color: AppColors.warning),
                  ]),
                  const SizedBox(height: 16),

                  // Historical table
                  _buildTable(),
                ],
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildTable() {
    final reversed = history.reversed.toList();
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2.5),
        2: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.stone200, width: 0.5))),
          children: [
            _th('Bulan'),
            _th(_s.colHeader),
            _th('vs Bln Lalu'),
          ],
        ),
        // Rows
        ...reversed.asMap().entries.map((e) {
          final idx      = history.length - 1 - e.key;
          final isLatest = e.key == 0;
          final prev     = idx > 0 ? history[idx - 1].value : null;
          final chg      = prev != null
              ? ((e.value.value - prev) / prev * 100)
              : null;
          final up = chg != null && chg >= 0;

          // For expense: up is bad
          final goodDir = type == KpiType.expense ? !up : up;

          return TableRow(
            decoration: isLatest
                ? BoxDecoration(
                    color: _s.cardBg,
                    borderRadius: BorderRadius.circular(6))
                : null,
            children: [
              _td('${e.value.month} 2025',
                suffix: isLatest ? ' ←' : null,
                suffixColor: _s.color),
              _td(_fmtFull(e.value.value), mono: true),
              _td(
                chg != null
                  ? '${up ? '▲' : '▼'} ${chg.abs().toStringAsFixed(1)}%'
                  : '—',
                color: chg == null
                  ? AppColors.stone400
                  : goodDir ? AppColors.income : AppColors.expense,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _th(String t) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 10, vertical: 7),
    child: Text(t,
      style: AppTextStyles.body(10,
        color: AppColors.stone400, weight: FontWeight.w500)),
  );

  Widget _td(String t, {
    bool mono = false, Color? color,
    String? suffix, Color? suffixColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 10, vertical: 8),
    child: Row(children: [
      Text(t,
        style: mono
            ? AppTextStyles.mono(11,
                color: color ?? AppColors.stone700)
            : AppTextStyles.body(11,
                color: color ?? AppColors.stone700,
                weight: FontWeight.w400)),
      if (suffix != null)
        Text(suffix,
          style: AppTextStyles.body(10,
            color: suffixColor ?? AppColors.brand,
            weight: FontWeight.w600)),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.stone100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
              style: AppTextStyles.mono(12,
                color: color, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label,
              style: AppTextStyles.body(10, color: AppColors.stone400)),
          ],
        ),
      ),
    );
  }
}

// ─── Style config per widget.type ────────────────────────────────────────────────────

class _KpiStyle {
  final Color   color;
  final Color   cardBg;
  final Color   iconBg;
  final Color   border;
  final Color   badgeText;
  final IconData icon;
  final String  label;
  final String  sheetTitle;
  final String  colHeader;

  const _KpiStyle({
    required this.color,
    required this.cardBg,
    required this.iconBg,
    required this.border,
    required this.badgeText,
    required this.icon,
    required this.label,
    required this.sheetTitle,
    required this.colHeader,
  });
}

_KpiStyle _styleFor(KpiType t) {
  switch (t) {
    case KpiType.margin:
      return _KpiStyle(
        color:      const Color(0xFF185FA5),
        cardBg:     AppColors.accentLight,
        iconBg:     AppColors.accentLight,
        border:     AppColors.navyBorder,
        badgeText:  AppColors.navyBadgeFg,
        icon:       Icons.percent_rounded,
        label:      'Margin Laba Bersih',
        sheetTitle: 'Margin Laba Bersih',
        colHeader:  'Margin',
      );
    case KpiType.income:
      return _KpiStyle(
        color:      AppColors.income,
        cardBg:     AppColors.incomeLight,
        iconBg:     AppColors.incomeLight,
        border:     AppColors.incomeBorder,
        badgeText:  AppColors.incomeBadgeFg,
        icon:       Icons.trending_up_rounded,
        label:      'Pemasukan Bulan Ini',
        sheetTitle: 'Pemasukan Bulanan',
        colHeader:  'Pemasukan',
      );
    case KpiType.expense:
      return _KpiStyle(
        color:      AppColors.expense,
        cardBg:     AppColors.expenseLight,
        iconBg:     AppColors.expenseLight,
        border:     AppColors.expenseBorder,
        badgeText:  AppColors.expenseBadgeFg,
        icon:       Icons.trending_down_rounded,
        label:      'Pengeluaran Bulan Ini',
        sheetTitle: 'Pengeluaran Bulanan',
        colHeader:  'Pengeluaran',
      );
    case KpiType.profit:
      return _KpiStyle(
        color:      AppColors.income,
        cardBg:     AppColors.incomeLight,
        iconBg:     AppColors.incomeLight,
        border:     AppColors.incomeBorder,
        badgeText:  AppColors.incomeBadgeFg,
        icon:       Icons.account_balance_wallet_outlined,
        label:      'Laba Bersih',
        sheetTitle: 'Laba Bersih Bulanan',
        colHeader:  'Laba Bersih',
      );
    case KpiType.ytd:
      return _KpiStyle(
        color:      AppColors.warning,
        cardBg:     AppColors.warningLight,
        iconBg:     AppColors.warningLight,
        border:     AppColors.warningBorder,
        badgeText:  AppColors.warningBadgeFg,
        icon:       Icons.bar_chart_rounded,
        label:      'Omzet YTD',
        sheetTitle: 'Akumulasi Omzet YTD',
        colHeader:  'Omzet Kumulatif',
      );
  }
}
