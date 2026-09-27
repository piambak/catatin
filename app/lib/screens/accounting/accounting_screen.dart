// lib/screens/accounting/accounting_screen.dart
//
// Layar Pencatatan: scaffold, state, dan tab bar. Isi tiap tab ada di berkasnya sendiri.
//
// Dipecah dari accounting_screen.dart (2.451 baris) untuk PRD R-7 / issue #52.
// Pemindahan murni: tidak ada perilaku yang diubah. Hanya delapan kelas yang
// naik jadi publik, yaitu yang dipakai lintas berkas.

import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/accounting/tx_add_sheet.dart';
import '../../widgets/common/app_widgets.dart';
import 'calendar_view.dart';
import 'daily_tab.dart';
import 'monthly_tab.dart';
import 'total_tab.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Shared data
  List<TxData> _allTx = [];
  bool _loading = true;
  String? _error;

  // Date cursors
  late DateTime _dailyCursor;
  late DateTime _calCursor;
  late int _monthlyYear;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _dailyCursor = DateTime(now.year, now.month);
    _calCursor = DateTime(now.year, now.month);
    _monthlyYear = now.year;
    _loadAll();
    // Layar ini tetap hidup di IndexedStack; muat ulang setiap transaksi
    // dibuat, diubah, atau dihapus di mana pun.
    AccountingService.changes.addListener(_loadAll);
  }

  @override
  void dispose() {
    AccountingService.changes.removeListener(_loadAll);
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final txs = await AccountingService.getTransactions();
      if (mounted) setState(() => _allTx = txs);
    } on ApiException catch (e) {
      // T-22: dulu ini hanya SnackBar sekilas. Akibatnya layar menampilkan
      // daftar KOSONG yang tidak bisa dibedakan dari "Anda memang belum punya
      // transaksi" — dan tidak ada cara mencoba lagi selain menutup aplikasi.
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddSheet() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TxAddSheet(
            // Daftar dimuat ulang lewat AccountingService.changes. Transaksi
            // yang dikirim balik lembar ini ber-id sementara — kalau disisipkan
            // langsung, detailnya tidak bisa dibuka dari backend.
            onSaved: (_) {},
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = Bp.of(context);
    final pad = Bp.pagePadding(bp);

    return Scaffold(
      backgroundColor: DS.surface,
      body: Column(
        children: [
          // ── Kepala tetap ─────────────────────────────────────
          Material(
            color: DS.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 20, pad - 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pencatatan',
                          style: Typo.serif(bp.isExpanded ? 34 : 25),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ViewTabs(controller: _tabCtrl, pad: pad),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────
          // Galat diperiksa SEBELUM loading: kalau tidak, skeleton menutupi
          // keadaan galat dan pengguna tidak pernah melihatnya.
          if (_error != null)
            Expanded(
              child: ErrorState(message: _error!, onRetry: _loadAll),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  DailyTab(
                    allTx: _allTx,
                    loading: _loading,
                    cursor: _dailyCursor,
                    onShift: (d) => setState(() => _dailyCursor = d),
                    onRefresh: _loadAll,
                  ),
                  AccountingCalendarTab(
                    allTx: _allTx,
                    loading: _loading,
                    cursor: _calCursor,
                    onShift: (d) => setState(() => _calCursor = d),
                  ),
                  MonthlyTab(
                    allTx: _allTx,
                    loading: _loading,
                    year: _monthlyYear,
                    onShift: (y) => setState(() => _monthlyYear = y),
                  ),
                  TotalTab(allTx: _allTx, loading: _loading),
                ],
              ),
            ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────
      // Digeser ke atas supaya tidak tertimpa pil navigasi mengambang.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: Bp.bottomInset(bp)),
        child: FloatingActionButton(
          onPressed: _showAddSheet,
          backgroundColor: DS.brand,
          foregroundColor: DS.onBrand,
          elevation: 2,
          tooltip: 'Catat transaksi',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month Nav Bar
// ─────────────────────────────────────────────────────────────────────────────

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.controller, required this.pad});

  final TabController controller;
  final double pad;

  static const _labels = ['Harian', 'Kalender', 'Bulanan', 'Total'];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Tanpa lebar penuh, Container ini menyusut selebar isinya dan Column
      // induk (crossAxisAlignment default = center) menaruhnya di tengah,
      // sehingga tab tidak sebaris dengan judul di atasnya.
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DS.hairline)),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ViewTabPill(
                    label: _labels[i],
                    selected: controller.index == i,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewTabPill extends StatelessWidget {
  const _ViewTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? DS.brandMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Typo.sans(
                13.5,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? DS.brandInk : DS.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
