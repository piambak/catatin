// lib/screens/simulator/pph21_tab.dart

import 'package:flutter/material.dart';
import '../../core/services/simulator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/simulator/sim_widgets.dart';

class Pph21Tab extends StatefulWidget {
  const Pph21Tab({super.key});

  @override
  State<Pph21Tab> createState() => _Pph21TabState();
}

class _Pph21TabState extends State<Pph21Tab>
    with AutomaticKeepAliveClientMixin {
  double     _gaji       = 0;
  PtkpStatus _ptkp       = PtkpStatus.tk0;
  PPh21Result? _result;
  List<TerRow> _terRows  = buildTerTable(0);

  @override
  bool get wantKeepAlive => true;

  void _calc() {
    setState(() {
      _result  = _gaji > 0 ? calculatePPh21(_gaji, _ptkp) : null;
      _terRows = buildTerTable(_gaji);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Input ─────────────────────────────────────────
          SimCard(
            title: 'PPh 21 Karyawan',
            subtitle: 'Metode TER — PMK 168/2023',
            icon: Icons.people_outline_rounded,
            iconColor: AppColors.navy,
            children: [
              RupiahInput(
                label: 'Gaji Kotor Bulanan (Rp)',
                hint: '8.000.000',
                onChanged: (v) { _gaji = v; _calc(); },
              ),
              const SizedBox(height: 14),
              Text('Status PTKP',
                style: AppTextStyles.body(12, weight: FontWeight.w500)),
              const SizedBox(height: 6),
              _PtkpPicker(
                selected: _ptkp,
                onChanged: (v) { _ptkp = v; _calc(); },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Result ────────────────────────────────────────
          if (_result != null) ...[
            ResultBox(
              variant: ResultBoxVariant.blue,
              rows: [
                ResultRow(label: 'PPh 21 Dipotong / Bulan',
                  value: Rupiah.format(_result!.pajakBulanan), isBig: true),
                ResultRow(label: 'Take-Home Pay',
                  value: Rupiah.format(_result!.netGaji)),
                ResultRow(label: 'Tarif TER Berlaku',
                  value: Pct.format(_result!.terRate)),
                ResultRow(label: 'PTKP Tahunan',
                  value: Rupiah.format(_result!.ptkp)),
                ResultRow(label: 'Estimasi PPh 21 / Tahun',
                  value: Rupiah.format(_result!.pajakTahunanEst)),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── TER table ─────────────────────────────────────
          SimCard(
            title: 'Tabel TER Bulanan',
            subtitle: 'Kategori A (TK/0) — PMK 168/2023',
            icon: Icons.table_chart_outlined,
            iconColor: AppColors.stone500,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.stone200, width: 0.5),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.stone100,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8)),
                      ),
                      child: Row(children: [
                        Expanded(child: Text('Penghasilan s.d.',
                          style: AppTextStyles.body(11,
                            color: AppColors.stone500,
                            weight: FontWeight.w600))),
                        Text('TER/Bulan',
                          style: AppTextStyles.body(11,
                            color: AppColors.stone500,
                            weight: FontWeight.w600)),
                      ]),
                    ),
                    ..._terRows.asMap().entries.map((entry) {
                      final i   = entry.key;
                      final row = entry.value;
                      final isLast = i == _terRows.length - 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: row.isActive
                              ? AppColors.incomeLight
                              : i.isEven
                                  ? AppColors.bgPage
                                  : AppColors.bgCard,
                          borderRadius: isLast
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(8))
                              : null,
                          border: Border(
                            bottom: isLast
                                ? BorderSide.none
                                : BorderSide(
                                    color: AppColors.stone200,
                                    width: 0.5),
                          ),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(row.rangeLabel,
                            style: AppTextStyles.body(11,
                              color: row.isActive
                                  ? AppColors.income
                                  : AppColors.stone600))),
                          Text(Pct.format(row.rate),
                            style: AppTextStyles.mono(11,
                              color: row.isActive
                                  ? AppColors.income
                                  : AppColors.stone800,
                              weight: row.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.incomeLight,
                      border: Border.all(
                        color: AppColors.incomeBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Baris hijau = tarif berlaku untuk gaji ${Rupiah.format(_gaji)}',
                    style: AppTextStyles.body(
                      10, color: AppColors.stone400)),
                ]),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const SimDisclaimer(),
        ],
      ),
    );
  }
}

// ─── PTKP Status Picker ───────────────────────────────────────────────────────

class _PtkpPicker extends StatelessWidget {
  final PtkpStatus selected;
  final ValueChanged<PtkpStatus> onChanged;

  const _PtkpPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: PtkpStatus.values.map((s) {
        final isSelected = s == selected;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.navy : AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.navy : AppColors.stone200,
                width: 0.5,
              ),
            ),
            child: Text(s.shortLabel,
              style: AppTextStyles.body(12,
                color: isSelected
                    ? Colors.white : AppColors.stone600,
                weight: isSelected
                    ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }
}
