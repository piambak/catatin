// lib/screens/accounting/tx_detail_screen.dart
//
// Detail transaksi — digayakan ulang mengikuti mockup Claude Design.
//
// Nominal jadi satu angka besar di puncak layar, bukan kartu berwarna; sisanya
// turun jadi daftar baris berpemisah tipis. Konfirmasi hapus tetap inline
// (bukan dialog) supaya alur ini tidak menambah lapisan modal — R-5.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/accounting_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common/ds_widgets.dart';

const _paymentLabels = {
  'CASH': 'Tunai',
  'TRANSFER': 'Transfer bank',
  'QRIS': 'QRIS',
  'KARTU_DEBIT': 'Kartu debit',
  'KARTU_KREDIT': 'Kartu kredit',
  'COD': 'COD',
  'OTHER': 'Lainnya',
};

class TxDetailScreen extends StatefulWidget {
  final String txId;
  const TxDetailScreen({super.key, required this.txId});

  @override
  State<TxDetailScreen> createState() => _TxDetailScreenState();
}

class _TxDetailScreenState extends State<TxDetailScreen> {
  TxData? _tx;
  bool _loading = true;
  bool _deleting = false;
  bool _confirmDelete = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tx = await AccountingService.getTransaction(widget.txId);
    if (!mounted) return;
    setState(() {
      _tx = tx;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await AccountingService.deleteTransaction(widget.txId);
    if (!mounted) return;
    context.go('/accounting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            final pad = Bp.pagePadding(bp);
            return Column(
              children: [
                _header(pad, bp),
                Expanded(child: _body(pad)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(double pad, Breakpoint bp) => Padding(
        padding: EdgeInsets.fromLTRB(pad - 8, 12, pad, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_rounded, color: DS.body),
              tooltip: 'Kembali',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text('Detail transaksi',
                  style: T.serif(bp.isExpanded ? 30 : 24)),
            ),
          ],
        ),
      );

  Widget _body(double pad) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: DS.brand));
    }

    final tx = _tx;
    if (tx == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 34, color: DS.faint),
              const SizedBox(height: 16),
              Text('Transaksi tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: T.sans(15, color: DS.body)),
              const SizedBox(height: 20),
              DsButton(label: 'Coba lagi', onPressed: _load),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(tx),
              const SizedBox(height: 32),
              _details(tx),
              const SizedBox(height: 30),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nominal ────────────────────────────────────────────────────────────────

  Widget _hero(TxData tx) {
    final accent = tx.isIncome ? DS.income : DS.expense;
    final sign = tx.isIncome ? '+' : '−';
    final amountText = '$sign${Rupiah.format(tx.amount)}';
    final typeLabel = tx.isIncome ? 'Pemasukan' : 'Pengeluaran';

    return Semantics(
      label: '$typeLabel $amountText',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsLabel(typeLabel),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(amountText,
                  style: T.serif(42, color: accent, height: 1, spacing: -1)),
            ),
            if (tx.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(tx.description!,
                  style: T.sans(16, color: DS.body, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Rincian ────────────────────────────────────────────────────────────────

  Widget _details(TxData tx) {
    final tags = [
      if (tx.category.taxRelevant) 'Pajak',
      if (tx.category.isCogs) 'HPP',
    ];

    return DsSection(
      label: 'Rincian',
      child: Column(
        children: [
          DsListRow(
            title: 'Kategori',
            trailing:
                '${tx.category.icon} ${tx.category.name}${tags.isEmpty ? '' : ' · ${tags.join(' · ')}'}',
            trailingStyle: T.sans(14, color: DS.ink, weight: FontWeight.w500),
          ),
          DsListRow(
            title: 'Tanggal',
            trailing: Tanggal.long(tx.date),
            trailingStyle: T.sans(14, color: DS.ink),
          ),
          DsListRow(
            title: 'Metode pembayaran',
            trailing:
                _paymentLabels[tx.paymentMethod] ?? tx.paymentMethod,
            trailingStyle: T.sans(14, color: DS.ink),
          ),
          if (tx.receiptNote?.isNotEmpty ?? false)
            DsListRow(
              title: 'Catatan nota',
              trailing: tx.receiptNote!,
              trailingStyle: T.sans(14, color: DS.ink),
            ),
          DsListRow(
            title: 'Dicatat',
            trailing: Tanggal.long(tx.createdAt),
            trailingStyle: T.sans(14, color: DS.muted),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  // ── Aksi ───────────────────────────────────────────────────────────────────

  Widget _actions() {
    if (_confirmDelete) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DS.expense.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: DS.expense.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: DS.expense, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Hapus transaksi ini?',
                      style: T.sans(14.5,
                          weight: FontWeight.w600, color: DS.expense)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Tindakan ini tidak bisa dibatalkan.',
                style: T.sans(13, color: DS.body)),
            const SizedBox(height: 14),
            Row(
              children: [
                DsButton(
                  label: 'Batal',
                  onPressed: _deleting
                      ? null
                      : () => setState(() => _confirmDelete = false),
                  kind: DsButtonKind.outlined,
                  minHeight: 46,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DsButton(
                    label: _deleting ? 'Menghapus…' : 'Ya, hapus',
                    onPressed: _deleting ? null : _delete,
                    expand: true,
                    minHeight: 46,
                    background: DS.expense,
                    foreground: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: DsButton(
            label: 'Sunting',
            // Penyuntingan belum tersambung — sama seperti sebelum redesain.
            onPressed: null,
            kind: DsButtonKind.outlined,
            expand: true,
            minHeight: 48,
          ),
        ),
        const SizedBox(width: 10),
        DsButton(
          label: 'Hapus',
          onPressed: () => setState(() => _confirmDelete = true),
          kind: DsButtonKind.outlined,
          minHeight: 48,
          foreground: DS.expense,
        ),
      ],
    );
  }
}
