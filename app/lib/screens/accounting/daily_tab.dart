// lib/screens/accounting/daily_tab.dart
//
// Tab Harian.
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

class DailyTab extends StatelessWidget {
  final List<TxData> allTx;
  final bool loading;
  final DateTime cursor;
  final ValueChanged<DateTime> onShift;
  final Future<void> Function() onRefresh;

  const DailyTab({
    required this.allTx,
    required this.loading,
    required this.cursor,
    required this.onShift,
    required this.onRefresh,
  });

  List<TxData> get _monthTx =>
      allTx
          .where(
            (t) => t.date.year == cursor.year && t.date.month == cursor.month,
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Map<String, List<TxData>> get _grouped {
    final map = <String, List<TxData>>{};
    for (final tx in _monthTx) {
      final key = _dayKey(tx.date);
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  String _dayKey(DateTime d) =>
      '${_wd(d.weekday)}, ${d.day} ${_mon(d.month)} ${d.year}';

  static const _wds = ['', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _mons = [
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
  String _wd(int w) => _wds[w];
  String _mon(int m) => _mons[m];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: DS.brand,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          MonthNav(cursor: cursor, onShift: onShift),
          if (loading)
            _shimmer()
          else if (_monthTx.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Ketuk + untuk mencatat transaksi baru',
              ),
            )
          else
            ..._grouped.entries.map(
              (e) => _DayGroup(dateLabel: e.key, txs: e.value),
            ),
        ],
      ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: const [
              ShimmerBox(width: 36, height: 36, radius: 9),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 140, height: 12),
                    SizedBox(height: 5),
                    ShimmerBox(width: 90, height: 10),
                  ],
                ),
              ),
              ShimmerBox(width: 80, height: 13),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DayGroup extends StatelessWidget {
  final String dateLabel;
  final List<TxData> txs;
  const _DayGroup({required this.dateLabel, required this.txs});

  double get _net =>
      txs.fold(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

  @override
  Widget build(BuildContext context) {
    final netColor = _net >= 0 ? DS.income : DS.expense;
    final netStr = (_net >= 0 ? '+' : '−') + Rupiah.compact(_net.abs());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DS.hairline,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateLabel,
                    style: Typo.sans(11, weight: FontWeight.w600),
                  ),
                ),
                Text(
                  netStr,
                  style: Typo.mono(
                    11,
                    color: netColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Transactions
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DS.hairline, width: 0.5),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 0.5, indent: 56, color: DS.hairline),
              itemBuilder: (_, i) => TxListTile(tx: txs[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALENDAR TAB
// ─────────────────────────────────────────────────────────────────────────────
