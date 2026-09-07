// lib/widgets/dashboard/regulation_card.dart
//
// Sebelumnya menarik daftar dokumen dari Pustaka peraturan (LibraryService).
// Fitur Pustaka peraturan dicabut di Fase Dua — kartu ini sekarang berisi
// info pajak dasar secara inline. Isi masih sementara; menunggu daftar final
// dari Pakar Regulasi DJP & Kemenkeu (lihat docs/PROJECT_TIMELINE.md Minggu 1).

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class _RegNote {
  final String tag;
  final Color tagBg;
  final Color tagFg;
  final String title;
  final String body;

  const _RegNote({
    required this.tag,
    required this.tagBg,
    required this.tagFg,
    required this.title,
    required this.body,
  });

  static const List<_RegNote> defaults = [
    _RegNote(
      tag: 'PPh Final',
      tagBg: Color(0xFFFCEBEB),
      tagFg: Color(0xFF791F1F),
      title: 'PPh Final UMKM tetap 0,5% dari omzet',
      body: 'Berlaku untuk usaha dengan omzet bruto hingga Rp 4,8 Miliar/tahun '
          '(PP 23/2018), disetor tiap bulan.',
    ),
    _RegNote(
      tag: 'PKP',
      tagBg: Color(0xFFFAEEDA),
      tagFg: Color(0xFF633806),
      title: 'Wajib PKP saat omzet tembus Rp 4,8 Miliar/tahun',
      body: 'Setelah jadi Pengusaha Kena Pajak, usaha wajib memungut dan '
          'menyetor PPN atas transaksinya.',
    ),
    _RegNote(
      tag: 'PPN',
      tagBg: Color(0xFFE6F1FB),
      tagFg: Color(0xFF0C447C),
      title: 'PPN 11% berlaku untuk usaha berstatus PKP',
      body: 'Dikenakan atas penyerahan barang/jasa kena pajak, dihitung dari '
          'dasar pengenaan pajak transaksi.',
    ),
    _RegNote(
      tag: 'PPh Badan',
      tagBg: Color(0xFFEDE9FC),
      tagFg: Color(0xFF3C3489),
      title: 'PPh Badan 22% di luar rezim PPh Final',
      body: 'Berlaku kalau usaha keluar dari skema PPh Final 0,5% (mis. '
          'omzet lewat ambang batas atau bentuk usaha berubah).',
    ),
  ];
}

// ─── Regulation Card ──────────────────────────────────────────────────────────

class RegulationCard extends StatelessWidget {
  final bool compact;

  const RegulationCard({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final notes = _RegNote.defaults;
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Info Pajak UMKM', style: AppTextStyles.display(13)),
          const SizedBox(height: 2),
          Text('Ringkasan aturan dasar — bukan pengganti konsultasi resmi',
            style: AppTextStyles.body(10, color: AppColors.stone400)),
          const SizedBox(height: 10),

          Column(
            children: notes.asMap().entries.map((e) =>
              _RegItem(
                note: e.value,
                isLast: e.key == notes.length - 1,
                compact: compact,
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Single info row ──────────────────────────────────────────────────────────

class _RegItem extends StatefulWidget {
  final _RegNote note;
  final bool isLast;
  final bool compact;

  const _RegItem({
    required this.note,
    required this.isLast,
    this.compact = false,
  });

  @override
  State<_RegItem> createState() => _RegItemState();
}

class _RegItemState extends State<_RegItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.brand.withOpacity(0.04) : Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(
            top: 8, bottom: widget.isLast ? 0 : 8),
          decoration: widget.isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.stone200, width: 0.5))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: note.tagBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  note.tag,
                  style: AppTextStyles.body(
                    9, color: note.tagFg, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: AppTextStyles.body(
                        11, weight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 1),
                      Text(
                        note.body,
                        style: AppTextStyles.body(
                          10, color: AppColors.stone500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
