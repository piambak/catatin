// lib/widgets/accounting/month_picker.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/accounting_service.dart';
import '../common/app_widgets.dart';
import './tx_add_sheet.dart';

// ── Month Tab Picker ──────────────────────────────────────────────────────────

class MonthPicker extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;

  static const _months = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des',
  ];

  const MonthPicker({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final month = i + 1;
          final isSelected = month == selectedMonth;
          return GestureDetector(
            onTap: () => onMonthChanged(month),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.dark : AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.dark : AppColors.stone200,
                  width: 0.5,
                ),
              ),
              child: Text(
                _months[i],
                style: AppTextStyles.body(
                  12,
                  color: isSelected ? Colors.white : AppColors.stone500,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Summary Row (3 cards) ─────────────────────────────────────────────────────

class AccountingSummaryRow extends StatelessWidget {
  final TxSummary summary;
  final bool isLoading;

  const AccountingSummaryRow({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        label: 'Pemasukan',
        amount: summary.income,
        icon: Icons.arrow_upward_rounded,
        color: AppColors.income,
        bg: AppColors.incomeLight,
      ),
      _SummaryItem(
        label: 'Pengeluaran',
        amount: summary.expense,
        icon: Icons.arrow_downward_rounded,
        color: AppColors.expense,
        bg: AppColors.expenseLight,
      ),
      _SummaryItem(
        label: 'Laba Bersih',
        amount: summary.profit,
        icon: Icons.account_balance_wallet_outlined,
        color: summary.profit >= 0 ? AppColors.income : AppColors.expense,
        bg: summary.profit >= 0 ? AppColors.incomeLight : AppColors.expenseLight,
      ),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: e.key == 0 ? 0 : 5,
              right: e.key == 2 ? 0 : 5,
            ),
            child: AppCard(
              padding: const EdgeInsets.all(11),
              child: Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: e.value.bg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(e.value.icon, size: 14, color: e.value.color),
                  ),
                  const SizedBox(height: 7),
                  isLoading
                    ? const ShimmerBox(width: 70, height: 13)
                    : Text(
                        Rupiah.compact(e.value.amount),
                        style: AppTextStyles.mono(12,
                          color: e.value.color, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  const SizedBox(height: 2),
                  Text(e.value.label,
                    style: AppTextStyles.body(9, color: AppColors.stone400),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bg;
  const _SummaryItem({
    required this.label, required this.amount,
    required this.icon, required this.color, required this.bg,
  });
}

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
          ? AppColors.brand.withOpacity(0.04)
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
                  color: tx.category.flutterColor.withOpacity(0.15),
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
              color: tx.category.flutterColor.withOpacity(0.15),
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
              Navigator.of(context).pop();
              // Slight delay so first dialog fully dismisses
              Future.microtask(() => _openEdit(context, tx));
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

  void _openEdit(BuildContext context, TxData tx) {
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
  }

  String _payLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':     return 'Tunai';
      case 'TRANSFER': return 'Transfer Bank';
      case 'QRIS':     return 'QRIS';
      case 'DEBIT':    return 'Kartu Debit';
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