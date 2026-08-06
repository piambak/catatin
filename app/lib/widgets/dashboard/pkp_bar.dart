// lib/widgets/dashboard/pkp_bar.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';

class PkpBar extends StatelessWidget {
  final double ytdOmzet;
  final bool isLoading;

  const PkpBar({
    super.key,
    required this.ytdOmzet,
    this.isLoading = false,
  });

  static const _pkpThreshold = 4800000000.0;

  double get _percent => (ytdOmzet / _pkpThreshold).clamp(0.0, 1.0);
  double get _percentDisplay => _percent * 100;
  bool get _isWarning  => _percentDisplay >= 70;
  bool get _isDanger   => _percentDisplay >= 90;

  Color get _barColor {
    if (_isDanger)  return AppColors.expense;
    if (_isWarning) return AppColors.warning;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Progres Omzet ke Batas PKP',
                  style: AppTextStyles.body(13, weight: FontWeight.w600)),
                Text('Batas: Rp 4.800.000.000 / tahun',
                  style: AppTextStyles.body(11, color: AppColors.stone400)),
              ]),
              if (!isLoading)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '${_percentDisplay.toStringAsFixed(1)}%',
                    style: AppTextStyles.mono(14,
                      color: _barColor, weight: FontWeight.w700),
                  ),
                  Text(
                    Rupiah.compact(ytdOmzet),
                    style: AppTextStyles.body(11, color: AppColors.stone400),
                  ),
                ]),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          isLoading
              ? const ShimmerBox(width: double.infinity, height: 8, radius: 10)
              : LinearPercentIndicator(
                  percent: _percent,
                  lineHeight: 8,
                  backgroundColor: AppColors.stone100,
                  progressColor: _barColor,
                  barRadius: const Radius.circular(10),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 800,
                ),

          // Warning message
          if (!isLoading && _isWarning) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                size: 14,
                color: _isDanger ? AppColors.expense : AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isDanger
                    ? 'Segera konsultasi — Anda hampir wajib PKP!'
                    : 'Perhatikan omzet — mendekati batas PKP.',
                  style: AppTextStyles.body(11,
                    color: _isDanger ? AppColors.expense : AppColors.warning),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
