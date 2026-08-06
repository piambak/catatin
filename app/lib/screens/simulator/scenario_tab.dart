// lib/screens/simulator/scenario_tab.dart

import 'package:flutter/material.dart';
import '../../core/services/simulator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/simulator/sim_widgets.dart';

class ScenarioTab extends StatefulWidget {
  const ScenarioTab({super.key});

  @override
  State<ScenarioTab> createState() => _ScenarioTabState();
}

class _ScenarioTabState extends State<ScenarioTab>
    with AutomaticKeepAliveClientMixin {
  double     _omzetBase     = 0;
  int        _employees     = 0;
  double     _avgGaji       = 0;
  PtkpStatus _ptkp          = PtkpStatus.tk0;
  bool       _isPkp         = false;
  List<ScenarioResult>? _results;

  @override
  bool get wantKeepAlive => true;

  void _calc() {
    if (_omzetBase <= 0) {
      setState(() => _results = null);
      return;
    }
    setState(() {
      _results = calculateScenarios(ScenarioInput(
        omzetBulanan:  _omzetBase,
        employeeCount: _employees,
        avgGaji:       _avgGaji,
        ptkpStatus:    _ptkp,
        isPkp:         _isPkp,
      ));
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
          // ── Input card ────────────────────────────────────
          SimCard(
            title: 'Perencana Skenario',
            subtitle: 'Bandingkan beban pajak di 3 skenario omzet',
            icon: Icons.tune_rounded,
            iconColor: AppColors.income,
            children: [
              RupiahInput(
                label: 'Omzet Bulanan Base (Rp)',
                hint: '28.500.000',
                onChanged: (v) { _omzetBase = v; _calc(); },
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jumlah Karyawan',
                      style: AppTextStyles.body(
                        12, weight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    _StepperInput(
                      value: _employees,
                      onChanged: (v) { _employees = v; _calc(); },
                    ),
                  ],
                )),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status PKP',
                      style: AppTextStyles.body(
                        12, weight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    _PkpToggle(
                      value: _isPkp,
                      onChanged: (v) { _isPkp = v; _calc(); },
                    ),
                  ],
                )),
              ]),

              if (_employees > 0) ...[
                const SizedBox(height: 14),
                RupiahInput(
                  label: 'Rata-rata Gaji Karyawan (Rp)',
                  hint: '5.000.000',
                  onChanged: (v) { _avgGaji = v; _calc(); },
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // ── Scenario Cards ────────────────────────────────
          if (_results != null) ...[
            // Cards stacked (full-width each)
            ..._results!.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ScenarioCard(
                label:         s.label,
                note:          _noteFor(s.label),
                omzetTahunan:  s.omzetTahunan,
                totalPajak:    s.totalPajak,
                effectiveRate: s.effectiveRate,
                breakdown: {
                  'PPh Final 0,5%':   s.pphFinal,
                  if (_employees > 0)
                    'PPh 21 Karyawan': s.pph21Total,
                  if (_isPkp)
                    'PPN 11%':         s.ppn,
                },
                isFeatured: s.isFeatured,
              ),
            )),

            // Mini bar chart
            _buildBarChart(_results!),
            const SizedBox(height: 14),
          ],

          const SimDisclaimer(),
        ],
      ),
    );
  }

  String _noteFor(String label) {
    if (label == 'Konservatif') return '70% dari omzet base';
    if (label == 'Optimistis')  return '140% dari omzet base';
    return 'Omzet saat ini';
  }

  Widget _buildBarChart(List<ScenarioResult> results) {
    final maxTotal = results.map((r) => r.totalPajak).reduce((a, b) => a > b ? a : b);
    if (maxTotal <= 0) return const SizedBox.shrink();

    final colors = [
      AppColors.incomeBorder,
      AppColors.brand,
      const Color(0xFFF0997B),
    ];

    return SimCard(
      title: 'Perbandingan Beban Pajak',
      subtitle: 'Visualisasi 3 skenario',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.stone500,
      children: [
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: results.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final barHeight = (s.totalPajak / maxTotal * 80).clamp(4.0, 80.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(Rupiah.compact(s.totalPajak),
                        style: AppTextStyles.mono(
                          9, color: AppColors.stone500)),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(s.label,
                        style: AppTextStyles.body(
                          10, color: AppColors.stone500),
                        textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Stepper Input ────────────────────────────────────────────────────────────

class _StepperInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperInput({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.stone300, width: 0.5),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).cardColor,
      ),
      child: Row(children: [
        _StepBtn(icon: Icons.remove_rounded,
          onTap: value > 0 ? () => onChanged(value - 1) : null),
        Expanded(child: Text('$value',
          textAlign: TextAlign.center,
          style: AppTextStyles.mono(14, weight: FontWeight.w600))),
        _StepBtn(icon: Icons.add_rounded,
          onTap: value < 99 ? () => onChanged(value + 1) : null),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        child: Icon(icon,
          size: 18,
          color: onTap != null
              ? AppColors.stone600 : AppColors.stone300),
      ),
    );
  }
}

// ─── PKP Toggle ───────────────────────────────────────────────────────────────

class _PkpToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PkpToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? AppColors.navy : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.navy : AppColors.stone300,
            width: 0.5),
        ),
        child: Row(children: [
          Icon(value
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: value ? Colors.white : AppColors.stone400),
          const SizedBox(width: 6),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value ? 'PKP' : 'Bukan PKP',
                style: AppTextStyles.body(12,
                  color: value ? Colors.white : AppColors.stone700,
                  weight: FontWeight.w600)),
              Text(value ? 'Wajib PPN 11%' : 'Bebas PPN',
                style: AppTextStyles.body(10,
                  color: value
                    ? Colors.white70 : AppColors.stone400)),
            ],
          )),
        ]),
      ),
    );
  }
}