// lib/widgets/dashboard/recent_transactions.dart

import 'package:flutter/material.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<RecentTx> transactions;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onTxTap;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.onViewAll,
    this.onTxTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaksi Terakhir',
                  style: AppTextStyles.display(15)),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text('Lihat semua',
                      style: AppTextStyles.body(12,
                        color: AppColors.brand, weight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Loading shimmer
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: List.generate(4, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    const ShimmerBox(width: 36, height: 36, radius: 8),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 130, height: 12),
                        SizedBox(height: 5),
                        ShimmerBox(width: 80, height: 10),
                      ],
                    )),
                    const ShimmerBox(width: 80, height: 14),
                  ]),
                )),
              ),
            )

          // Empty state
          else if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Catat transaksi pertama Anda',
                action: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Catat Transaksi'),
                ),
              ),
            )

          // Transaction rows
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _TxRow(
                tx: transactions[i],
                onTap: onTxTap != null
                  ? () => onTxTap!(transactions[i].id)
                  : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _TxRow extends StatefulWidget {
  final RecentTx tx;
  final VoidCallback? onTap;

  const _TxRow({required this.tx, this.onTap});

  @override
  State<_TxRow> createState() => _TxRowState();
}

class _TxRowState extends State<_TxRow> {
  bool _hovered = false;

  Color get _iconBg {
    final hex = widget.tx.categoryColor.replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));
    return color.withOpacity(0.15);
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
        decoration: BoxDecoration(
          color: _hovered
            ? AppColors.brand.withOpacity(0.04)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          splashColor: AppColors.brand.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
            // Category icon bubble
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tx.categoryIcon ?? '💰',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description ?? tx.categoryName,
                    style: AppTextStyles.body(13, weight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${Tanggal.short(tx.date)} · ${tx.categoryName}',
                    style: AppTextStyles.body(11, color: AppColors.stone400),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '${tx.isIncome ? '+' : '−'}${Rupiah.format(tx.amount)}',
              style: AppTextStyles.mono(13,
                color: tx.isIncome ? AppColors.income : AppColors.expense,
                weight: FontWeight.w600),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}