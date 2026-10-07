// lib/screens/accounting/total_tab.dart
//
// Tab Total beserta grafik-grafiknya.
//
// Dipecah dari accounting_screen.dart (2.451 baris) untuk PRD R-7 / issue #52.
// Pemindahan murni: tidak ada perilaku yang diubah. Hanya delapan kelas yang
// naik jadi publik, yaitu yang dipakai lintas berkas.

import 'package:flutter/material.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/accounting/tx_list_tile.dart';
import '../../widgets/common/app_widgets.dart';
import 'accounting_shared.dart';
import 'package:fl_chart/fl_chart.dart';

class TotalTab extends StatelessWidget {
  final List<TxData> allTx;
  final bool loading;

  const TotalTab({required this.allTx, required this.loading});

  double get _totalIncome =>
      allTx.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _totalExpense =>
      allTx.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _profit => _totalIncome - _totalExpense;
  double get _margin => _totalIncome > 0 ? _profit / _totalIncome * 100 : 0;

  // Average daily income (rough: assume 22 working days)
  double get _avgDaily => _totalIncome / 22;

  // Transaction counts
  int get _incomeCount => allTx.where((t) => t.isIncome).length;
  int get _expenseCount => allTx.where((t) => !t.isIncome).length;
  double get _avgTxValue =>
      allTx.isEmpty ? 0 : ((_totalIncome + _totalExpense) / allTx.length);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ── 4 KPI chips ───────────────────────────────────────
        Row(
          children: [
            _StatChip(
              label: 'Total Pemasukan',
              value: Rupiah.compact(_totalIncome),
              color: DS.income,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Total Pengeluaran',
              value: Rupiah.compact(_totalExpense),
              color: DS.expense,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatChip(
              label: 'Laba Bersih',
              value: Rupiah.compact(_profit),
              color: _profit >= 0 ? const Color(0xFF185FA5) : DS.expense,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Margin',
              value: Pct.formatValue(_margin),
              color: DS.brandDeep,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatChip(
              label: 'Rata-rata Harian',
              value: Rupiah.compact(_avgDaily),
              color: DS.muted,
            ),
            const SizedBox(width: 8),
            _StatChip(
              label: 'Total Transaksi',
              value: '${allTx.length} tx',
              color: DS.muted,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Bar chart — income vs expense 6 months ────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pemasukan vs Pengeluaran', style: Typo.serif(13)),
              Text('6 bulan terakhir', style: Typo.sans(10, color: DS.faint)),
              const SizedBox(height: 14),
              Semantics(
                label:
                    'Grafik batang pemasukan dan pengeluaran enam bulan terakhir',
                child: ExcludeSemantics(child: _BarChart(allTx: allTx)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  LegDot(color: DS.income, label: 'Pemasukan'),
                  const SizedBox(width: 12),
                  LegDot(color: DS.expense, label: 'Pengeluaran'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Line chart — cumulative laba ──────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tren Laba Kumulatif', style: Typo.serif(13)),
              Text(
                'Akumulasi laba per bulan',
                style: Typo.sans(10, color: DS.faint),
              ),
              const SizedBox(height: 14),
              Semantics(
                label: 'Grafik garis tren laba enam bulan terakhir',
                child: ExcludeSemantics(child: _LineChart(allTx: allTx)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Pie chart — income vs expense composition ─────────
        LayoutBuilder(
          builder: (_, box) {
            final wide = box.maxWidth > 500;
            if (wide) {
              return Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Komposisi Arus Kas', style: Typo.serif(13)),
                          Text(
                            'Pemasukan vs Pengeluaran',
                            style: Typo.sans(10, color: DS.faint),
                          ),
                          const SizedBox(height: 14),
                          Semantics(
                            label:
                                'Diagram lingkaran perbandingan pemasukan dan pengeluaran',
                            child: ExcludeSemantics(
                              child: _PieChart(
                                income: _totalIncome,
                                expense: _totalExpense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategori Pengeluaran', style: Typo.serif(13)),
                          Text(
                            'Top 5 terbesar',
                            style: Typo.sans(10, color: DS.faint),
                          ),
                          const SizedBox(height: 14),
                          Semantics(
                            label:
                                'Diagram lingkaran komposisi pengeluaran per kategori',
                            child: ExcludeSemantics(
                              child: _ExpensePieChart(allTx: allTx),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Komposisi Arus Kas', style: Typo.serif(13)),
                      Text(
                        'Pemasukan vs Pengeluaran',
                        style: Typo.sans(10, color: DS.faint),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label:
                            'Diagram lingkaran perbandingan pemasukan dan pengeluaran',
                        child: ExcludeSemantics(
                          child: _PieChart(
                            income: _totalIncome,
                            expense: _totalExpense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori Pengeluaran', style: Typo.serif(13)),
                      Text(
                        'Top 5 terbesar',
                        style: Typo.sans(10, color: DS.faint),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        label:
                            'Diagram lingkaran komposisi pengeluaran per kategori',
                        child: ExcludeSemantics(
                          child: _ExpensePieChart(allTx: allTx),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),

        // ── Category breakdown (bar) ──────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rincian Pengeluaran', style: Typo.serif(13)),
              const SizedBox(height: 10),
              _CategoryBreakdown(allTx: allTx),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Tx stats row ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frekuensi Transaksi', style: Typo.serif(13)),
                    const SizedBox(height: 8),
                    _StatsRow(
                      icon: Icons.trending_up_rounded,
                      label: 'Pemasukan',
                      value: '$_incomeCount transaksi',
                      color: DS.income,
                    ),
                    const SizedBox(height: 4),
                    _StatsRow(
                      icon: Icons.trending_down_rounded,
                      label: 'Pengeluaran',
                      value: '$_expenseCount transaksi',
                      color: DS.expense,
                    ),
                    const SizedBox(height: 4),
                    _StatsRow(
                      icon: Icons.payments_outlined,
                      label: 'Rata-rata nilai',
                      value: Rupiah.compact(_avgTxValue),
                      color: DS.muted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Frequent transactions ─────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaksi Paling Sering', style: Typo.serif(13)),
              Text(
                'Berdasarkan frekuensi',
                style: Typo.sans(10, color: DS.faint),
              ),
              const SizedBox(height: 10),
              _FrequentList(allTx: allTx),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatsRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: Typo.sans(11, color: DS.muted)),
      ),
      Text(
        value,
        style: Typo.sans(11, color: color, weight: FontWeight.w600),
      ),
    ],
  );
}

// ── Line Chart (cumulative profit) ───────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<TxData> allTx;
  const _LineChart({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i),
    );

    double cumulative = 0;
    final spots = months.asMap().entries.map((e) {
      final m = e.value;
      final txs = allTx.where(
        (t) => t.date.year == m.year && t.date.month == m.month,
      );
      final inc = txs
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      final exp = txs
          .where((t) => !t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      cumulative += (inc - exp);
      return FlSpot(e.key.toDouble(), cumulative / 1000000);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    const labels = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthLabels = months.map((m) => labels[m.month]).toList();

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0
                ? (maxY / 3).clamp(1, double.infinity)
                : 1,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: DS.hairline, strokeWidth: .5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= monthLabels.length)
                    return const SizedBox.shrink();
                  return Text(
                    monthLabels[i],
                    style: Typo.sans(8, color: DS.faint),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minY < 0 ? minY * 1.1 : 0,
          maxY: maxY > 0 ? maxY * 1.1 : 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _profit(allTx) >= 0 ? DS.income : DS.expense,
              barWidth: 2.5,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (_profit(allTx) >= 0 ? DS.income : DS.expense)
                    .withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _profit(List<TxData> txs) {
    final inc = txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final exp = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    return inc - exp;
  }
}

// ── Pie Chart (income vs expense) ────────────────────────────────────────────

class _PieChart extends StatelessWidget {
  final double income, expense;
  const _PieChart({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    if (total == 0)
      return Center(
        child: Text('Belum ada data', style: Typo.sans(11, color: DS.faint)),
      );

    final incPct = income / total * 100;
    final expPct = expense / total * 100;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: income,
                  color: DS.income,
                  radius: 40,
                  title: Pct.formatValue(incPct, decimals: 0),
                  titleStyle: Typo.sans(
                    10,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
                PieChartSectionData(
                  value: expense,
                  color: DS.expense,
                  radius: 40,
                  title: Pct.formatValue(expPct, decimals: 0),
                  titleStyle: Typo.sans(
                    10,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LegDot(color: DS.income, label: 'Masuk ${Rupiah.compact(income)}'),
            const SizedBox(width: 12),
            LegDot(
              color: DS.expense,
              label: 'Keluar ${Rupiah.compact(expense)}',
            ),
          ],
        ),
      ],
    );
  }
}

// ── Pie Chart (expense categories) ───────────────────────────────────────────

class _ExpensePieChart extends StatelessWidget {
  final List<TxData> allTx;
  const _ExpensePieChart({required this.allTx});

  static const _catColors = [
    Color(0xFFD92B2B),
    Color(0xFFB07D2A),
    Color(0xFF185FA5),
    Color(0xFF1B8A4B),
    Color(0xFF8898AA),
  ];

  @override
  Widget build(BuildContext context) {
    final expenses = allTx.where((t) => !t.isIncome);
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total == 0)
      return Center(
        child: Text('Belum ada data', style: Typo.sans(11, color: DS.faint)),
      );

    final map = <String, double>{};
    for (final t in expenses) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    final sorted =
        (map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sorted.asMap().entries.map((e) {
                final pct = e.value.value / total * 100;
                return PieChartSectionData(
                  value: e.value.value,
                  color: _catColors[e.key % _catColors.length],
                  radius: 44,
                  title: pct >= 8 ? Pct.formatValue(pct, decimals: 0) : '',
                  titleStyle: Typo.sans(
                    9,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: sorted
              .asMap()
              .entries
              .map(
                (e) => LegDot(
                  color: _catColors[e.key % _catColors.length],
                  label: e.value.key,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: DS.hairline,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Typo.mono(13, color: color, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(label, style: Typo.sans(10, color: DS.faint)),
        ],
      ),
    ),
  );
}

class _BarChart extends StatelessWidget {
  final List<TxData> allTx;
  const _BarChart({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - 5 + i),
    );

    double maxVal = 1;
    final data = months.map((m) {
      final txs = allTx.where(
        (t) => t.date.year == m.year && t.date.month == m.month,
      );
      final inc = txs
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      final exp = txs
          .where((t) => !t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
      return (m, inc, exp);
    }).toList();

    const h = 90.0;
    return SizedBox(
      height: h + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final (m, inc, exp) = d;
          final hi = (inc / maxVal * h).clamp(2.0, h);
          final he = (exp / maxVal * h).clamp(2.0, h);
          final lbl = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agu',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ][m.month - 1];
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: hi,
                      decoration: BoxDecoration(
                        color: DS.income.withValues(alpha: 0.85),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 10,
                      height: he,
                      decoration: BoxDecoration(
                        color: DS.expense.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(lbl, style: Typo.sans(8, color: DS.faint)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<TxData> allTx;
  const _CategoryBreakdown({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final expenses = allTx.where((t) => !t.isIncome);
    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total == 0)
      return Text(
        'Tidak ada data pengeluaran',
        style: Typo.sans(12, color: DS.faint),
      );

    final map = <String, double>{};
    for (final t in expenses) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5);

    return Column(
      children: top.map((e) {
        final pct = e.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  e.key,
                  style: Typo.sans(11, color: DS.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: DS.hairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DS.expense,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Pct.formatValue(pct * 100, decimals: 0),
                style: Typo.mono(
                  11,
                  color: DS.expense,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FrequentList extends StatelessWidget {
  final List<TxData> allTx;
  const _FrequentList({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final map = <String, int>{};
    for (final t in allTx) {
      final key = t.description ?? t.category.name;
      map[key] = (map[key] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    if (top.isEmpty)
      return Text('Belum ada data', style: Typo.sans(12, color: DS.faint));

    return Column(
      children: top.asMap().entries.map((e) {
        final tx = allTx.firstWhere(
          (t) => (t.description ?? t.category.name) == e.value.key,
          orElse: () => allTx.first,
        );
        final amtTotal = allTx
            .where((t) => (t.description ?? t.category.name) == e.value.key)
            .fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
        return Column(
          children: [
            if (e.key > 0) Divider(height: 0.5, color: DS.hairline),
            // Ringkasan per keterangan, bukan satu transaksi — tidak punya detail.
            TxListTile(
              tx: tx.copyWith(amount: amtTotal.abs()),
              interactive: false,
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bergaya pil — menggantikan TabBar bergaris bawah, mengikuti mockup.
// ─────────────────────────────────────────────────────────────────────────────
