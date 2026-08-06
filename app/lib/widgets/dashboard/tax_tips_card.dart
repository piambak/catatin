// lib/widgets/dashboard/tax_tips_card.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class TaxTip {
  final String title;
  final String body;
  final List<String> tags;
  const TaxTip({required this.title, required this.body, required this.tags});

  static List<TaxTip> defaults() => const [
    TaxTip(
      title: 'Biaya sewa tempat usaha bisa jadi pengurang pajak',
      body:  'Simpan bukti pembayaran sewa dan catat sebagai pengeluaran usaha. '
             'Ini mengurangi PKP saat beralih dari rezim PP 23/2018 ke rezim normal.',
      tags:  ['PPh Badan', 'Pengurang Pajak'],
    ),
    TaxTip(
      title: 'Simpan semua struk dan faktur pengeluaran usaha',
      body:  'Faktur belanja bahan baku, listrik, dan operasional adalah bukti '
             'yang diakui DJP. Scan dan simpan digitalnya minimal 5 tahun.',
      tags:  ['Pembukuan', 'Dokumentasi'],
    ),
    TaxTip(
      title: 'Setor PPh Final sebelum tanggal 15 setiap bulan',
      body:  'PPh Final 0,5% dari omzet bruto harus disetor paling lambat '
             'tanggal 15 bulan berikutnya. Telat dikenakan denda 2% per bulan.',
      tags:  ['PPh Final', 'Deadline'],
    ),
    TaxTip(
      title: 'Pisahkan rekening pribadi dan rekening usaha',
      body:  'Mencampur keuangan pribadi dan usaha menyulitkan pembukuan dan '
             'bisa memicu pemeriksaan pajak DJP.',
      tags:  ['Pembukuan', 'UMKM'],
    ),
    TaxTip(
      title: 'Batas PKP bukan hanya soal omzet',
      body:  'Selain omzet Rp 4,8 M, perhatikan proyeksi pertumbuhan usaha. '
             'Konsultasikan ke konsultan pajak sebelum mendekati batas PKP.',
      tags:  ['PKP', 'PPN'],
    ),
  ];
}

class TaxTipsCard extends StatefulWidget {
  final List<TaxTip> tips;
  const TaxTipsCard({super.key, this.tips = const []});

  @override
  State<TaxTipsCard> createState() => _TaxTipsCardState();
}

class _TaxTipsCardState extends State<TaxTipsCard> {
  int _idx = 0;

  List<TaxTip> get _tips =>
      widget.tips.isNotEmpty ? widget.tips : TaxTip.defaults();
  TaxTip get _current => _tips[_idx];

  void _prev() => setState(() =>
      _idx = (_idx - 1 + _tips.length) % _tips.length);
  void _next() => setState(() =>
      _idx = (_idx + 1) % _tips.length);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 220),
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.lightbulb_outline_rounded,
                size: 12, color: AppColors.warning),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text('Tips Pajak Hari Ini',
              style: AppTextStyles.display(13))),
          ]),
          const SizedBox(height: 2),
          Text('${Tanggal.long(DateTime.now())} · ${_idx + 1}/${_tips.length}',
            style: AppTextStyles.body(10, color: AppColors.stone400)),
          const SizedBox(height: 10),

          // Tip body
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Container(
              key: ValueKey(_idx),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_current.title,
                    style: AppTextStyles.body(
                      12, weight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(_current.body,
                    style: AppTextStyles.body(
                      11, color: AppColors.stone500),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tags + arrow nav in one row
          Row(children: [
            Expanded(
              child: Wrap(spacing: 5, runSpacing: 4,
                children: _current.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.stone200, width: 0.5)),
                  child: Text(t, style: AppTextStyles.body(
                    10, color: AppColors.stone500)),
                )).toList(),
              ),
            ),
            const SizedBox(width: 8),
            // Arrow buttons — icon only
            _ArrowBtn(
              icon: Icons.chevron_left_rounded,
              onTap: _tips.length > 1 ? _prev : null,
            ),
            const SizedBox(width: 6),
            _ArrowBtn(
              icon: Icons.chevron_right_rounded,
              onTap: _tips.length > 1 ? _next : null,
            ),
          ]),
        ],
      ),
    ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ArrowBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.stone200, width: 0.5),
        ),
        child: Icon(icon,
          size: 18,
          color: onTap != null ? AppColors.stone500 : AppColors.stone300),
      ),
    );
  }
}