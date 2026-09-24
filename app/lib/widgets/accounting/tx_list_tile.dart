// lib/widgets/accounting/tx_list_tile.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/accounting_service.dart';
import './tx_add_sheet.dart';

// ── Transaction List Tile ─────────────────────────────────────────────────────

class TxListTile extends StatefulWidget {
  final TxData tx;
  final VoidCallback? onTap;

  const TxListTile({super.key, required this.tx, this.onTap});

  @override
  State<TxListTile> createState() => _TxListTileState();
}

class _TxListTileState extends State<TxListTile> {
  bool _hovered = false;

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _TxDetailContent(tx: widget.tx),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
          ? AppColors.brand.withValues(alpha: 0.04)
          : Colors.transparent,
        child: InkWell(
          onTap: () => _showDetail(context),
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              // Icon
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: tx.category.flutterColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(child: Text(tx.category.icon,
                  style: const TextStyle(fontSize: 17))),
              ),
              const SizedBox(width: 11),

              // Name + meta
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description ?? tx.category.name,
                    style: AppTextStyles.body(13, weight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Tanggal.short(tx.date)} · ${tx.category.name}',
                    style: AppTextStyles.body(11, color: AppColors.stone400),
                  ),
                ],
              )),

              // Amount
              Text(
                '${tx.isIncome ? '+' : '−'}${Rupiah.format(tx.amount)}',
                style: AppTextStyles.mono(13,
                  color: tx.isIncome ? AppColors.income : AppColors.expense,
                  weight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                size: 16,
                color: _hovered ? AppColors.brand : AppColors.stone300),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Detail Content ──────────────────────────────────────────────

class _TxDetailContent extends StatelessWidget {
  final TxData tx;
  const _TxDetailContent({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: tx.category.flutterColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(tx.category.icon,
              style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.description ?? tx.category.name,
                style: AppTextStyles.display(15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(tx.category.name,
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

        // Detail rows
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.stone200, width: .5)),
          child: Column(children: [
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: Tanggal.long(tx.date)),
            Divider(height: .5, indent: 42, color: AppColors.stone200),
            _DetailRow(
              icon: tx.isIncome
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
              label: 'Jenis',
              value: tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
              valueColor: tx.isIncome ? AppColors.income : AppColors.expense),
            Divider(height: .5, indent: 42, color: AppColors.stone200),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: tx.category.name),
            Divider(height: .5, indent: 42, color: AppColors.stone200),
            _DetailRow(
              icon: Icons.payment_outlined,
              label: 'Metode Bayar',
              value: _payLabel(tx.paymentMethod)),
            if (tx.receiptNote != null) ...[
              Divider(height: .5, indent: 42, color: AppColors.stone200),
              _DetailRow(
                icon: Icons.receipt_outlined,
                label: 'Catatan',
                value: tx.receiptNote!),
            ],
          ]),
        ),

        // Tax relevance badge
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: tx.category.taxRelevant
              ? AppColors.incomeLight
              : AppColors.stone100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tx.category.taxRelevant
                ? AppColors.incomeBorder
                : AppColors.stone200,
              width: .5)),
          child: Row(children: [
            Icon(
              tx.category.taxRelevant
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
              size: 15,
              color: tx.category.taxRelevant
                ? AppColors.income : AppColors.stone400),
            const SizedBox(width: 8),
            Expanded(child: Text(
              tx.category.taxRelevant
                ? 'Transaksi ini relevan untuk pelaporan pajak'
                : 'Transaksi ini tidak mempengaruhi pelaporan pajak',
              style: AppTextStyles.body(11,
                color: tx.category.taxRelevant
                  ? AppColors.income : AppColors.stone500))),
          ]),
        ),

        const SizedBox(height: 16),
        // Edit + Close buttons
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () {
              // NavigatorState diambil SEBELUM pop. Sesudah pop, `context`
              // milik route yang sudah dilepas, dan memakainya di dalam
              // microtask berarti menyentuh widget mati. NavigatorState
              // tetap hidup selama Navigator-nya ada. (T-7)
              final navigator = Navigator.of(context);
              navigator.pop();
              // Jeda singkat supaya dialog pertama benar-benar tertutup.
              Future.microtask(() => _openEdit(navigator, tx));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: BorderSide(color: AppColors.brand),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
            child: Text('Edit',
              style: AppTextStyles.body(13, weight: FontWeight.w500)),
          )),
          const SizedBox(width: 10),
          Expanded(child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.stone500,
              padding: const EdgeInsets.symmetric(vertical: 12)),
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
                    child: TxEditSheet(tx: tx),
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

  /// Menerima [NavigatorState], bukan [BuildContext], supaya pemanggilnya
  /// tidak perlu menyimpan context lintas async gap. (T-7)
  void _openEdit(NavigatorState navigator, TxData tx) {
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TxEditSheet(tx: tx),
        ),
      ),
    );
  }

  String _payLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':     return 'Tunai';
      case 'TRANSFER': return 'Transfer Bank';
      case 'QRIS':     return 'QRIS';
      case 'KARTU_DEBIT':
      case 'DEBIT':    return 'Kartu Debit'; // DEBIT: nilai lama lembar tambah transaksi
      case 'KARTU_KREDIT': return 'Kartu Kredit';
      case 'COD':      return 'COD';
      case 'OTHER':    return 'Lainnya';
      default:         return method;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon, required this.label,
    required this.value, this.valueColor,
  });

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