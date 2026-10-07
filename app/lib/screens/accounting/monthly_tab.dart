// lib/screens/accounting/monthly_tab.dart
//
// Tab Bulanan.
//
// Dipecah dari accounting_screen.dart (2.451 baris) untuk PRD R-7 / issue #52.
// Pemindahan murni: tidak ada perilaku yang diubah. Hanya delapan kelas yang
// naik jadi publik, yaitu yang dipakai lintas berkas.

import 'package:flutter/material.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import 'accounting_shared.dart';

class MonthlyTab extends StatefulWidget {
  final List<TxData> allTx;
  final bool loading;
  final int year;
  final ValueChanged<int> onShift;

  const MonthlyTab({
    required this.allTx,
    required this.loading,
    required this.year,
    required this.onShift,
  });

  @override
  State<MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<MonthlyTab> {
  final Set<int> _expanded = {};

  static const _months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<TxData> _txMonth(int m) => widget.allTx
      .where((t) => t.date.year == widget.year && t.date.month == m)
      .toList();

  List<TxData> _txWeek(int m, int week) {
    // week 1=days1-7, 2=days8-14, 3=days15-21, 4=days22+
    final txs = _txMonth(m);
    return txs.where((t) {
      final d = t.date.day;
      if (week == 1) return d <= 7;
      if (week == 2) return d >= 8 && d <= 14;
      if (week == 3) return d >= 15 && d <= 21;
      return d >= 22;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final months =
        List.generate(12, (i) => i + 1)
            .where((m) => _txMonth(m).isNotEmpty || m <= DateTime.now().month)
            .toList()
          ..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        YearNav(year: widget.year, onShift: widget.onShift),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: months.map((m) {
              final txs = _txMonth(m);
              final income = txs
                  .where((t) => t.isIncome)
                  .fold(0.0, (s, t) => s + t.amount);
              final expense = txs
                  .where((t) => !t.isIncome)
                  .fold(0.0, (s, t) => s + t.amount);
              final isOpen = _expanded.contains(m);

              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => isOpen ? _expanded.remove(m) : _expanded.add(m),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: isOpen ? 0 : 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(10),
                          bottom: Radius.circular(isOpen ? 0 : 10),
                        ),
                        border: Border.all(color: DS.hairline, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: DS.hairline,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _months[m].substring(0, 3),
                                style: Typo.sans(11, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _months[m],
                              style: Typo.sans(13, weight: FontWeight.w500),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${Rupiah.compact(income)}',
                                style: Typo.mono(
                                  11,
                                  color: DS.income,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '−${Rupiah.compact(expense)}',
                                style: Typo.mono(
                                  11,
                                  color: DS.expense,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: DS.faint,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: DS.hairline,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                        border: Border.all(color: DS.hairline, width: 0.5),
                      ),
                      child: Column(
                        children: List.generate(4, (wi) {
                          final weekTxs = _txWeek(m, wi + 1);
                          final wInc = weekTxs
                              .where((t) => t.isIncome)
                              .fold(0.0, (s, t) => s + t.amount);
                          final wExp = weekTxs
                              .where((t) => !t.isIncome)
                              .fold(0.0, (s, t) => s + t.amount);
                          final labels = ['1–7', '8–14', '15–21', '22+'];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Minggu ${wi + 1}  (${labels[wi]})',
                                  style: Typo.sans(11, color: DS.muted),
                                ),
                                const Spacer(),
                                Text(
                                  '+${Rupiah.compact(wInc)}',
                                  style: Typo.mono(
                                    10,
                                    color: DS.income,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '−${Rupiah.compact(wExp)}',
                                  style: Typo.mono(
                                    10,
                                    color: DS.expense,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOTAL TAB
// ─────────────────────────────────────────────────────────────────────────────
