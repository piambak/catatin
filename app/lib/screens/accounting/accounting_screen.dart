// lib/screens/accounting/accounting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/accounting/tx_add_sheet.dart';
import '../../widgets/accounting/month_picker.dart' show TxListTile;
import '../../widgets/common/app_widgets.dart';
import 'package:fl_chart/fl_chart.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Shared data
  List<TxData> _allTx   = [];
  bool         _loading = true;

  // Date cursors
  late DateTime _dailyCursor;
  late DateTime _calCursor;
  late int      _monthlyYear;

  @override
  void initState() {
    super.initState();
    _tabCtrl     = TabController(length: 4, vsync: this);
    final now    = DateTime.now();
    _dailyCursor = DateTime(now.year, now.month);
    _calCursor   = DateTime(now.year, now.month);
    _monthlyYear = now.year;
    _loadAll();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final txs = await AccountingService.getTransactions();
    if (mounted) setState(() { _allTx = txs; _loading = false; });
  }

  void _showAddSheet() {
    showDialog(
      context:          context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TxAddSheet(
            onSaved: (tx) {
              setState(() => _allTx = [tx, ..._allTx]);
            },
          ),
        ),
      ),
    );
  }

  void _showFavorites() {
    final favs = _allTx.where((t) => t.isFavorite).toList();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize:     0.9,
        minChildSize:     0.35,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16))),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.stone200,
                borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(children: [
                Icon(Icons.star_rounded, size: 18, color: AppColors.brand),
                const SizedBox(width: 8),
                Text('Transaksi Favorit',
                  style: AppTextStyles.display(15)),
                const Spacer(),
                Text('${favs.length} transaksi',
                  style: AppTextStyles.body(12, color: AppColors.stone400)),
              ])),
            Divider(height: 0.5, color: AppColors.stone200),
            if (favs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: EmptyState(
                  icon: Icons.star_border_rounded,
                  title: 'Belum ada favorit',
                  subtitle: 'Tandai transaksi sebagai favorit\ndari halaman detail transaksi'))
            else
              Expanded(child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favs.length,
                separatorBuilder: (_, __) =>
                  Divider(height: 0.5, color: AppColors.stone200),
                itemBuilder: (_, i) => TxListTile(
                  tx:    favs[i],
                  onTap: () {},
                ),
              )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        // ── Sticky header ────────────────────────────────────
        Material(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pembukuan',
                      style: AppTextStyles.display(17, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor)),
                    Text('Catat dan pantau transaksi',
                      style: AppTextStyles.body(11, color: AppColors.stone500)),
                  ],
                )),
                IconButton(
                  icon: Icon(Icons.star_border_rounded,
                    color: Theme.of(context).appBarTheme.foregroundColor),
                  tooltip: 'Transaksi Favorit',
                  onPressed: _showFavorites,
                ),
              ]),
            ),
            const SizedBox(height: 4),
            TabBar(
              controller: _tabCtrl,
              labelStyle: AppTextStyles.body(12, weight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.body(12),
              labelColor: Theme.of(context).appBarTheme.foregroundColor,
              unselectedLabelColor: AppColors.stone400,
              indicatorColor: AppColors.brand,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.stone200,
              tabs: const [
                Tab(text: 'Harian'),
                Tab(text: 'Kalender'),
                Tab(text: 'Bulanan'),
                Tab(text: 'Total'),
              ],
            ),
          ]),
        ),

        // ── Tab content ──────────────────────────────────────
        Expanded(child: TabBarView(
          controller: _tabCtrl,
          children: [
            _DailyTab(
              allTx:   _allTx,
              loading: _loading,
              cursor:  _dailyCursor,
              onShift: (d) => setState(() => _dailyCursor = d),
              onRefresh: _loadAll,
            ),
            _CalendarTab(
              allTx:   _allTx,
              loading: _loading,
              cursor:  _calCursor,
              onShift: (d) => setState(() => _calCursor = d),
            ),
            _MonthlyTab(
              allTx:   _allTx,
              loading: _loading,
              year:    _monthlyYear,
              onShift: (y) => setState(() => _monthlyYear = y),
            ),
            _TotalTab(
              allTx:   _allTx,
              loading: _loading,
            ),
          ],
        )),
      ]),

      // ── FAB ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed:       _showAddSheet,
        backgroundColor: AppColors.brand,
        tooltip:         'Catat Transaksi',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month Nav Bar
// ─────────────────────────────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  final DateTime cursor;
  final ValueChanged<DateTime> onShift;

  const _MonthNav({required this.cursor, required this.onShift});

  static const _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [
      _NavBtn(
        icon: Icons.chevron_left_rounded,
        onTap: () => onShift(DateTime(
          cursor.year, cursor.month - 1)),
      ),
      const SizedBox(width: 10),
      Text(
        '${_months[cursor.month]} ${cursor.year}',
        style: AppTextStyles.body(13, weight: FontWeight.w500)),
      const SizedBox(width: 10),
      _NavBtn(
        icon: Icons.chevron_right_rounded,
        onTap: () => onShift(DateTime(
          cursor.year, cursor.month + 1)),
      ),
    ]),
  );
}

class _YearNav extends StatelessWidget {
  final int year;
  final ValueChanged<int> onShift;

  const _YearNav({required this.year, required this.onShift});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [
      _NavBtn(
        icon: Icons.chevron_left_rounded,
        onTap: () => onShift(year - 1)),
      const SizedBox(width: 10),
      Text('$year', style: AppTextStyles.body(13, weight: FontWeight.w500)),
      const SizedBox(width: 10),
      _NavBtn(
        icon: Icons.chevron_right_rounded,
        onTap: () => onShift(year + 1)),
    ]),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.stone200, width: 0.5)),
      child: Icon(icon, size: 17, color: AppColors.stone500),
    ),
  ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  final List<TxData> allTx;
  final bool         loading;
  final DateTime     cursor;
  final ValueChanged<DateTime> onShift;
  final Future<void> Function() onRefresh;

  const _DailyTab({
    required this.allTx, required this.loading,
    required this.cursor, required this.onShift,
    required this.onRefresh,
  });

  List<TxData> get _monthTx => allTx
    .where((t) => t.date.year == cursor.year && t.date.month == cursor.month)
    .toList()..sort((a, b) => b.date.compareTo(a.date));

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

  static const _wds = ['','Sen','Sel','Rab','Kam','Jum','Sab','Min'];
  static const _mons = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  String _wd(int w)  => _wds[w];
  String _mon(int m) => _mons[m];

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _MonthNav(cursor: cursor, onShift: onShift),
          if (loading)
            _shimmer()
          else if (_monthTx.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Ketuk + untuk mencatat transaksi baru'))
          else
            ..._grouped.entries.map((e) => _DayGroup(
              dateLabel: e.key,
              txs:       e.value,
            )),
        ],
      ),
    );
  }

  Widget _shimmer() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: List.generate(4, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: const [
        ShimmerBox(width: 36, height: 36, radius: 9),
        SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 140, height: 12),
            SizedBox(height: 5),
            ShimmerBox(width: 90, height: 10),
          ])),
        ShimmerBox(width: 80, height: 13),
      ]),
    ))),
  );
}

class _DayGroup extends StatelessWidget {
  final String       dateLabel;
  final List<TxData> txs;
  const _DayGroup({required this.dateLabel, required this.txs});

  double get _net => txs.fold(0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));

  @override
  Widget build(BuildContext context) {
    final netColor = _net >= 0 ? AppColors.income : AppColors.expense;
    final netStr   = (_net >= 0 ? '+' : '−') +
        Rupiah.compact(_net.abs());

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
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(7)),
            child: Row(children: [
              Expanded(child: Text(dateLabel,
                style: AppTextStyles.body(11, weight: FontWeight.w600))),
              Text(netStr, style: AppTextStyles.mono(11,
                color: netColor, weight: FontWeight.w600)),
            ]),
          ),
          // Transactions
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.stone200, width: 0.5)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) =>
                Divider(height: 0.5, indent: 56, color: AppColors.stone100),
              itemBuilder: (_, i) => TxListTile(
                tx: txs[i], onTap: () {}),
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

class _CalendarTab extends StatefulWidget {
  final List<TxData> allTx;
  final bool         loading;
  final DateTime     cursor;
  final ValueChanged<DateTime> onShift;

  const _CalendarTab({
    required this.allTx, required this.loading,
    required this.cursor, required this.onShift,
  });

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  bool _showIncome  = true;
  bool _showExpense = true;

  static const _months = [
    '','Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final wide = box.maxWidth > 680;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left sidebar (wide only) ─────────────────────
          if (wide) SizedBox(
            width: 240,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 6, 20),
              child: Column(children: [
                _MiniCalendar(
                  cursor:  widget.cursor,
                  allTx:   widget.allTx,
                  onMonth: widget.onShift,
                ),
                const SizedBox(height: 14),
                _FilterCard(
                  showIncome:  _showIncome,
                  showExpense: _showExpense,
                  onIncomeToggle:  (v) => setState(() => _showIncome  = v),
                  onExpenseToggle: (v) => setState(() => _showExpense = v),
                ),
              ]),
            ),
          ),

          // ── Main calendar ────────────────────────────────
          Expanded(
            child: Column(children: [
              // Month nav
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  _NavBtn(icon: Icons.chevron_left_rounded,
                    onTap: () => widget.onShift(DateTime(
                      widget.cursor.year, widget.cursor.month - 1))),
                  const SizedBox(width: 10),
                  Text('${_months[widget.cursor.month]} ${widget.cursor.year}',
                    style: AppTextStyles.body(14, weight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  _NavBtn(icon: Icons.chevron_right_rounded,
                    onTap: () => widget.onShift(DateTime(
                      widget.cursor.year, widget.cursor.month + 1))),
                  const SizedBox(width: 10),
                  // Today button
                  GestureDetector(
                    onTap: () => widget.onShift(
                      DateTime(DateTime.now().year, DateTime.now().month)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.stone100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.stone200, width: .5)),
                      child: Text('Hari Ini',
                        style: AppTextStyles.body(11,
                          weight: FontWeight.w500)),
                    ),
                  ),
                  const Spacer(),
                  // Legend
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    _LegDot(color: AppColors.income,  label: 'Masuk'),
                    const SizedBox(width: 10),
                    _LegDot(color: AppColors.expense, label: 'Keluar'),
                    const SizedBox(width: 10),
                    _LegDot(color: AppColors.brand,   label: 'Keduanya'),
                  ]),
                ]),
              ),
              // Day labels
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 8),
                child: Row(
                  children: ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
                    .map((d) => Expanded(child: Center(child: Text(d,
                      style: AppTextStyles.body(9,
                        color: AppColors.stone400,
                        weight: FontWeight.w500)))))
                    .toList(),
                ),
              ),
              const SizedBox(height: 3),
              // Calendar grid — fills remaining height
              Expanded(child: _FullCalGrid(
                cursor:      widget.cursor,
                allTx:       widget.allTx,
                showIncome:  _showIncome,
                showExpense: _showExpense,
                padding:     EdgeInsets.symmetric(horizontal: wide ? 16 : 8),
                onDayTap:    (day, txs) =>
                  _showDayDetail(context, widget.cursor, day, txs),
              )),
            ]),
          ),
        ],
      );
    });
  }

  void _showDayDetail(BuildContext ctx, DateTime month,
      int day, List<TxData> txs) {
    final date    = DateTime(month.year, month.month, day);
    final income  = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expense = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

    showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:36,height:4,
            decoration:BoxDecoration(color:AppColors.stone200,
              borderRadius:BorderRadius.circular(2))),
          const SizedBox(height:12),
          Row(children: [
            Expanded(child: Text(Tanggal.long(date),
              style: AppTextStyles.display(15))),
            Text('${txs.length} transaksi',
              style: AppTextStyles.body(12, color: AppColors.stone400)),
          ]),
          const SizedBox(height:8),
          Row(children: [
            _CalStat(label:'Masuk',  value:income,  color:AppColors.income),
            const SizedBox(width:8),
            _CalStat(label:'Keluar', value:expense, color:AppColors.expense),
            const SizedBox(width:8),
            _CalStat(label:'Net',    value:income-expense,
              color: income>=expense ? AppColors.income : AppColors.expense),
          ]),
          Divider(height:20,color:AppColors.stone200),
          ConstrainedBox(
            constraints:const BoxConstraints(maxHeight:300),
            child: ListView.separated(
              shrinkWrap:true,
              itemCount:txs.length,
              separatorBuilder:(_,__)=>Divider(height:.5,color:AppColors.stone100),
              itemBuilder:(_,i)=>TxListTile(tx:txs[i],onTap:(){}),
            ),
          ),
        ])),
      )),
    ));
  }
}

// ── Full calendar grid (fills parent, prev/next month days fill edges) ────────

class _FullCalGrid extends StatefulWidget {
  final DateTime   cursor;
  final List<TxData> allTx;
  final bool showIncome, showExpense;
  final EdgeInsets padding;
  final void Function(int day, List<TxData> txs) onDayTap;

  const _FullCalGrid({
    required this.cursor, required this.allTx,
    required this.showIncome, required this.showExpense,
    required this.padding, required this.onDayTap,
  });

  @override
  State<_FullCalGrid> createState() => _FullCalGridState();
}

class _FullCalGridState extends State<_FullCalGrid> {
  int? _hovered;

  int  _daysIn(int y, int m) => DateTime(y, m + 1, 0).day;
  int  _startWd(int y, int m) {
    final d = DateTime(y, m, 1).weekday;
    return d == 7 ? 0 : d;
  }

  // Build a map: each cell index → (day, month, year, List<TxData>)
  List<({int day, int month, int year, bool isCurrent})> _cells() {
    final cy = widget.cursor.year;
    final cm = widget.cursor.month;
    final start = _startWd(cy, cm);
    final dim   = _daysIn(cy, cm);
    final cells = <({int day, int month, int year, bool isCurrent})>[];

    // Prev month fill
    final prevM = cm == 1 ? 12 : cm - 1;
    final prevY = cm == 1 ? cy - 1 : cy;
    final prevDim = _daysIn(prevY, prevM);
    for (int i = 0; i < start; i++) {
      cells.add((day: prevDim - start + i + 1, month: prevM, year: prevY, isCurrent: false));
    }
    // Current month
    for (int d = 1; d <= dim; d++) {
      cells.add((day: d, month: cm, year: cy, isCurrent: true));
    }
    // Next month fill to complete 42 cells
    final nextM = cm == 12 ? 1  : cm + 1;
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
      if (!widget.showIncome  &&  tx.isIncome) continue;
      if (!widget.showExpense && !tx.isIncome) continue;
      final key = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cells = _cells();
    final txMap  = _txMap();
    final today  = DateTime.now();

    return LayoutBuilder(builder: (_, box) {
      final rows   = 6;
      final cellH  = (box.maxHeight / rows).clamp(40.0, 120.0);
      final fontSize = (cellH * 0.22).clamp(10.0, 16.0);

      return Padding(
        padding: widget.padding,
        child: Column(children: List.generate(rows, (row) =>
          Expanded(child: Row(children: List.generate(7, (col) {
            final i = row * 7 + col;
            final c = cells[i];
            final key = '${c.year}-${c.month}-${c.day}';
            final txs = txMap[key] ?? [];
            final hasInc = txs.any((t) =>  t.isIncome);
            final hasExp = txs.any((t) => !t.isIncome);
            final isToday = c.day == today.day &&
                            c.month == today.month &&
                            c.year  == today.year;
            final isHovered = _hovered == i && txs.isNotEmpty && c.isCurrent;

            // Border between cells
            final border = Border(
              right:  col < 6 ? BorderSide(color: AppColors.stone200, width: .5) : BorderSide.none,
              bottom: row < 5 ? BorderSide(color: AppColors.stone200, width: .5) : BorderSide.none,
            );

            Color? bg;
            Color  numClr;
            if (!c.isCurrent) {
              numClr = AppColors.stone300;
            } else if (isToday) {
              numClr = AppColors.navy;
            } else {
              numClr = AppColors.stone700;
            }

            if (txs.isNotEmpty && c.isCurrent) {
              if (hasInc && hasExp)     bg = AppColors.brand.withOpacity(.10);
              else if (hasInc)          bg = AppColors.incomeLight;
              else                      bg = AppColors.expenseLight;
            }
            if (isHovered) bg = AppColors.brand.withOpacity(.18);

            final inc = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
            final exp = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
            final net = inc - exp;
            final tip = txs.isNotEmpty
              ? '${net >= 0 ? "+" : "−"}${Rupiah.compact(net.abs())}'
              : '';

            return Expanded(child: MouseRegion(
              onEnter: (_) { if (txs.isNotEmpty && c.isCurrent) setState(() => _hovered = i); },
              onExit:  (_) => setState(() => _hovered = null),
              cursor: txs.isNotEmpty && c.isCurrent
                ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: Tooltip(
                message: c.isCurrent && txs.isNotEmpty ? tip : '',
                preferBelow: false,
                textStyle: AppTextStyles.body(11, color: Colors.white),
                decoration: BoxDecoration(
                  color: AppColors.stone700,
                  borderRadius: BorderRadius.circular(6)),
                child: GestureDetector(
                  onTap: c.isCurrent && txs.isNotEmpty
                    ? () => widget.onDayTap(c.day, txs) : null,
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
                          decoration: isToday ? BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle) : null,
                          child: Center(child: Text('${c.day}',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday ? Colors.white : numClr))),
                        ),
                        // Dot indicators
                        if (txs.isNotEmpty && c.isCurrent && cellH >= 52)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (hasInc) _dot(AppColors.income),
                              if (hasExp) _dot(AppColors.expense),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
          }))),
        )),
      );
    });
  }

  Widget _dot(Color c) => Container(
    width: 5, height: 5,
    margin: const EdgeInsets.only(right: 2),
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

// ── Mini calendar (left sidebar) ──────────────────────────────────────────────

class _MiniCalendar extends StatelessWidget {
  final DateTime     cursor;
  final List<TxData> allTx;
  final ValueChanged<DateTime> onMonth;

  const _MiniCalendar({
    required this.cursor, required this.allTx, required this.onMonth});

  static const _months = [
    '','Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ];

  @override
  Widget build(BuildContext context) {
    final daysWithTx = <int>{};
    for (final tx in allTx) {
      if (tx.date.year == cursor.year && tx.date.month == cursor.month) {
        daysWithTx.add(tx.date.day);
      }
    }
    final dim    = DateTime(cursor.year, cursor.month + 1, 0).day;
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
        border: Border.all(color: AppColors.stone200, width: .5)),
      child: Column(children: [
        // Mini month nav
        Row(children: [
          GestureDetector(
            onTap: () => onMonth(DateTime(cursor.year, cursor.month - 1)),
            child: Icon(Icons.chevron_left_rounded,
              size: 16, color: AppColors.stone400)),
          Expanded(child: Text(
            '${_months[cursor.month]} ${cursor.year}',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(11, weight: FontWeight.w600))),
          GestureDetector(
            onTap: () => onMonth(DateTime(cursor.year, cursor.month + 1)),
            child: Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.stone400)),
        ]),
        const SizedBox(height: 6),
        // Day labels
        Row(children: ['M','S','S','R','K','J','S'].map((d) =>
          Expanded(child: Text(d, textAlign: TextAlign.center,
            style: AppTextStyles.body(8, color: AppColors.stone400)))
        ).toList()),
        const SizedBox(height: 3),
        // Mini grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisExtent: 22, mainAxisSpacing: 1),
          itemCount: 42,
          itemBuilder: (_, i) {
            final day = i - startWd + 1;
            if (day < 1 || day > dim) return const SizedBox.shrink();
            final hasTx  = daysWithTx.contains(day);
            final isToday = day == today.day &&
                cursor.month == today.month && cursor.year == today.year;
            return Center(child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: isToday ? AppColors.navy : Colors.transparent,
                shape: BoxShape.circle),
              child: Stack(alignment: Alignment.center, children: [
                Text('$day', style: AppTextStyles.body(8,
                  color: isToday ? Colors.white : AppColors.stone600)),
                if (hasTx && !isToday)
                  Positioned(bottom: 1, child: Container(
                    width: 3, height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.brand, shape: BoxShape.circle))),
              ]),
            ));
          },
        ),
      ]),
    );
  }
}

// ── Filter card (left sidebar) ────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final bool showIncome, showExpense;
  final ValueChanged<bool> onIncomeToggle, onExpenseToggle;

  const _FilterCard({
    required this.showIncome, required this.showExpense,
    required this.onIncomeToggle, required this.onExpenseToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stone200, width: .5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter', style: AppTextStyles.body(12, weight: FontWeight.w500)),
          const SizedBox(height: 8),
          _FilterRow(
            label: 'Pemasukan',
            color: AppColors.income,
            value: showIncome,
            onToggle: onIncomeToggle),
          const SizedBox(height: 6),
          _FilterRow(
            label: 'Pengeluaran',
            color: AppColors.expense,
            value: showExpense,
            onToggle: onExpenseToggle),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   value;
  final ValueChanged<bool> onToggle;

  const _FilterRow({
    required this.label, required this.color,
    required this.value, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onToggle(!value),
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: value ? color : Colors.transparent,
          border: Border.all(
            color: value ? color : AppColors.stone300, width: 1.5),
          borderRadius: BorderRadius.circular(3)),
        child: value
          ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
          : null),
      const SizedBox(width: 8),
      Text(label, style: AppTextStyles.body(11,
        color: value ? AppColors.stone700 : AppColors.stone400,
        weight: value ? FontWeight.w500 : FontWeight.w400)),
      const Spacer(),
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color.withOpacity(value ? 0.3 : 0.1),
          border: Border.all(color: value ? color : AppColors.stone300),
          borderRadius: BorderRadius.circular(2))),
    ]),
  );
}

class _LegDot extends StatelessWidget {
  final Color color; final String label;
  const _LegDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width:8,height:8,
        decoration:BoxDecoration(
          color:color.withOpacity(.3),
          border:Border.all(color:color,width:1),
          borderRadius:BorderRadius.circular(2))),
      const SizedBox(width:4),
      Text(label,style:AppTextStyles.body(10,color:AppColors.stone500)),
    ]);
}


class _CalStat extends StatelessWidget {
  final String label;
  final double value;
  final Color  color;
  const _CalStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.body(10, color: AppColors.stone400)),
        const SizedBox(height: 2),
        Text(Rupiah.compact(value.abs()),
          style: AppTextStyles.mono(12, color: color, weight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTHLY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyTab extends StatefulWidget {
  final List<TxData> allTx;
  final bool loading;
  final int  year;
  final ValueChanged<int> onShift;

  const _MonthlyTab({
    required this.allTx, required this.loading,
    required this.year,  required this.onShift,
  });

  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab> {
  final Set<int> _expanded = {};

  static const _months = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  List<TxData> _txMonth(int m) => widget.allTx.where(
    (t) => t.date.year == widget.year && t.date.month == m).toList();

  List<TxData> _txWeek(int m, int week) {
    // week 1=days1-7, 2=days8-14, 3=days15-21, 4=days22+
    final txs = _txMonth(m);
    return txs.where((t) {
      final d = t.date.day;
      if (week == 1) return d <= 7;
      if (week == 2) return d >= 8  && d <= 14;
      if (week == 3) return d >= 15 && d <= 21;
      return d >= 22;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1)
      .where((m) => _txMonth(m).isNotEmpty || m <= DateTime.now().month)
      .toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _YearNav(year: widget.year, onShift: widget.onShift),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: months.map((m) {
              final txs     = _txMonth(m);
              final income  = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
              final expense = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
              final isOpen  = _expanded.contains(m);

              return Column(children: [
                GestureDetector(
                  onTap: () => setState(() =>
                    isOpen ? _expanded.remove(m) : _expanded.add(m)),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: isOpen ? 0 : 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.vertical(
                        top:    const Radius.circular(10),
                        bottom: Radius.circular(isOpen ? 0 : 10)),
                      border: Border.all(color: AppColors.stone200, width: 0.5)),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.stone100,
                          borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(
                          _months[m].substring(0, 3),
                          style: AppTextStyles.body(11, weight: FontWeight.w600)))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_months[m],
                        style: AppTextStyles.body(13, weight: FontWeight.w500))),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('+${Rupiah.compact(income)}',
                          style: AppTextStyles.mono(11,
                            color: AppColors.income, weight: FontWeight.w600)),
                        Text('−${Rupiah.compact(expense)}',
                          style: AppTextStyles.mono(11,
                            color: AppColors.expense, weight: FontWeight.w600)),
                      ]),
                      const SizedBox(width: 8),
                      Icon(isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: AppColors.stone400),
                    ]),
                  ),
                ),
                if (isOpen)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.stone100,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10)),
                      border: Border.all(color: AppColors.stone200, width: 0.5)),
                    child: Column(
                      children: List.generate(4, (wi) {
                        final weekTxs = _txWeek(m, wi + 1);
                        final wInc    = weekTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
                        final wExp    = weekTxs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
                        final labels  = ['1–7', '8–14', '15–21', '22+'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                          child: Row(children: [
                            Text('Minggu ${wi + 1}  (${labels[wi]})',
                              style: AppTextStyles.body(11, color: AppColors.stone500)),
                            const Spacer(),
                            Text('+${Rupiah.compact(wInc)}',
                              style: AppTextStyles.mono(10,
                                color: AppColors.income, weight: FontWeight.w500)),
                            const SizedBox(width: 10),
                            Text('−${Rupiah.compact(wExp)}',
                              style: AppTextStyles.mono(10,
                                color: AppColors.expense, weight: FontWeight.w500)),
                          ]),
                        );
                      }),
                    ),
                  ),
              ]);
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

class _TotalTab extends StatelessWidget {
  final List<TxData> allTx;
  final bool         loading;

  const _TotalTab({required this.allTx, required this.loading});

  double get _totalIncome  => allTx.where((t) =>  t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _totalExpense => allTx.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
  double get _profit       => _totalIncome - _totalExpense;
  double get _margin       => _totalIncome > 0 ? _profit / _totalIncome * 100 : 0;

  // Average daily income (rough: assume 22 working days)
  double get _avgDaily => _totalIncome / 22;

  // Transaction counts
  int get _incomeCount  => allTx.where((t) =>  t.isIncome).length;
  int get _expenseCount => allTx.where((t) => !t.isIncome).length;
  double get _avgTxValue => allTx.isEmpty ? 0 : ((_totalIncome + _totalExpense) / allTx.length);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [

        // ── 4 KPI chips ───────────────────────────────────────
        Row(children: [
          _StatChip(label: 'Total Pemasukan',  value: Rupiah.compact(_totalIncome),  color: AppColors.income),
          const SizedBox(width: 8),
          _StatChip(label: 'Total Pengeluaran',value: Rupiah.compact(_totalExpense), color: AppColors.expense),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _StatChip(label: 'Laba Bersih', value: Rupiah.compact(_profit),
            color: _profit >= 0 ? const Color(0xFF185FA5) : AppColors.expense),
          const SizedBox(width: 8),
          _StatChip(label: 'Margin', value: '${_margin.toStringAsFixed(1)}%', color: AppColors.warning),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _StatChip(label: 'Rata-rata Harian', value: Rupiah.compact(_avgDaily), color: AppColors.stone500),
          const SizedBox(width: 8),
          _StatChip(label: 'Total Transaksi',  value: '${allTx.length} tx',    color: AppColors.stone500),
        ]),
        const SizedBox(height: 14),

        // ── Bar chart — income vs expense 6 months ────────────
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pemasukan vs Pengeluaran', style: AppTextStyles.display(13)),
            Text('6 bulan terakhir', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 14),
            _BarChart(allTx: allTx),
            const SizedBox(height: 8),
            Row(children: [
              _LegDot(color: AppColors.income,  label: 'Pemasukan'),
              const SizedBox(width: 12),
              _LegDot(color: AppColors.expense, label: 'Pengeluaran'),
            ]),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Line chart — cumulative laba ──────────────────────
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tren Laba Kumulatif', style: AppTextStyles.display(13)),
            Text('Akumulasi laba per bulan', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 14),
            _LineChart(allTx: allTx),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Pie chart — income vs expense composition ─────────
        LayoutBuilder(builder: (_, box) {
          final wide = box.maxWidth > 500;
          if (wide) {
            return Row(children: [
              Expanded(child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Komposisi Arus Kas', style: AppTextStyles.display(13)),
                  Text('Pemasukan vs Pengeluaran', style: AppTextStyles.body(10, color: AppColors.stone400)),
                  const SizedBox(height: 14),
                  _PieChart(income: _totalIncome, expense: _totalExpense),
                ]),
              )),
              const SizedBox(width: 10),
              Expanded(child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kategori Pengeluaran', style: AppTextStyles.display(13)),
                  Text('Top 5 terbesar', style: AppTextStyles.body(10, color: AppColors.stone400)),
                  const SizedBox(height: 14),
                  _ExpensePieChart(allTx: allTx),
                ]),
              )),
            ]);
          }
          return Column(children: [
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Komposisi Arus Kas', style: AppTextStyles.display(13)),
              Text('Pemasukan vs Pengeluaran', style: AppTextStyles.body(10, color: AppColors.stone400)),
              const SizedBox(height: 14),
              _PieChart(income: _totalIncome, expense: _totalExpense),
            ])),
            const SizedBox(height: 10),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kategori Pengeluaran', style: AppTextStyles.display(13)),
              Text('Top 5 terbesar', style: AppTextStyles.body(10, color: AppColors.stone400)),
              const SizedBox(height: 14),
              _ExpensePieChart(allTx: allTx),
            ])),
          ]);
        }),
        const SizedBox(height: 10),

        // ── Category breakdown (bar) ──────────────────────────
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rincian Pengeluaran', style: AppTextStyles.display(13)),
            const SizedBox(height: 10),
            _CategoryBreakdown(allTx: allTx),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Tx stats row ──────────────────────────────────────
        Row(children: [
          Expanded(child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Frekuensi Transaksi', style: AppTextStyles.display(13)),
              const SizedBox(height: 8),
              _StatsRow(icon: Icons.trending_up_rounded,
                label: 'Pemasukan', value: '$_incomeCount transaksi',
                color: AppColors.income),
              const SizedBox(height: 4),
              _StatsRow(icon: Icons.trending_down_rounded,
                label: 'Pengeluaran', value: '$_expenseCount transaksi',
                color: AppColors.expense),
              const SizedBox(height: 4),
              _StatsRow(icon: Icons.payments_outlined,
                label: 'Rata-rata nilai', value: Rupiah.compact(_avgTxValue),
                color: AppColors.stone500),
            ]),
          )),
        ]),
        const SizedBox(height: 10),

        // ── Frequent transactions ─────────────────────────────
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Transaksi Paling Sering', style: AppTextStyles.display(13)),
            Text('Berdasarkan frekuensi',
              style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 10),
            _FrequentList(allTx: allTx),
          ]),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color    color;
  const _StatsRow({required this.icon, required this.label,
    required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 8),
    Expanded(child: Text(label,
      style: AppTextStyles.body(11, color: AppColors.stone500))),
    Text(value, style: AppTextStyles.body(11, color: color, weight: FontWeight.w600)),
  ]);
}

// ── Line Chart (cumulative profit) ───────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<TxData> allTx;
  const _LineChart({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) =>
      DateTime(now.year, now.month - 5 + i));

    double cumulative = 0;
    final spots = months.asMap().entries.map((e) {
      final m = e.value;
      final txs = allTx.where((t) =>
        t.date.year == m.year && t.date.month == m.month);
      final inc = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final exp = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
      cumulative += (inc - exp);
      return FlSpot(e.key.toDouble(), cumulative / 1000000);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

    const labels = ['','Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final monthLabels = months.map((m) => labels[m.month]).toList();

    return SizedBox(
      height: 120,
      child: LineChart(LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY / 3).clamp(1, double.infinity) : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.stone200, strokeWidth: .5),
        ),
        titlesData: FlTitlesData(
          leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= monthLabels.length) return const SizedBox.shrink();
              return Text(monthLabels[i],
                style: AppTextStyles.body(8, color: AppColors.stone400));
            },
          )),
        ),
        borderData: FlBorderData(show: false),
        minY: minY < 0 ? minY * 1.1 : 0,
        maxY: maxY > 0 ? maxY * 1.1 : 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _profit(allTx) >= 0 ? AppColors.income : AppColors.expense,
            barWidth: 2.5,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (_profit(allTx) >= 0 ? AppColors.income : AppColors.expense)
                .withOpacity(0.08)),
          ),
        ],
      )),
    );
  }

  double _profit(List<TxData> txs) {
    final inc = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
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
    if (total == 0) return Center(child: Text('Belum ada data',
      style: AppTextStyles.body(11, color: AppColors.stone400)));

    final incPct = income / total * 100;
    final expPct = expense / total * 100;

    return Column(children: [
      SizedBox(
        height: 140,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          sections: [
            PieChartSectionData(
              value: income,
              color: AppColors.income,
              radius: 40,
              title: '${incPct.toStringAsFixed(0)}%',
              titleStyle: AppTextStyles.body(10,
                color: Colors.white, weight: FontWeight.w600),
            ),
            PieChartSectionData(
              value: expense,
              color: AppColors.expense,
              radius: 40,
              title: '${expPct.toStringAsFixed(0)}%',
              titleStyle: AppTextStyles.body(10,
                color: Colors.white, weight: FontWeight.w600),
            ),
          ],
        )),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _LegDot(color: AppColors.income,  label: 'Masuk ${Rupiah.compact(income)}'),
        const SizedBox(width: 12),
        _LegDot(color: AppColors.expense, label: 'Keluar ${Rupiah.compact(expense)}'),
      ]),
    ]);
  }
}

// ── Pie Chart (expense categories) ───────────────────────────────────────────

class _ExpensePieChart extends StatelessWidget {
  final List<TxData> allTx;
  const _ExpensePieChart({required this.allTx});

  static const _catColors = [
    Color(0xFFD92B2B), Color(0xFFB07D2A), Color(0xFF185FA5),
    Color(0xFF1B8A4B), Color(0xFF8898AA),
  ];

  @override
  Widget build(BuildContext context) {
    final expenses = allTx.where((t) => !t.isIncome);
    final total    = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total == 0) return Center(child: Text('Belum ada data',
      style: AppTextStyles.body(11, color: AppColors.stone400)));

    final map = <String, double>{};
    for (final t in expenses) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    final sorted = (map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .take(5).toList();

    return Column(children: [
      SizedBox(
        height: 140,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          sections: sorted.asMap().entries.map((e) {
            final pct = e.value.value / total * 100;
            return PieChartSectionData(
              value: e.value.value,
              color: _catColors[e.key % _catColors.length],
              radius: 44,
              title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
              titleStyle: AppTextStyles.body(9,
                color: Colors.white, weight: FontWeight.w600),
            );
          }).toList(),
        )),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 4,
        children: sorted.asMap().entries.map((e) =>
          _LegDot(
            color: _catColors[e.key % _catColors.length],
            label: e.value.key)).toList(),
      ),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(9)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTextStyles.mono(13, color: color, weight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.body(10, color: AppColors.stone400)),
      ]),
    ),
  );
}

class _BarChart extends StatelessWidget {
  final List<TxData> allTx;
  const _BarChart({required this.allTx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) =>
      DateTime(now.year, now.month - 5 + i));

    double maxVal = 1;
    final data = months.map((m) {
      final txs  = allTx.where((t) =>
        t.date.year == m.year && t.date.month == m.month);
      final inc  = txs.where((t) =>  t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final exp  = txs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
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
          final lbl = ['Jan','Feb','Mar','Apr','Mei','Jun',
            'Jul','Agu','Sep','Okt','Nov','Des'][m.month - 1];
          return Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 10, height: hi,
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.85),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)))),
                  const SizedBox(width: 2),
                  Container(width: 10, height: he,
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.75),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3)))),
                ],
              ),
              const SizedBox(height: 4),
              Text(lbl, style: AppTextStyles.body(8, color: AppColors.stone400)),
            ],
          ));
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
    final expenses  = allTx.where((t) => !t.isIncome);
    final total     = expenses.fold(0.0, (s, t) => s + t.amount);
    if (total == 0) return Text('Tidak ada data pengeluaran',
      style: AppTextStyles.body(12, color: AppColors.stone400));

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
          child: Row(children: [
            SizedBox(width: 90, child: Text(e.key,
              style: AppTextStyles.body(11, color: AppColors.stone500),
              overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Expanded(child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.stone200,
                borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.expense,
                    borderRadius: BorderRadius.circular(3))))),
            ),
            const SizedBox(width: 8),
            Text('${(pct * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.mono(11,
                color: AppColors.expense, weight: FontWeight.w600)),
          ]),
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

    if (top.isEmpty) return Text('Belum ada data',
      style: AppTextStyles.body(12, color: AppColors.stone400));

    return Column(
      children: top.asMap().entries.map((e) {
        final tx = allTx.firstWhere(
          (t) => (t.description ?? t.category.name) == e.value.key,
          orElse: () => allTx.first);
        final amtTotal = allTx
          .where((t) => (t.description ?? t.category.name) == e.value.key)
          .fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount));
        return Column(children: [
          if (e.key > 0) Divider(height: 0.5, color: AppColors.stone100),
          TxListTile(
            tx: tx.copyWith(amount: amtTotal.abs()),
            onTap: () {}),
        ]);
      }).toList(),
    );
  }
}