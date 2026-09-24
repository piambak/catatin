// lib/widgets/accounting/tx_list_tile.dart

//
// Satu baris transaksi di daftar Pembukuan.
//
// Ketuk = buka layar detail (`/accounting/:id`) — di sanalah Sunting dan Hapus
// tinggal. Dulu baris ini mengabaikan `onTap` dan membuka dialog detail
// tersendiri (T-20a): dua jalan ke "detail" yang isinya berbeda, dan dialog di
// atas dialog saat menyunting (R-5).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/accounting_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// ── Transaction List Tile ─────────────────────────────────────────────────────

class TxListTile extends StatefulWidget {
  final TxData tx;

  /// Aksi saat diketuk. Kosong = buka detail transaksi.
  final VoidCallback? onTap;

  /// `false` untuk baris ringkasan yang bukan satu transaksi utuh (mis. total
  /// per keterangan): tidak bisa diketuk dan tanpa chevron, supaya tidak
  /// menjanjikan detail yang tidak ada.
  final bool interactive;

  const TxListTile({
    super.key,
    required this.tx,
    this.onTap,
    this.interactive = true,
  });

  @override
  State<TxListTile> createState() => _TxListTileState();
}

class _TxListTileState extends State<TxListTile> {
  bool _hovered = false;

  void _open() {
    final onTap = widget.onTap;
    if (onTap != null) {
      onTap();
    } else {
      // push, bukan go: detail punya tombol kembali ke daftar ini (T-19).
      context.push('/accounting/${widget.tx.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final interactive = widget.interactive;
    return MouseRegion(
      onEnter: (_) {
        if (interactive) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (interactive) setState(() => _hovered = false);
      },
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered
          ? AppColors.brand.withValues(alpha: 0.04)
          : Colors.transparent,
        child: InkWell(
          onTap: interactive ? _open : null,
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
              if (interactive) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                  size: 16,
                  color: _hovered ? AppColors.brand : AppColors.stone300),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
