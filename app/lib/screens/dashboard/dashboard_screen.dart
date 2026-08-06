// lib/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accounting/tx_add_sheet.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/dashboard/kpi_card.dart';
import '../../widgets/dashboard/income_chart_card.dart';
import '../../widgets/dashboard/recent_transactions.dart';
import '../../widgets/dashboard/deadline_card.dart';
import '../../widgets/dashboard/tax_tips_card.dart';
import '../../widgets/dashboard/regulation_card.dart';
import '../../widgets/dashboard/cal_deadline_card.dart';
import '../../widgets/common/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State
  MonthlySummary? _summary;
  List<RecentTx>  _recentTx   = [];
  List<TaxDeadline> _deadlines = [];
  bool _loading = true;
  String? _error;
  String _userName = '';
  String? _businessName;

  // KPI history — ikut dimuat sekali bersama data dashboard lain
  List<KpiHistory> _incomeHistory  = [];
  List<KpiHistory> _expenseHistory = [];
  List<KpiHistory> _profitHistory  = [];
  List<KpiHistory> _ytdHistory     = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  List<KpiHistory> _toHistory(List<KpiPoint> points) =>
      points.map((p) => KpiHistory(month: p.month, value: p.value)).toList();

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final name     = await StorageService.getUserName();
      final bizId    = await StorageService.getBusinessId();

      final results = await Future.wait([
        DashboardService.getSummary(),
        DashboardService.getRecentTransactions(),
        DashboardService.getDeadlines(),
        DashboardService.getKpiHistory(KpiMetric.income),
        DashboardService.getKpiHistory(KpiMetric.expense),
        DashboardService.getKpiHistory(KpiMetric.profit),
        DashboardService.getKpiHistory(KpiMetric.ytd),
      ]);

      setState(() {
        _userName       = name ?? '';
        _businessName   = bizId != null ? 'Toko Anda' : null;
        _summary        = results[0] as MonthlySummary;
        _recentTx       = results[1] as List<RecentTx>;
        _deadlines      = results[2] as List<TaxDeadline>;
        _incomeHistory  = _toHistory(results[3] as List<KpiPoint>);
        _expenseHistory = _toHistory(results[4] as List<KpiPoint>);
        _profitHistory  = _toHistory(results[5] as List<KpiPoint>);
        _ytdHistory     = _toHistory(results[6] as List<KpiPoint>);
        _loading        = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat data.'; _loading = false; });
    }
  }

  String get _firstName =>
      _userName.isNotEmpty ? _userName.split(' ').first : 'Pengguna';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.brand,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────
            _buildAppBar(),

            // ── Body ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: _error != null
                  ? SliverFillRemaining(
                      child: ErrorState(
                        message: _error!,
                        onRetry: _loadAll,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        // KPI cards
                        KpiGrid(
                          income:    _summary?.income    ?? 0,
                          expense:   _summary?.expense   ?? 0,
                          profit:    _summary?.profit    ?? 0,
                          ytdOmzet:  _summary?.ytdOmzet  ?? 0,
                          isLoading: _loading,
                          incomeHistory:  _incomeHistory,
                          expenseHistory: _expenseHistory,
                          profitHistory:  _profitHistory,
                          ytdHistory:     _ytdHistory,
                        ),
                        const SizedBox(height: 14),

                        // Income vs Expense chart (replaces PKP bar)
                        IncomeChartCard(),
                        const SizedBox(height: 14),

                        // Recent transactions
                        RecentTransactionsList(
                          transactions: _recentTx,
                          isLoading:    _loading,
                          onViewAll:    () => context.go(AppRoutes.accounting),
                          onTxTap: (id) {
                            final tx = _recentTx.firstWhere(
                              (t) => t.id == id,
                              orElse: () => _recentTx.first);
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 40),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 440),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: _RecentTxDetail(tx: tx),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Bottom section — responsive 3-col grid ────────
                        LayoutBuilder(builder: (_, constraints) {
                          final wide = constraints.maxWidth > 700;
                          final medium = constraints.maxWidth > 480;

                          if (wide) {
                            // 3-col grid — fixed height so no IntrinsicHeight needed
                            return SizedBox(
                              height: 560,
                              child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Col 1+2: Tips/Actions row + Regulation row
                                Expanded(
                                  flex: 2,
                                  child: Column(children: [
                                    // Row 1: Tips | Actions — same height
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: TaxTipsCard()),
                                          const SizedBox(width: 10),
                                          Expanded(child: QuickActions(
                                            onNewTx: () => context.push(
                                                AppRoutes.newTx),
                                            onSimulator: () => context.go(
                                                AppRoutes.simulator),
                                            onLibrary: () => context.go(
                                                AppRoutes.library),
                                          )),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Row 2: Regulation fills remaining height
                                    Expanded(
                                      child: RegulationCard(
                                        onViewAll: () =>
                                            context.go(AppRoutes.library),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(width: 10),
                                // Col 3: Calendar + Deadline (spans both rows)
                                Expanded(
                                  child: CalDeadlineCard(
                                    deadlines:   _deadlines,
                                    isLoading:   _loading,
                                    isPkp:       false,
                                    hasEmployees:true,
                                    onViewAll:   () => context.go(
                                        AppRoutes.simulator),
                                  ),
                                ),
                              ],
                            ));
                          }

                          if (medium) {
                            // Medium: single column (same as mobile, avoids height issues)
                            return Column(children: [
                              TaxTipsCard(),
                              const SizedBox(height: 10),
                              QuickActions(
                                onNewTx: () => context.push(AppRoutes.newTx),
                                onSimulator: () => context.go(AppRoutes.simulator),
                                onLibrary: () => context.go(AppRoutes.library),
                              ),
                              const SizedBox(height: 10),
                              RegulationCard(
                                onViewAll: () => context.go(AppRoutes.library)),
                              const SizedBox(height: 10),
                              CalDeadlineCard(
                                deadlines: _deadlines,
                                isLoading: _loading,
                                onViewAll: () => context.go(AppRoutes.simulator),
                              ),
                            ]);
                          }

                          // Mobile: single column
                          return Column(children: [
                            TaxTipsCard(),
                            const SizedBox(height: 10),
                            QuickActions(
                              onNewTx: () => context.push(AppRoutes.newTx),
                              onSimulator: () => context.go(AppRoutes.simulator),
                              onLibrary: () => context.go(AppRoutes.library),
                            ),
                            const SizedBox(height: 10),
                            RegulationCard(
                              onViewAll: () => context.go(AppRoutes.library)),
                            const SizedBox(height: 10),
                            CalDeadlineCard(
                              deadlines: _deadlines,
                              isLoading: _loading,
                              onViewAll: () => context.go(AppRoutes.simulator),
                            ),
                          ]);
                        }),
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom SliverAppBar ────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 62,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: App name + welcome
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.display(18, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor),
                children: [
                  TextSpan(text: 'Catat'),
                  TextSpan(
                    text: 'in',
                    style: TextStyle(color: AppColors.brand),
                  ),
                ],
              ),
            ),
            Text(
              _businessName != null
                ? _businessName!
                : 'Selamat datang, $_firstName 👋',
              style: AppTextStyles.body(11, color: AppColors.stone400),
            ),
          ]),

          // Right: Notification bell only
          Stack(children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: () => context.push('/notifications'),
              tooltip: 'Notifikasi',
            ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).appBarTheme.backgroundColor!,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}


// ─── Recent Transaction Detail Dialog ────────────────────────────────────────

class _RecentTxDetail extends StatelessWidget {
  final RecentTx tx;
  const _RecentTxDetail({required this.tx});

  @override
  Widget build(BuildContext context) {
    final hex   = tx.categoryColor.replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(tx.categoryIcon ?? '💰',
              style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.description ?? tx.categoryName,
                style: AppTextStyles.display(15),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(tx.categoryName,
                style: AppTextStyles.body(11, color: AppColors.stone400)),
            ],
          )),
          Text(
            '${tx.isIncome ? '+' : '−'}${Rupiah.format(tx.amount)}',
            style: AppTextStyles.mono(16,
              color: tx.isIncome ? AppColors.income : AppColors.expense,
              weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),

        // Detail table
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.stone200, width: .5)),
          child: Column(children: [
            _Row(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: Tanggal.long(tx.date)),
            Divider(height: .5, indent: 42, color: AppColors.stone200),
            _Row(
              icon: tx.isIncome
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
              label: 'Jenis',
              value: tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
              valueColor: tx.isIncome ? AppColors.income : AppColors.expense),
            Divider(height: .5, indent: 42, color: AppColors.stone200),
            _Row(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: tx.categoryName),
          ]),
        ),

        const SizedBox(height: 16),
        // Action buttons
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.stone500,
              side: BorderSide(color: AppColors.stone200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9))),
            child: Text('Tutup',
              style: AppTextStyles.body(13, weight: FontWeight.w500)),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
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
                      onSaved: (_) {},
                      prefill: TxPrefill(
                        type:        tx.type,
                        amount:      tx.amount,
                        description: tx.description,
                        date:        tx.date,
                      ),
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9))),
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: Text('Edit',
              style: AppTextStyles.body(13, weight: FontWeight.w600)),
          )),
        ]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  final Color?   valueColor;

  const _Row({required this.icon, required this.label,
    required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.stone400),
      const SizedBox(width: 10),
      SizedBox(width: 80, child: Text(label,
        style: AppTextStyles.body(11, color: AppColors.stone400))),
      Expanded(child: Text(value,
        style: AppTextStyles.body(13,
          color: valueColor ?? AppColors.stone700,
          weight: FontWeight.w500),
        textAlign: TextAlign.end)),
    ]),
  );
}
