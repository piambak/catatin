// lib/screens/accounting/calendar_view.dart
//
// Tab Kalender beserta grid dan filternya.
//
// Dipecah dari accounting_screen.dart (2.451 baris) untuk PRD R-7 / issue #52.
// Pemindahan murni: tidak ada perilaku yang diubah. Hanya delapan kelas yang
// naik jadi publik, yaitu yang dipakai lintas berkas.

import 'package:flutter/material.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/accounting/tx_list_tile.dart';
import 'accounting_shared.dart';

class AccountingCalendarTab extends StatefulWidget {
  final List<TxData> allTx;
  final bool loading;
  final DateTime cursor;
  final ValueChanged<DateTime> onShift;

  const AccountingCalendarTab({
    required this.allTx,
    required this.loading,
    required this.cursor,
    required this.onShift,
  });

  @override
  State<AccountingCalendarTab> createState() => _AccountingCalendarTabState();
}

class _AccountingCalendarTabState extends State<AccountingCalendarTab> {
  bool _showIncome = true;
  bool _showExpense = true;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) {
        final wide = box.maxWidth > 680;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left sidebar (wide only) ─────────────────────
            if (wide)
              SizedBox(
                width: 240,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 6, 20),
                  child: Column(
                    children: [
                      _MiniCalendar(
                        cursor: widget.cursor,
                        allTx: widget.allTx,
                        onMonth: widget.onShift,
                      ),
                      const SizedBox(height: 14),
                      _FilterCard(
                        showIncome: _showIncome,
                        showExpense: _showExpense,
                        onIncomeToggle: (v) => setState(() => _showIncome = v),
                        onExpenseToggle: (v) =>
                            setState(() => _showExpense = v),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Main calendar ────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Month nav
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        NavBtn(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => widget.onShift(
                            DateTime(
                              widget.cursor.year,
                              widget.cursor.month - 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_months[widget.cursor.month]} ${widget.cursor.year}',
                          style: Typo.sans(14, weight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        NavBtn(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => widget.onShift(
                            DateTime(
                              widget.cursor.year,
                              widget.cursor.month + 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Today button
                        GestureDetector(
                          onTap: () => widget.onShift(
                            DateTime(DateTime.now().year, DateTime.now().month),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: DS.hairline,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: DS.hairline, width: .5),
                            ),
                            child: Text(
                              'Hari Ini',
                              style: Typo.sans(11, weight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Legend
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LegDot(color: DS.income, label: 'Masuk'),
                            const SizedBox(width: 10),
                            LegDot(color: DS.expense, label: 'Keluar'),
                            const SizedBox(width: 10),
                            LegDot(color: DS.brand, label: 'Keduanya'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Day labels
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 8),
                    child: Row(
                      children:
                          ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: Typo.sans(
                                        9,
                                        color: DS.faint,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Calendar grid — fills remaining height
                  Expanded(
                    child: _FullCalGrid(
                      cursor: widget.cursor,
                      allTx: widget.allTx,
                      showIncome: _showIncome,
                      showExpense: _showExpense,
                      padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 8),
                      onDayTap: (day, txs) =>
                          _showDayDetail(context, widget.cursor, day, txs),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDayDetail(
    BuildContext ctx,
    DateTime month,
    int day,
    List<TxData> txs,
  ) {
    final date = DateTime(month.year, month.month, day);
    final income = txs
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DS.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(Tanggal.long(date), style: Typo.serif(15)),
                      ),
                      Text(
                        '${txs.length} transaksi',
                        style: Typo.sans(12, color: DS.faint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CalStat(label: 'Masuk', value: income, color: DS.income),
                      const SizedBox(width: 8),
                      _CalStat(
                        label: 'Keluar',
                        value: expense,
                        color: DS.expense,
                      ),
                      const SizedBox(width: 8),
                      _CalStat(
                        label: 'Net',
                        value: income - expense,
                        color: income >= expense ? DS.income : DS.expense,
                      ),
                    ],
                  ),
                  Divider(height: 20, color: DS.hairline),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: txs.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: .5, color: DS.hairline),
                      itemBuilder: (_, i) => TxListTile(tx: txs[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Full calendar grid (fills parent, prev/next month days fill edges) ────────

class _FullCalGrid extends StatefulWidget {
  final DateTime cursor;
  final List<TxData> allTx;
  final bool showIncome, showExpense;
  final EdgeInsets padding;
  final void Function(int day, List<TxData> txs) onDayTap;

  const _FullCalGrid({
    required this.cursor,
    required this.allTx,
    required this.showIncome,
    required this.showExpense,
    required this.padding,
    required this.onDayTap,
  });

  @override
  State<_FullCalGrid> createState() => _FullCalGridState();
}

class _FullCalGridState extends State<_FullCalGrid> {
  int? _hovered;

  int _daysIn(int y, int m) => DateTime(y, m + 1, 0).day;
  int _startWd(int y, int m) {
    final d = DateTime(y, m, 1).weekday;
    return d == 7 ? 0 : d;
  }

  // Build a map: each cell index → (day, month, year, List<TxData>)
  List<({int day, int month, int year, bool isCurrent})> _cells() {
    final cy = widget.cursor.year;
    final cm = widget.cursor.month;
    final start = _startWd(cy, cm);
    final dim = _daysIn(cy, cm);
    final cells = <({int day, int month, int year, bool isCurrent})>[];

    // Prev month fill
    final prevM = cm == 1 ? 12 : cm - 1;
    final prevY = cm == 1 ? cy - 1 : cy;
    final prevDim = _daysIn(prevY, prevM);
    for (int i = 0; i < start; i++) {
      cells.add((
        day: prevDim - start + i + 1,
        month: prevM,
        year: prevY,
        isCurrent: false,
      ));
    }
    // Current month
    for (int d = 1; d <= dim; d++) {
      cells.add((day: d, month: cm, year: cy, isCurrent: true));
    }
    // Next month fill to complete 42 cells
    final nextM = cm == 12 ? 1 : cm + 1;
    final nextY = cm == 12 ? cy + 1 : cy;
    int nd = 1;
    while (cells.length < 42) {
      cells.add((day: nd++, month: nextM, year: nextY, isCurrent: false));
    }
    return cells;
  }

  Map<String, List<TxData>> _txMap() {
    final map = <String, List<TxData>>{};
    for (final tx in widget.allTx) {
      if (!widget.showIncome && tx.isIncome) continue;
      if (!widget.showExpense && !tx.isIncome) continue;
      final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _cells();
    final txMap = _txMap();
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (_, box) {
        final rows = 6;
        final cellH = (box.maxHeight / rows).clamp(40.0, 120.0);
        final fontSize = (cellH * 0.22).clamp(10.0, 16.0);

        return Padding(
          padding: widget.padding,
          child: Column(
            children: List.generate(
              rows,
              (row) => Expanded(
                child: Row(
                  children: List.generate(7, (col) {
                    final i = row * 7 + col;
                    final c = cells[i];
                    final key = '${c.year}-${c.month}-${c.day}';
                    final txs = txMap[key] ?? [];
                    final hasInc = txs.any((t) => t.isIncome);
                    final hasExp = txs.any((t) => !t.isIncome);
                    final isToday =
                        c.day == today.day &&
                        c.month == today.month &&
                        c.year == today.year;
                    final isHovered =
                        _hovered == i && txs.isNotEmpty && c.isCurrent;

                    // Border between cells
                    final border = Border(
                      right: col < 6
                          ? BorderSide(color: DS.hairline, width: .5)
                          : BorderSide.none,
                      bottom: row < 5
                          ? BorderSide(color: DS.hairline, width: .5)
                          : BorderSide.none,
                    );

                    Color? bg;
                    Color numClr;
                    if (!c.isCurrent) {
                      numClr = DS.border;
                    } else if (isToday) {
                      numClr = DS.accent;
                    } else {
                      numClr = DS.ink;
                    }

                    if (txs.isNotEmpty && c.isCurrent) {
                      if (hasInc && hasExp)
                        bg = DS.brand.withValues(alpha: .10);
                      else if (hasInc)
                        bg = DS.income.withValues(alpha: 0.12);
                      else
                        bg = DS.expense.withValues(alpha: 0.12);
                    }
                    if (isHovered) bg = DS.brand.withValues(alpha: .18);

                    final inc = txs
                        .where((t) => t.isIncome)
                        .fold(0.0, (s, t) => s + t.amount);
                    final exp = txs
                        .where((t) => !t.isIncome)
                        .fold(0.0, (s, t) => s + t.amount);
                    final net = inc - exp;
                    final tip = txs.isNotEmpty
                        ? '${net >= 0 ? "+" : "−"}${Rupiah.compact(net.abs())}'
                        : '';

                    return Expanded(
                      child: MouseRegion(
                        onEnter: (_) {
                          if (txs.isNotEmpty && c.isCurrent)
                            setState(() => _hovered = i);
                        },
                        onExit: (_) => setState(() => _hovered = null),
                        cursor: txs.isNotEmpty && c.isCurrent
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: Tooltip(
                          message: c.isCurrent && txs.isNotEmpty ? tip : '',
                          preferBelow: false,
                          textStyle: Typo.sans(11, color: Colors.white),
                          decoration: BoxDecoration(
                            color: DS.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: GestureDetector(
                            onTap: c.isCurrent && txs.isNotEmpty
                                ? () => widget.onDayTap(c.day, txs)
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              decoration: BoxDecoration(
                                color: bg,
                                border: border,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day number
                                  Container(
                                    width: fontSize * 1.7,
                                    height: fontSize * 1.7,
                                    decoration: isToday
                                        ? BoxDecoration(
                                            color: DS.accent,
                                            shape: BoxShape.circle,
                                          )
                                        : null,
                                    child: Center(
                                      child: Text(
                                        '${c.day}',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: isToday
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: isToday
                                              ? Colors.white
                                              : numClr,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Dot indicators
                                  if (txs.isNotEmpty &&
                                      c.isCurrent &&
                                      cellH >= 52)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (hasInc) _dot(DS.income),
                                          if (hasExp) _dot(DS.expense),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dot(Color c) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsets.only(right: 2),
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

// ── Mini calendar (left sidebar) ──────────────────────────────────────────────

class _MiniCalendar extends StatelessWidget {
  final DateTime cursor;
  final List<TxData> allTx;
  final ValueChanged<DateTime> onMonth;

  const _MiniCalendar({
    required this.cursor,
    required this.allTx,
    required this.onMonth,
  });

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    final daysWithTx = <int>{};
    for (final tx in allTx) {
      if (tx.date.year == cursor.year && tx.date.month == cursor.month) {
        daysWithTx.add(tx.date.day);
      }
    }
    final dim = DateTime(cursor.year, cursor.month + 1, 0).day;
    final startWd = () {
      final d = DateTime(cursor.year, cursor.month, 1).weekday;
      return d == 7 ? 0 : d;
    }();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DS.hairline, width: .5),
      ),
      child: Column(
        children: [
          // Mini month nav
          Row(
            children: [
              GestureDetector(
                onTap: () => onMonth(DateTime(cursor.year, cursor.month - 1)),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 16,
                  color: DS.faint,
                ),
              ),
              Expanded(
                child: Text(
                  '${_months[cursor.month]} ${cursor.year}',
                  textAlign: TextAlign.center,
                  style: Typo.sans(11, weight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => onMonth(DateTime(cursor.year, cursor.month + 1)),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: DS.faint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Day labels
          Row(
            children: ['M', 'S', 'S', 'R', 'K', 'J', 'S']
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: Typo.sans(8, color: DS.faint),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 3),
          // Mini grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 22,
              mainAxisSpacing: 1,
            ),
            itemCount: 42,
            itemBuilder: (_, i) {
              final day = i - startWd + 1;
              if (day < 1 || day > dim) return const SizedBox.shrink();
              final hasTx = daysWithTx.contains(day);
              final isToday =
                  day == today.day &&
                  cursor.month == today.month &&
                  cursor.year == today.year;
              return Center(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isToday ? DS.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: Typo.sans(
                          8,
                          color: isToday ? Colors.white : DS.muted,
                        ),
                      ),
                      if (hasTx && !isToday)
                        Positioned(
                          bottom: 1,
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: DS.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Filter card (left sidebar) ────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final bool showIncome, showExpense;
  final ValueChanged<bool> onIncomeToggle, onExpenseToggle;

  const _FilterCard({
    required this.showIncome,
    required this.showExpense,
    required this.onIncomeToggle,
    required this.onExpenseToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DS.hairline, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter', style: Typo.sans(12, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          _FilterRow(
            label: 'Pemasukan',
            color: DS.income,
            value: showIncome,
            onToggle: onIncomeToggle,
          ),
          const SizedBox(height: 6),
          _FilterRow(
            label: 'Pengeluaran',
            color: DS.expense,
            value: showExpense,
            onToggle: onExpenseToggle,
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _FilterRow({
    required this.label,
    required this.color,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onToggle(!value),
    child: Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: value ? color : Colors.transparent,
            border: Border.all(color: value ? color : DS.border, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: value
              ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Typo.sans(
            11,
            color: value ? DS.ink : DS.faint,
            weight: value ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value ? 0.3 : 0.1),
            border: Border.all(color: value ? color : DS.border),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

class _CalStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _CalStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: DS.hairline,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Typo.sans(10, color: DS.faint)),
          const SizedBox(height: 2),
          Text(
            Rupiah.compact(value.abs()),
            style: Typo.mono(12, color: color, weight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTHLY TAB
// ─────────────────────────────────────────────────────────────────────────────
