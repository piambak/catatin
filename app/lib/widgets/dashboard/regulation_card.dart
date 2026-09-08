// lib/widgets/dashboard/regulation_card.dart
//
// Sebelumnya menarik daftar dokumen dari Pustaka peraturan (LibraryService).
// Fitur Pustaka peraturan dicabut di Fase Dua — kartu ini sekarang berisi
// info pajak dasar secara inline. Isi masih sementara; menunggu daftar final
// dari Pakar Regulasi DJP & Kemenkeu (lihat docs/PROJECT_TIMELINE.md Minggu 1).
//
// Aturan isi kartu ini, sampai pakar pajak memberi daftar final:
//
//   1. Angka pajak TIDAK boleh ditulis ulang sebagai teks di sini. Ambil dari
//      `AppConstants` supaya kartu dan Simulator tidak pernah menampilkan tarif
//      yang berbeda setelah tarifnya berubah.
//   2. Poin yang tarifnya sedang bergerak atau butuh syarat panjang JANGAN
//      ditayangkan sebelum ada angka tertulis dari pakar. PPN dan PPh Badan
//      dicabut karena itu — lihat docs/PROJECT_TIMELINE.md, temuan T-3 dan
//      catatan review PR #2.

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

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

  /// Getter, bukan `const`: warna tag ikut tema (AppColors membaca
  /// themeNotifier saat diakses) dan angkanya dirangkai dari AppConstants.
  static List<_RegNote> get defaults => [
    _RegNote(
      tag: 'PPh Final',
      tagBg: AppColors.expenseLight,
      tagFg: AppColors.expenseBadgeFg,
      title: 'PPh Final UMKM ${Pct.id(AppConstants.pphFinalRate)} dari omzet',
      body: 'Berlaku untuk usaha dengan omzet bruto hingga '
          '${Rupiah.miliar(AppConstants.pkpThreshold)}/tahun (PP 23/2018), '
          'disetor tiap bulan. Ada syarat jangka waktu dan ambang omzet tidak '
          'kena pajak yang belum dirinci di sini.',
    ),
    _RegNote(
      tag: 'PKP',
      tagBg: AppColors.warningLight,
      tagFg: AppColors.warningBadgeFg,
      title: 'Wajib PKP saat omzet tembus '
          '${Rupiah.miliar(AppConstants.pkpThreshold)}/tahun',
      body: 'Setelah jadi Pengusaha Kena Pajak, usaha wajib memungut dan '
          'menyetor PPN atas transaksinya.',
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
          Text('Ringkasan sementara, belum ditinjau pakar pajak — bukan '
            'pengganti konsultasi resmi',
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
        color: _hovered ? AppColors.brand.withValues(alpha: 0.04) : Colors.transparent,
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
                        // 3 baris, bukan 2: kartu kini berisi 2 poin (bukan 4)
                        // sehingga ada ruang, dan syarat di ekor kalimat justru
                        // bagian yang tidak boleh terpotong ellipsis.
                        maxLines: 3,
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
