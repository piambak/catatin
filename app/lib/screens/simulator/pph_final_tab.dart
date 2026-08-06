// lib/screens/simulator/pph_final_tab.dart

import 'package:flutter/material.dart';
import '../../core/services/simulator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/simulator/sim_widgets.dart';
import '../../widgets/common/app_widgets.dart';

class PphFinalTab extends StatefulWidget {
  const PphFinalTab({super.key});

  @override
  State<PphFinalTab> createState() => _PphFinalTabState();
}

class _PphFinalTabState extends State<PphFinalTab>
    with AutomaticKeepAliveClientMixin {
  double _omzetBulanan = 0;
  PPhFinalResult? _result;

  @override
  bool get wantKeepAlive => true; // preserve state on tab switch

  void _onOmzetChanged(double val) {
    setState(() {
      _omzetBulanan = val;
      _result = val > 0 ? calculatePPhFinal(val) : null;
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
            title: 'PPh Final UMKM',
            subtitle: 'PP 23/2018 — tarif 0,5% dari omzet bulanan',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.brand,
            children: [
              RupiahInput(
                label: 'Omzet Bulanan (Rp)',
                hint: '28.500.000',
                initialValue: _omzetBulanan > 0 ? _omzetBulanan : null,
                onChanged: _onOmzetChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Result card ────────────────────────────────────
          if (_result != null) ...[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _result!.eligible
                  ? _buildEligibleResult(_result!)
                  : _buildIneligibleResult(_result!),
            ),
            const SizedBox(height: 14),
          ],

          // ── PKP simulation ─────────────────────────────────
          SimCard(
            title: 'Simulasi Melampaui PKP',
            subtitle: 'Lihat kewajiban jika omzet > Rp 4,8 Miliar',
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: AppColors.warningBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jika omzet Anda melampaui Rp 4,8 M/tahun:',
                      style: AppTextStyles.body(12,
                        color: AppColors.warning,
                        weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...[ 
                      'Wajib dikukuhkan sebagai PKP',
                      'Pungut & setor PPN 11% dari setiap transaksi',
                      'Lapor SPT Masa PPN setiap bulan',
                      'Terbitkan e-Faktur untuk setiap penjualan',
                    ].map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('→ ', style: AppTextStyles.body(
                            11, color: AppColors.warning)),
                          Expanded(child: Text(t, style: AppTextStyles.body(
                            11, color: AppColors.warning))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Syarat PPh Final ───────────────────────────────
          SimCard(
            title: 'Syarat PPh Final 0,5%',
            subtitle: 'Berdasarkan PP 23/2018',
            icon: Icons.checklist_rounded,
            iconColor: AppColors.income,
            children: [
              ...[
                (true,  'WP Orang Pribadi atau Badan (non-PT go public)'),
                (true,  'Omzet bruto ≤ Rp 4,8 Miliar dalam satu tahun pajak'),
                (true,  'Tidak dalam jangka waktu tertentu (masa manfaat)'),
                (false, 'Maks 7 tahun untuk WP Orang Pribadi'),
                (false, 'Maks 4 tahun untuk CV / firma / koperasi'),
                (false, 'Maks 3 tahun untuk PT'),
              ].map((item) {
                final (isGreen, text) = item;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isGreen
                          ? Icons.check_circle_outline_rounded
                          : Icons.schedule_rounded,
                        size: 15,
                        color: isGreen ? AppColors.income : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text,
                        style: AppTextStyles.body(12,
                          color: isGreen
                            ? AppColors.stone600 : AppColors.warning))),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          const SimDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildEligibleResult(PPhFinalResult r) {
    return AppCard(
      key: const ValueKey('eligible'),
      borderColor: AppColors.incomeBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultBox(
            variant: ResultBoxVariant.green,
            rows: [
              ResultRow(label: 'Pajak Bulan Ini',
                value: Rupiah.format(r.pajakBulanan), isBig: true),
              ResultRow(label: 'Estimasi Pajak / Tahun',
                value: Rupiah.format(r.pajakTahunanEst)),
              ResultRow(label: 'Tarif PPh Final',
                value: Pct.format(r.rate)),
              ResultRow(label: 'Estimasi Omzet / Tahun',
                value: Rupiah.format(r.omzetTahunanEst)),
            ],
          ),
          const SizedBox(height: 12),
          SimPkpBar(
            percent:   r.pkpThresholdPercent,
            isDanger:  r.isPkpDanger,
            isWarning: r.isPkpWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildIneligibleResult(PPhFinalResult r) {
    return AppCard(
      key: const ValueKey('ineligible'),
      backgroundColor: AppColors.expenseLight,
      borderColor: AppColors.expense.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline_rounded,
              color: AppColors.expense, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Omzet melebihi Rp 4,8 Miliar/tahun — tidak eligible PPh Final 0,5%. '
              'Wajib beralih ke rezim normal (norma/pembukuan).',
              style: AppTextStyles.body(12, color: AppColors.expense),
            )),
          ]),
          const SizedBox(height: 12),
          ResultBox(
            variant: ResultBoxVariant.red,
            rows: [
              ResultRow(label: 'Estimasi Omzet / Tahun',
                value: Rupiah.format(r.omzetTahunanEst), isBig: true),
              ResultRow(label: 'Batas PKP',
                value: Rupiah.format(4800000000)),
            ],
          ),
        ],
      ),
    );
  }
}
