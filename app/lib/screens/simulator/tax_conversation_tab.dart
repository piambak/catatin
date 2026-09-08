// lib/screens/simulator/tax_conversation_tab.dart
//
// Simulator sebagai percakapan — artboard 1c di Catatin.dc.html.
//
// Tiga pertanyaan berurutan. Jawaban yang selesai mengendap jadi baris ringkas
// dengan tautan "Ubah", dan hasilnya tumbuh di bawah tanpa pindah layar.
//
// SEMUA kalkulasi memanggil core/services/simulator_service.dart. Layar ini
// tidak memuat satu pun tarif atau rumus pajak sendiri — itu keputusan sadar
// supaya bug T-1 (kategori TER B & C belum ada) tetap tinggal di satu tempat
// dan tidak ikut tersalin ke kode baru. Lihat docs/PROJECT_TIMELINE.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/simulator_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/common/ds_widgets.dart';

/// Pilihan profesi.
///
/// Catatan: jawaban ini **tidak memengaruhi** hasil hitung — sama seperti di
/// mockup. Fungsinya membuka percakapan dengan pertanyaan yang mudah dijawab.
/// Kalau nanti dipakai memilih skema pajak, sambungkan di `_result`.
const _professions = <String>[
  'Desainer / kreatif',
  'Fotografer / videografer',
  'Guru / tutor',
  'Dokter / tenaga medis',
  'Pedagang online',
  'Driver / kurir',
  'Lainnya',
];

/// Label manusiawi untuk tiap status PTKP.
///
/// Mockup memakai 5 pilihan; aplikasi punya 8 di [PtkpStatus]. Kedelapannya
/// ditampilkan supaya tidak ada kemampuan yang hilang. Kode teknis (TK/0, K/1)
/// turun jadi keterangan kecil di kanan, bukan label utama.
const _ptkpLabels = <PtkpStatus, String>{
  PtkpStatus.tk0: 'Belum menikah, tanpa tanggungan',
  PtkpStatus.tk1: 'Belum menikah, 1 tanggungan',
  PtkpStatus.tk2: 'Belum menikah, 2 tanggungan',
  PtkpStatus.tk3: 'Belum menikah, 3 tanggungan',
  PtkpStatus.k0: 'Menikah, tanpa tanggungan',
  PtkpStatus.k1: 'Menikah, 1 tanggungan',
  PtkpStatus.k2: 'Menikah, 2 tanggungan',
  PtkpStatus.k3: 'Menikah, 3 tanggungan',
};

enum _Step { profession, income, ptkp }

class TaxConversationTab extends StatefulWidget {
  const TaxConversationTab({super.key});

  @override
  State<TaxConversationTab> createState() => _TaxConversationTabState();
}

class _TaxConversationTabState extends State<TaxConversationTab> {
  final _incomeCtrl = TextEditingController();

  _Step _step = _Step.profession;
  String? _profession;
  double _income = 0;
  PtkpStatus? _ptkp;
  bool _explainOpen = false;

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  bool get _done => _profession != null && _income > 0 && _ptkp != null;
  bool get _hasResult => _income > 0;

  PPh21Result? get _result =>
      _hasResult && _ptkp != null ? calculatePPh21(_income, _ptkp!) : null;

  /// Pembanding skema UMKM, dari service yang sama.
  double get _umkm => calculatePPhFinal(_income).pajakBulanan;

  void _reset() {
    setState(() {
      _step = _Step.profession;
      _profession = null;
      _income = 0;
      _ptkp = null;
      _explainOpen = false;
      _incomeCtrl.clear();
    });
  }

  void _pickProfession(String p) => setState(() {
        _profession = p;
        _step = _Step.income;
      });

  void _submitIncome() {
    if (_income <= 0) return;
    setState(() => _step = _Step.ptkp);
  }

  void _pickPtkp(PtkpStatus s) => setState(() => _ptkp = s);

  void _onIncomeChanged(String raw) {
    final formatted = Rupiah.typing(raw);
    _incomeCtrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() => _income = Rupiah.parse(formatted));
  }

  @override
  Widget build(BuildContext context) {
    return BreakpointBuilder(
      builder: (context, bp) {
        final wide = bp.isExpanded;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  Bp.pagePadding(bp),
                  18,
                  Bp.pagePadding(bp),
                  24 + (wide || _hasResult ? 0 : Bp.bottomInset(bp)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 720 : 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._answeredRows(),
                        if (_step == _Step.profession) _professionCard(wide),
                        if (_step == _Step.income) _incomeCard(wide),
                        if (_step == _Step.ptkp && _ptkp == null)
                          _ptkpCard(wide),
                        if (wide && _hasResult) ...[
                          const SizedBox(height: 14),
                          _ResultPanel(
                            result: _result,
                            income: _income,
                            ptkp: _ptkp,
                            umkm: _umkm,
                            expanded: true,
                            explainOpen: true,
                            onToggleExplain: null,
                          ),
                        ],
                        if (_done) ...[
                          const SizedBox(height: 14),
                          DsButton(
                            label: 'Hitung ulang dari awal',
                            onPressed: _reset,
                            kind: DsButtonKind.outlined,
                            minHeight: 44,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Di layar sempit hasil menempel di bawah seperti di mockup.
            if (!wide && _hasResult && _step != _Step.income)
              _ResultPanel(
                result: _result,
                income: _income,
                ptkp: _ptkp,
                umkm: _umkm,
                expanded: false,
                explainOpen: _explainOpen,
                onToggleExplain: _done
                    ? () => setState(() => _explainOpen = !_explainOpen)
                    : null,
              ),
          ],
        );
      },
    );
  }

  List<Widget> _answeredRows() {
    final rows = <Widget>[];

    void add(String label, String value, VoidCallback onEdit) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DsAnsweredRow(label: label, value: value, onEdit: onEdit),
      ));
    }

    if (_profession != null) {
      add('Pekerjaan', _profession!,
          () => setState(() => _step = _Step.profession));
    }
    if (_income > 0 && _step != _Step.income) {
      add('Penghasilan per bulan', Rupiah.format(_income),
          () => setState(() => _step = _Step.income));
    }
    if (_ptkp != null) {
      add('Status keluarga', _ptkpLabels[_ptkp]!,
          () => setState(() {
                _ptkp = null;
                _step = _Step.ptkp;
              }));
    }
    return rows;
  }

  Widget _professionCard(bool wide) => _StepShell(
        wide: wide,
        step: 'Langkah 1 dari 3',
        question: 'Anda bekerja sebagai apa?',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _professions)
              DsChoiceChip(label: p, onTap: () => _pickProfession(p)),
          ],
        ),
      );

  Widget _incomeCard(bool wide) => _StepShell(
        wide: wide,
        step: 'Langkah 2 dari 3',
        question: 'Berapa penghasilan Anda dalam sebulan?',
        hint: 'Rata-rata saja, tidak harus persis.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 340 : double.infinity),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DS.brand, width: 2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rp', style: T.mono(18, color: DS.faint)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _incomeCtrl,
                        onChanged: _onIncomeChanged,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        autofocus: true,
                        style: T.mono(wide ? 32 : 30, color: DS.ink),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: T.mono(wide ? 32 : 30, color: DS.hairline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _income > 0
                  ? 'Ketuk kolomnya untuk mengubah.'
                  : 'Ketik nominal tanpa titik — pemisah ribuan ditambahkan otomatis.',
              style: T.sans(12.5, color: DS.faint),
            ),
            const SizedBox(height: 14),
            DsButton(
              label: _income > 0
                  ? 'Lanjut · ${Rupiah.format(_income)}'
                  : 'Masukkan penghasilan dulu',
              onPressed: _income > 0 ? _submitIncome : null,
              expand: !wide,
              minHeight: 50,
            ),
          ],
        ),
      );

  Widget _ptkpCard(bool wide) => _StepShell(
        wide: wide,
        step: 'Langkah 3 dari 3',
        question: 'Bagaimana status keluarga Anda?',
        hint: 'Ini menentukan penghasilan tidak kena pajak (PTKP).',
        child: Column(
          children: [
            for (final entry in _ptkpLabels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DsChoiceChip(
                  label: entry.value,
                  trailing: entry.key.shortLabel,
                  expand: true,
                  onTap: () => _pickPtkp(entry.key),
                ),
              ),
          ],
        ),
      );
}

/// Bungkus kartu langkah. Di web mockup memakai bidang polos tanpa border;
/// di ponsel memakai kartu berbingkai.
class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.wide,
    required this.step,
    required this.question,
    required this.child,
    this.hint,
  });

  final bool wide;
  final String step;
  final String question;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[
          DsLabel(step, size: 11),
          const SizedBox(height: 8),
        ],
        Text(question,
            style: T.sans(wide ? 20 : 19,
                weight: FontWeight.w600, color: DS.ink, height: 1.35)),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: T.sans(13.5, color: DS.muted)),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );

    if (wide) {
      return Padding(padding: const EdgeInsets.only(top: 8), child: content);
    }
    return DsStepCard(child: content);
  }
}

/// Panel hasil. Selalu gelap di kedua mode — itu maksud desainnya.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.income,
    required this.ptkp,
    required this.umkm,
    required this.expanded,
    required this.explainOpen,
    required this.onToggleExplain,
  });

  final PPh21Result? result;
  final double income;
  final PtkpStatus? ptkp;
  final double umkm;
  final bool expanded;
  final bool explainOpen;
  final VoidCallback? onToggleExplain;

  String get _taxText =>
      result == null ? '—' : Rupiah.format(result!.pajakBulanan);

  String get _subText {
    final r = result;
    if (r == null) return 'Pilih status keluarga untuk hasil akhir.';
    final status = ptkp == null ? '' : ' · ${ptkp!.shortLabel}';
    return 'per bulan · tarif TER ${Pct.format(r.terRate)}$status';
  }

  String get _explainText {
    final r = result;
    if (r == null || ptkp == null) {
      return 'Jawab tiga pertanyaan di atas untuk melihat perhitungannya.';
    }
    return 'Penghasilan bulanan Anda ${Rupiah.format(income)}. '
        'Dengan status ${ptkp!.shortLabel}, penghasilan tidak kena pajak Anda '
        '${Rupiah.format(r.ptkp)} per tahun, dan tarif efektif bulanan (TER) '
        'yang berlaku ${Pct.format(r.terRate)}. Jadi kira-kira '
        '${Rupiah.format(r.pajakBulanan)} dipotong tiap bulan. '
        'Kalau Anda memakai skema UMKM 0,5%, angkanya '
        '${Rupiah.format(umkm)} per bulan.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Padding bawah ekstra di layar sempit supaya isi panel tidak tertutup
      // pil navigasi yang mengambang di atasnya.
      padding: EdgeInsets.fromLTRB(
        expanded ? 26 : 22,
        expanded ? 24 : 18,
        expanded ? 26 : 22,
        expanded ? 24 : 22 + Bp.floatingNavInset,
      ),
      decoration: BoxDecoration(
        color: DS.invSurface,
        borderRadius: expanded
            ? BorderRadius.circular(Radii.lg)
            : const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const DsLabel('Perkiraan pajak Anda', color: DS.invMuted),
          const SizedBox(height: 8),
          Semantics(
            label: 'Perkiraan pajak Anda $_taxText, $_subText',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_taxText,
                        style: T.serif(expanded ? 40 : 34,
                            color: DS.invInk, height: 1.1)),
                  ),
                  const SizedBox(height: 6),
                  Text(_subText,
                      style: T.sans(expanded ? 14.5 : 13.5, color: DS.soft)),
                ],
              ),
            ),
          ),
          if (onToggleExplain != null) ...[
            const SizedBox(height: 14),
            DsButton(
              label: explainOpen ? 'Tutup penjelasan' : 'Kenapa segini?',
              onPressed: onToggleExplain,
              kind: DsButtonKind.ghost,
              minHeight: 44,
              foreground: DS.invInk,
            ),
          ],
          if (explainOpen) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: expanded ? 560 : double.infinity),
              child: Text(_explainText,
                  style: T.sans(expanded ? 15 : 14.5,
                      color: DS.invBody, height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }
}
