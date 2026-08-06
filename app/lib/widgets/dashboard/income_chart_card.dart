// lib/widgets/dashboard/income_chart_card.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// ─── Chart range enum ─────────────────────────────────────────────────────────

enum ChartRange { week, month, threeMonth, ytd, year, threeYear }

extension ChartRangeExt on ChartRange {
  String get label {
    switch (this) {
      case ChartRange.week:       return '1M';
      case ChartRange.month:      return '1B';
      case ChartRange.threeMonth: return '3B';
      case ChartRange.ytd:        return 'YTD';
      case ChartRange.year:       return '1T';
      case ChartRange.threeYear:  return '3T';
    }
  }

  String get subtitle {
    switch (this) {
      case ChartRange.week:       return '1 minggu terakhir';
      case ChartRange.month:      return '1 bulan terakhir';
      case ChartRange.threeMonth: return '3 bulan terakhir';
      case ChartRange.ytd:        return 'Tahun berjalan 2025';
      case ChartRange.year:       return '1 tahun terakhir';
      case ChartRange.threeYear:  return '3 tahun terakhir';
    }
  }
}

// ─── Chart data point ─────────────────────────────────────────────────────────

class ChartPoint {
  final DateTime date;
  final double income;
  final double expense;

  const ChartPoint({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get profit => income - expense;

  String labelFor(ChartRange r) {
    switch (r) {
      case ChartRange.week:
        return '${_weekDay(date.weekday)}, ${date.day} ${_mon(date.month)}';
      case ChartRange.month:
        return '${date.day} ${_mon(date.month)} ${date.year}';
      case ChartRange.threeMonth:
        return '${date.day} ${_mon(date.month)} ${date.year}';
      case ChartRange.ytd:
      case ChartRange.year:
        return '${_mon(date.month)} ${date.year}';
      case ChartRange.threeYear:
        return 'Q${((date.month - 1) ~/ 3) + 1} ${date.year}';
    }
  }

  static String _mon(int m) => const [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ][m - 1];

  static String _weekDay(int w) => const [
    '','Sen','Sel','Rab','Kam','Jum','Sab','Min',
  ][w];
}

// ─── Dummy data generator ─────────────────────────────────────────────────────

List<ChartPoint> generateDummyData(ChartRange range) {
  final now   = DateTime(2025, 10, 28);
  final pts   = <ChartPoint>[];
  final rand  = List.generate(50, (i) => 0.5 + (i * 13 % 10) / 10.0);
  int ri = 0;
  double r() { final v = rand[ri++ % rand.length]; return v; }

  switch (range) {
    case ChartRange.week:
      for (int i = 6; i >= 0; i--) {
        final d   = now.subtract(Duration(days: i));
        final inc = 15e6 + r() * 17e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.55 + r() * 0.13)));
      }
    case ChartRange.month:
      for (int i = 29; i >= 0; i -= 5) {
        final d   = now.subtract(Duration(days: i));
        final inc = 10e6 + r() * 25e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.55 + r() * 0.15)));
      }
    case ChartRange.threeMonth:
      for (int i = 12; i >= 0; i--) {
        final d   = now.subtract(Duration(days: i * 7));
        final inc = 20e6 + r() * 20e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.57 + r() * 0.11)));
      }
    case ChartRange.ytd:
      for (int m = 0; m <= 9; m++) {
        final d   = DateTime(2025, m + 1, 28);
        final inc = 24e6 + m * 5e5 + r() * 4e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.58 + r() * 0.1)));
      }
    case ChartRange.year:
      for (int i = 11; i >= 0; i--) {
        final d   = DateTime(now.year, now.month - i, 28);
        final inc = 22e6 + i * 4e5 + r() * 5e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.58 + r() * 0.11)));
      }
    case ChartRange.threeYear:
      for (int q = 11; q >= 0; q--) {
        final mo  = now.month - q * 3;
        final yr  = now.year + (mo <= 0 ? -1 : 0);
        final d   = DateTime(yr, mo <= 0 ? mo + 12 : mo, 28);
        final inc = 60e6 + q * 2e6 + r() * 10e6;
        pts.add(ChartPoint(date: d, income: inc, expense: inc * (0.60 + r() * 0.08)));
      }
  }
  return pts;
}

// ─── Income Chart Card ────────────────────────────────────────────────────────

class IncomeChartCard extends StatefulWidget {
  final List<ChartPoint>? data;
  const IncomeChartCard({super.key, this.data});

  @override
  State<IncomeChartCard> createState() => _IncomeChartCardState();
}

class _IncomeChartCardState extends State<IncomeChartCard> {
  ChartRange _range = ChartRange.week;
  late List<ChartPoint> _pts;

  @override
  void initState() {
    super.initState();
    _pts = widget.data ?? generateDummyData(_range);
  }

  void _setRange(ChartRange r) {
    setState(() {
      _range   = r;
      _pts     = widget.data ?? generateDummyData(r);
    });
  }

  double get _totalIncome  => _pts.fold(0, (s, p) => s + p.income);
  double get _totalExpense => _pts.fold(0, (s, p) => s + p.expense);
  double get _totalProfit  => _totalIncome - _totalExpense;
  double get _avgMargin    =>
      _totalIncome > 0 ? _totalProfit / _totalIncome * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pemasukan vs Pengeluaran',
                    style: AppTextStyles.display(13)),
                  const SizedBox(height: 2),
                  Text(_range.subtitle,
                    style: AppTextStyles.body(10, color: AppColors.stone400)),
                ],
              )),
              const SizedBox(width: 8),
              _RangeTabs(
                current: _range,
                onChanged: _setRange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Stats row ─────────────────────────────────────
          Row(children: [
            _StatChip(
              label: 'Total Pemasukan',
              value: Rupiah.compact(_totalIncome),
              color: AppColors.income),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Total Pengeluaran',
              value: Rupiah.compact(_totalExpense),
              color: AppColors.expense),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Laba Kotor',
              value: Rupiah.compact(_totalProfit),
              color: const Color(0xFF185FA5)),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Rata-rata Margin',
              value: '${_avgMargin.toStringAsFixed(1)}%',
              color: AppColors.warning),
          ]),
          const SizedBox(height: 14),

          // ── Chart ─────────────────────────────────────────
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.stone200,
                    strokeWidth: 0.5,
                  ),
                ),
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
                      reservedSize: 20,
                      getTitlesWidget: _buildXTitle,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Theme.of(context).cardColor,
                    tooltipBorder: BorderSide(
                      color: AppColors.stone200, width: 0.5),
                    getTooltipItems: (spots) {
                      final idx = spots.first.spotIndex;
                      if (idx < 0 || idx >= _pts.length) return [];
                      final p = _pts[idx];
                      return spots.map((s) {
                        switch (s.barIndex) {
                          case 0:
                            return LineTooltipItem(
                              '${p.labelFor(_range)}\n',
                              AppTextStyles.body(10, weight: FontWeight.w500),
                              children: [
                                TextSpan(
                                  text: 'Pemasukan: ${Rupiah.compact(p.income)}\n'
                                        'Pengeluaran: ${Rupiah.compact(p.expense)}\n'
                                        'Laba: ${Rupiah.compact(p.profit)}',
                                  style: AppTextStyles.body(9,
                                    color: AppColors.stone500),
                                ),
                              ],
                            );
                          default:
                            return const LineTooltipItem('', TextStyle());
                        }
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                minY: 0,
                maxY: _maxY,
                lineBarsData: [
                  _line(
                    pts: _pts.map((p) => p.income).toList(),
                    color: AppColors.income),
                  _line(
                    pts: _pts.map((p) => p.expense).toList(),
                    color: AppColors.expense),
                  _line(
                    pts: _pts.map((p) => p.profit).toList(),
                    color: const Color(0xFF185FA5),
                    dashed: true,
                    opacity: 0.55),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Legend ────────────────────────────────────────
          Row(children: [
            _LegendItem(label: 'Pemasukan',  color: AppColors.income),
            const SizedBox(width: 14),
            _LegendItem(label: 'Pengeluaran',color: AppColors.expense),
            const SizedBox(width: 14),
            _LegendItem(
              label: 'Laba bersih',
              color: const Color(0xFF185FA5),
              dashed: true),
          ]),
        ],
      ),
    );
  }

  double get _maxY {
    final maxV = _pts.isEmpty ? 1.0
        : _pts.map((p) => p.income).reduce((a, b) => a > b ? a : b);
    return maxV * 1.2;
  }

  LineChartBarData _line({
    required List<double> pts,
    required Color color,
    bool dashed = false,
    double opacity = 1.0,
  }) {
    return LineChartBarData(
      spots: pts.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList(),
      color: color.withOpacity(opacity),
      barWidth: dashed ? 1.5 : 2,
      isCurved: true,
      curveSmoothness: 0.35,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, idx) => FlDotCirclePainter(
          radius: 3.5,
          color: color.withOpacity(opacity),
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
      dashArray: dashed ? [5, 4] : null,
      belowBarData: BarAreaData(
        show: !dashed,
        color: color.withOpacity(0.04),
      ),
    );
  }

  Widget _buildXTitle(double val, TitleMeta meta) {
    final i = val.toInt();
    if (i < 0 || i >= _pts.length) return const SizedBox.shrink();
    // Show first, last, and evenly spaced middle labels
    final total = _pts.length;
    final step  = (total / 6).ceil().clamp(1, total);
    if (i != 0 && i != total - 1 && i % step != 0) {
      return const SizedBox.shrink();
    }
    final lbl = _pts[i].labelFor(_range).split(' ').first;
    return Text(lbl,
      style: AppTextStyles.body(8, color: AppColors.stone400),
      textAlign: TextAlign.center);
  }
}

// ─── Range tabs ───────────────────────────────────────────────────────────────

class _RangeTabs extends StatelessWidget {
  final ChartRange current;
  final ValueChanged<ChartRange> onChanged;

  const _RangeTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChartRange.values.map((r) {
          final on = r == current;
          return GestureDetector(
            onTap: () => onChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: on
                    ? Theme.of(context).cardColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: on
                    ? Border.all(
                        color: AppColors.stone200, width: 0.5)
                    : null,
              ),
              child: Text(r.label,
                style: AppTextStyles.body(10,
                  color: on
                      ? AppColors.stone700
                      : AppColors.stone400,
                  weight: on
                      ? FontWeight.w500
                      : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
              style: AppTextStyles.mono(12,
                color: color, weight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(label,
              style: AppTextStyles.body(9, color: AppColors.stone400),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Legend item ──────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   dashed;

  const _LegendItem({
    required this.label,
    required this.color,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (dashed)
        SizedBox(
          width: 16, height: 2,
          child: CustomPaint(
            painter: _DashPainter(color: color.withOpacity(0.6)),
          ),
        )
      else
        Container(
          width: 16, height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1)),
        ),
      const SizedBox(width: 5),
      Text(label,
        style: AppTextStyles.body(10, color: AppColors.stone500)),
    ]);
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashW = 4.0, gapW = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dashW).clamp(0, size.width), size.height / 2),
        paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}