// lib/screens/accounting/tx_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common/app_widgets.dart';

class TxDetailScreen extends StatefulWidget {
  final String txId;
  const TxDetailScreen({super.key, required this.txId});

  @override
  State<TxDetailScreen> createState() => _TxDetailScreenState();
}

class _TxDetailScreenState extends State<TxDetailScreen> {
  TxData? _tx;
  bool    _loading       = true;
  bool    _deleting      = false;
  bool    _confirmDelete = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tx = await AccountingService.getTransaction(widget.txId);
    setState(() { _tx = tx; _loading = false; });
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    await AccountingService.deleteTransaction(widget.txId);
    if (mounted) context.go('/accounting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : _tx == null
              ? ErrorState(message: 'Transaksi tidak ditemukan.', onRetry: _load)
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      children: [
                        _buildHero(),
                        const SizedBox(height: 14),
                        _buildDetails(),
                        const SizedBox(height: 14),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Hero amount card ───────────────────────────────────────────────────────

  Widget _buildHero() {
    final tx = _tx!;
    return AppCard(
      backgroundColor: tx.isIncome
          ? AppColors.incomeLight
          : AppColors.expenseLight,
      borderColor: tx.isIncome
          ? AppColors.incomeBorder
          : AppColors.expense.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(children: [
        // Big icon circle
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: (tx.isIncome ? AppColors.income : AppColors.expense)
                .withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            tx.isIncome
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: tx.isIncome ? AppColors.income : AppColors.expense,
            size: 26,
          ),
        ),
        const SizedBox(height: 12),

        // Amount
        Text(
          '${tx.isIncome ? '+' : '−'}${Rupiah.format(tx.amount)}',
          style: AppTextStyles.mono(
            26,
            color: tx.isIncome ? AppColors.income : AppColors.expense,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
          style: AppTextStyles.body(
            13,
            color: tx.isIncome
                ? AppColors.income.withOpacity(0.7)
                : AppColors.expense.withOpacity(0.7),
          ),
        ),
      ]),
    );
  }

  // ── Detail rows ────────────────────────────────────────────────────────────

  Widget _buildDetails() {
    final tx = _tx!;
    final pmLabels = const {
      'CASH':         'Tunai',
      'TRANSFER':     'Transfer Bank',
      'QRIS':         'QRIS',
      'KARTU_DEBIT':  'Kartu Debit',
      'KARTU_KREDIT': 'Kartu Kredit',
      'COD':          'COD',
      'OTHER':        'Lainnya',
    };

    return AppCard(
      child: Column(children: [
        _DetailRow(
          icon: Icons.sell_outlined,
          label: 'Kategori',
          child: Row(children: [
            Text(tx.category.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(tx.category.name,
              style: AppTextStyles.body(14, weight: FontWeight.w500)),
            if (tx.category.taxRelevant) ...[
              const SizedBox(width: 6),
              StatusBadge('Pajak', variant: BadgeVariant.amber),
            ],
            if (tx.category.isCogs) ...[
              const SizedBox(width: 4),
              StatusBadge('HPP', variant: BadgeVariant.blue),
            ],
          ]),
        ),
        const Divider(height: 1),

        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Tanggal',
          value: Tanggal.long(tx.date),
        ),
        const Divider(height: 1),

        _DetailRow(
          icon: Icons.payment_outlined,
          label: 'Metode Pembayaran',
          value: pmLabels[tx.paymentMethod] ?? tx.paymentMethod,
        ),

        if (tx.description != null && tx.description!.isNotEmpty) ...[
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.notes_rounded,
            label: 'Keterangan',
            value: tx.description!,
          ),
        ],

        if (tx.receiptNote != null && tx.receiptNote!.isNotEmpty) ...[
          const Divider(height: 1),
          _DetailRow(
            icon: Icons.receipt_outlined,
            label: 'Catatan Nota',
            value: tx.receiptNote!,
          ),
        ],

        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            Icon(Icons.access_time_rounded,
              size: 15, color: AppColors.stone300),
            const SizedBox(width: 8),
            Text(
              'Dicatat: ${Tanggal.long(tx.createdAt)}',
              style: AppTextStyles.body(11, color: AppColors.stone400),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions() {
    // Delete confirmation strip
    if (_confirmDelete) {
      return AppCard(
        backgroundColor: AppColors.expenseLight,
        borderColor: AppColors.expense.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded,
            color: AppColors.expense, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Hapus transaksi ini?',
              style: AppTextStyles.body(13,
                color: AppColors.expense, weight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => setState(() => _confirmDelete = false),
            child: Text('Batal',
              style: AppTextStyles.body(13, color: AppColors.stone400)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: _deleting ? null : _delete,
            child: _deleting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Text('Ya, Hapus'),
          ),
        ]),
      );
    }

    // Normal buttons
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit'),
        ),
      ),
      const SizedBox(width: 10),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.expense,
          side: BorderSide(
            color: AppColors.expense.withOpacity(0.4), width: 0.5),
        ),
        onPressed: () => setState(() => _confirmDelete = true),
        icon: Icon(Icons.delete_outline_rounded, size: 16),
        label: const Text('Hapus'),
      ),
    ]);
  }
}

// ── Detail Row helper ─────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.stone400),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: AppTextStyles.body(11, color: AppColors.stone400)),
            const SizedBox(height: 3),
            child ?? Text(value ?? '',
              style: AppTextStyles.body(14, weight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}