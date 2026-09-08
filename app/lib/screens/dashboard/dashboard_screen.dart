// lib/screens/dashboard/dashboard_screen.dart
//
// Dashboard hasil redesain — artboard 1b di Catatin.dc.html.
//
// Pergeseran intinya: layar tidak lagi membuka dengan tiga KPI setara, tapi
// dengan SATU angka — kewajiban pajak berikutnya. KPI turun jadi pendukung.
//
// Nominal kewajiban dihitung lewat `calculatePPhFinal()` dari
// core/services/simulator_service.dart, bukan rumus baru di layar ini. Model
// TaxDeadline tidak menyimpan nominal, jadi nilainya diturunkan dari omzet
// bulan berjalan. Begitu endpoint agregasi backend (Minggu 2) siap, ganti
// sumbernya di satu tempat saja: getter `_obligationAmount`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/services/simulator_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common/ds_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;

  MonthlySummary? _summary;
  List<RecentTx> _recentTx = const [];
  List<TaxDeadline> _deadlines = const [];
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        DashboardService.getSummary(),
        DashboardService.getRecentTransactions(limit: 3),
        DashboardService.getDeadlines(limit: 3),
      ]);
      final name = await StorageService.getUserName();

      if (!mounted) return;
      setState(() {
        _summary = results[0] as MonthlySummary;
        _recentTx = results[1] as List<RecentTx>;
        _deadlines = results[2] as List<TaxDeadline>;
        _name = (name ?? '').trim().split(' ').first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
    }
  }

  /// PPh Final masa berjalan, dihitung dari omzet bulan ini.
  double get _obligationAmount =>
      calculatePPhFinal(_summary?.income ?? 0).pajakBulanan;

  TaxDeadline? get _next => _deadlines.isEmpty ? null : _deadlines.first;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _greetingLine =>
      '$_greeting, ${_name.isEmpty ? 'Anda' : _name}.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            if (_loading) return const _DashboardSkeleton();
            if (_error != null) {
              return _DashboardError(message: _error!, onRetry: _load);
            }
            return RefreshIndicator(
              onRefresh: _load,
              color: DS.brand,
              child: bp.isExpanded ? _wide(bp) : _narrow(bp),
            );
          },
        ),
      ),
    );
  }

  // ── Susunan sempit (ponsel & tablet) ──────────────────────────────────────

  Widget _narrow(Breakpoint bp) {
    final pad = Bp.pagePadding(bp);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 32 + Bp.bottomInset(bp)),
      children: [
        _Header(greeting: _greetingLine, compact: true),
        const SizedBox(height: 32),
        _NextObligation(
          amount: _obligationAmount,
          deadline: _next,
          income: _summary?.income ?? 0,
          compact: true,
          onMarkPaid: _markPaid,
          onDetails: _openSimulator,
        ),
        const SizedBox(height: 34),
        if (_deadlines.length > 1) ...[
          DsSection(
            label: 'Setelah itu',
            child: Column(
              children: [
                for (var i = 1; i < _deadlines.length; i++)
                  DsListRow(
                    title: _deadlines[i].label,
                    subtitle: Tanggal.long(_deadlines[i].deadline),
                    trailing: _followUpAmount(i),
                    trailingStyle: i == 1
                        ? T.mono(14, color: DS.muted)
                        : T.sans(13, color: DS.faint),
                    showDivider: i < _deadlines.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
        ],
        DsSection(
          label: 'Bulan ini',
          action: _TextLink('Semua transaksi', onTap: _openAccounting),
          child: _MonthTotals(summary: _summary, compact: true),
        ),
        const SizedBox(height: 26),
        DsSection(
          label: 'Omzet tahun ini',
          child: _PkpProgress(summary: _summary),
        ),
        const SizedBox(height: 26),
        DsSection(
          label: 'Terakhir dicatat',
          child: _RecentList(items: _recentTx, onTap: _openTx),
        ),
      ],
    );
  }

  // ── Susunan lebar (web desktop) ───────────────────────────────────────────

  Widget _wide(Breakpoint bp) {
    final pad = Bp.pagePadding(bp);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Bp.contentMax),
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, 34, pad, 40),
          children: [
            _Header(greeting: _greetingLine, compact: false),
            const SizedBox(height: 38),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _wideMain()),
                const SizedBox(width: Space.x7),
                SizedBox(
                  width: 288,
                  child: Container(
                    padding: const EdgeInsets.only(left: 30),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: DS.hairline)),
                    ),
                    child: _wideAside(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wideMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NextObligation(
          amount: _obligationAmount,
          deadline: _next,
          income: _summary?.income ?? 0,
          compact: false,
          onMarkPaid: _markPaid,
          onDetails: _openSimulator,
        ),
        const SizedBox(height: 40),
        if (_deadlines.isNotEmpty)
          _Timeline(deadlines: _deadlines, amount: _obligationAmount),
        const SizedBox(height: Space.x7),
        DsSection(
          label: 'Bulan ini',
          action: _TextLink('Semua transaksi', onTap: _openAccounting),
          child: _MonthTotals(summary: _summary, compact: false),
        ),
      ],
    );
  }

  Widget _wideAside() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DsLabel('Omzet tahun ini'),
        const SizedBox(height: 12),
        _PkpProgress(summary: _summary),
        const SizedBox(height: 34),
        const DsLabel('Terakhir dicatat'),
        const SizedBox(height: 8),
        _RecentList(items: _recentTx, onTap: _openTx),
        const SizedBox(height: 34),
        const DsLabel('Cepat'),
        const SizedBox(height: 10),
        _TextLink('Catat transaksi baru', onTap: _openNewTx, block: true),
        _TextLink('Hitung pajak saya', onTap: _openSimulator, block: true),
      ],
    );
  }

  /// Tenggat kedua memakai estimasi dari omzet berjalan; sisanya belum bisa
  /// dihitung tanpa data periode berikutnya.
  String _followUpAmount(int index) => index == 1
      ? '≈ ${Rupiah.format(_obligationAmount)}'
      : 'Belum dihitung';

  void _openTx(RecentTx tx) => context.go('/accounting/${tx.id}');
  void _openAccounting() => context.go(AppRoutes.accounting);
  void _openSimulator() => context.go(AppRoutes.simulator);
  void _openNewTx() => context.go(AppRoutes.newTx);

  void _markPaid() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Penandaan pembayaran menunggu dukungan backend.'),
        backgroundColor: DS.invSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Bagian-bagian ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.compact});

  final String greeting;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsLabel(Tanggal.long(DateTime.now()), size: compact ? 10.5 : 11),
              const SizedBox(height: 8),
              Text(greeting, style: T.serif(compact ? 25 : 34, spacing: -0.2)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          badge: true,
          tooltip: 'Notifikasi',
          onTap: () => context.go(AppRoutes.notifications),
        ),
      ],
    );
  }
}

class _NextObligation extends StatelessWidget {
  const _NextObligation({
    required this.amount,
    required this.deadline,
    required this.income,
    required this.compact,
    required this.onMarkPaid,
    required this.onDetails,
  });

  final double amount;
  final TaxDeadline? deadline;
  final double income;
  final bool compact;
  final VoidCallback onMarkPaid;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final d = deadline;
    if (d == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsLabel('Kewajiban berikutnya'),
          const SizedBox(height: 14),
          Text('Tidak ada tenggat terdekat',
              style: T.serif(compact ? 28 : 38)),
          const SizedBox(height: 12),
          Text('Semua kewajiban pajak Anda sudah tercatat aman.',
              style: T.sans(15, color: DS.body)),
        ],
      );
    }

    final days = d.daysRemaining;
    final pillText = days < 0
        ? 'Terlambat ${days.abs()} hari'
        : days == 0
            ? 'Jatuh tempo hari ini'
            : '$days hari lagi${compact ? ' · ${Tanggal.short(d.deadline)}' : ''}';
    final amountText = Rupiah.format(amount);

    final headline = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(amountText,
                    style: T.serif(44, height: 1, spacing: -1)),
              ),
              const SizedBox(height: 14),
              DsStatusPill(text: pillText),
            ],
          )
        : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(amountText, style: T.serif(60, height: 1, spacing: -1.5)),
              DsStatusPill(text: pillText),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DsLabel('Kewajiban berikutnya'),
        SizedBox(height: compact ? 12 : 14),
        Semantics(
          label: 'Kewajiban berikutnya $amountText, $pillText',
          child: ExcludeSemantics(child: headline),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: compact ? double.infinity : 560),
          child: Text(
            compact
                ? '${d.label}, dari omzet ${Rupiah.format(income)} × ${Pct.format(AppConstants.pphFinalRate)}.'
                : '${d.label} — jatuh tempo ${Tanggal.long(d.deadline)}. '
                    'Dihitung dari omzet ${Rupiah.format(income)} dengan tarif '
                    '${Pct.format(AppConstants.pphFinalRate)} (PP 23/2018).',
            style: T.sans(compact ? 15.5 : 16, color: DS.body, height: 1.55),
          ),
        ),
        SizedBox(height: compact ? 20 : 22),
        if (compact)
          DsButton(
            label: 'Tandai sudah dibayar',
            onPressed: onMarkPaid,
            expand: true,
            minHeight: 50,
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DsButton(label: 'Tandai sudah dibayar', onPressed: onMarkPaid),
              DsButton(
                label: 'Lihat rinciannya',
                onPressed: onDetails,
                kind: DsButtonKind.outlined,
              ),
            ],
          ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.deadlines, required this.amount});

  final List<TaxDeadline> deadlines;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 6,
          child: Container(height: 1, color: DS.hairline),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < deadlines.length; i++) ...[
              Expanded(
                child: DsTimelineNode(
                  date: Tanggal.long(deadlines[i].deadline),
                  title: deadlines[i].label,
                  amount: switch (i) {
                    0 => Rupiah.format(amount),
                    1 => '≈ ${Rupiah.format(amount)}',
                    _ => 'Belum dihitung',
                  },
                  active: i == 0,
                ),
              ),
              if (i < deadlines.length - 1) const SizedBox(width: 28),
            ],
          ],
        ),
      ],
    );
  }
}

class _MonthTotals extends StatelessWidget {
  const _MonthTotals({required this.summary, required this.compact});

  final MonthlySummary? summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final items = <(String, double, Color)>[
      ('Pemasukan', s?.income ?? 0, DS.ink),
      ('Pengeluaran', s?.expense ?? 0, DS.ink),
      ('Laba', s?.profit ?? 0, DS.income),
    ];

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value, color) in items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: T.sans(12.5, color: DS.muted, height: 1.3)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Rupiah.plain(value),
                          style: T.mono(17, color: color)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 22),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(left: BorderSide(color: DS.hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(items[i].$1, style: T.sans(13, color: DS.muted)),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(Rupiah.format(items[i].$2),
                        style: T.mono(20, color: items[i].$3)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PkpProgress extends StatelessWidget {
  const _PkpProgress({required this.summary});

  final MonthlySummary? summary;

  @override
  Widget build(BuildContext context) {
    final ytd = summary?.ytdOmzet ?? 0;
    final ratio = (ytd / AppConstants.pkpThreshold).clamp(0.0, 1.0);
    final pctText = Pct.formatValue(ratio * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Rupiah.format(ytd), style: T.mono(21)),
        const SizedBox(height: 14),
        DsProgressBar(
          value: ratio,
          semanticLabel: 'Omzet tahun ini terhadap ambang PKP',
        ),
        const SizedBox(height: 10),
        Text(
          ratio >= 0.8
              ? '$pctText dari batas PKP Rp 4,8 M. Omzet Anda mendekati ambang — siapkan rencana PKP.'
              : '$pctText dari batas PKP Rp 4,8 M. Anda masih aman di skema UMKM 0,5%.',
          style: T.sans(13, color: DS.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items, required this.onTap});

  final List<RecentTx> items;
  final void Function(RecentTx) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('Belum ada transaksi bulan ini.',
          style: T.sans(14, color: DS.muted));
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _recentRow(items[i], showDivider: i < items.length - 1),
      ],
    );
  }

  Widget _recentRow(RecentTx tx, {required bool showDivider}) {
    final isIncome = tx.type == 'INCOME';
    final title = (tx.description?.isNotEmpty ?? false)
        ? tx.description!
        : tx.categoryName;
    return DsListRow(
      title: title,
      trailing: '${isIncome ? '+' : '−'}${Rupiah.plain(tx.amount)}',
      trailingStyle:
          T.mono(13.5, color: isIncome ? DS.income : DS.muted),
      showDivider: showDivider,
      onTap: () => onTap(tx),
    );
  }
}

// ── Elemen kecil ─────────────────────────────────────────────────────────────

class _TextLink extends StatelessWidget {
  const _TextLink(this.label, {required this.onTap, this.block = false});

  final String label;
  final VoidCallback onTap;
  final bool block;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: block ? double.infinity : null,
          constraints: BoxConstraints(minHeight: block ? 44 : 0),
          padding: EdgeInsets.symmetric(vertical: block ? 11 : 2),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: T.sans(block ? 14.5 : 13.5,
                weight: FontWeight.w500, color: DS.link),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DS.surface,
              shape: BoxShape.circle,
              border: Border.all(color: DS.hairline),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: DS.body),
                if (badge)
                  Positioned(
                    top: 9,
                    right: 11,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DS.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: DS.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: DS.hairline,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(140, 12),
          bar(220, 30),
          const SizedBox(height: 26),
          bar(120, 12),
          bar(260, 44),
          const SizedBox(height: 20),
          bar(double.infinity, 50),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 34, color: DS.faint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: T.sans(15, color: DS.body)),
            const SizedBox(height: 20),
            DsButton(label: 'Coba lagi', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
