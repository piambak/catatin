// lib/widgets/simulator/sim_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';

// ─── Simulator Section Card ───────────────────────────────────────────────────

class SimCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const SimCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: AppTextStyles.body(
                    14, weight: FontWeight.w600)),
                Text(subtitle,
                  style: AppTextStyles.body(
                    11, color: AppColors.stone400)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Rupiah Input Field ───────────────────────────────────────────────────────

class RupiahInput extends StatefulWidget {
  final String label;
  final String hint;
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final String? helper;

  const RupiahInput({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    required this.onChanged,
    this.helper,
  });

  @override
  State<RupiahInput> createState() => _RupiahInputState();
}

class _RupiahInputState extends State<RupiahInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue != null && widget.initialValue! > 0
          ? Rupiah.typing(widget.initialValue!.toStringAsFixed(0))
          : '',
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = digits.isEmpty ? '' : Rupiah.typing(digits);

    // Update display without firing onChanged loop
    _ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length.clamp(0, formatted.length)),
    );

    final val = double.tryParse(digits) ?? 0;
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
          style: AppTextStyles.body(12, weight: FontWeight.w500)),
        const SizedBox(height: 5),
        Focus(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onChanged,
            style: AppTextStyles.mono(14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.body(13, color: AppColors.stone400),
              prefixText: 'Rp  ',
              prefixStyle: AppTextStyles.mono(
                13, color: AppColors.stone400),
              helperText: widget.helper,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Result Box ───────────────────────────────────────────────────────────────

enum ResultBoxVariant { green, blue, amber, red }

class ResultBox extends StatelessWidget {
  final ResultBoxVariant variant;
  final List<ResultRow> rows;
  final Widget? footer;

  const ResultBox({
    super.key,
    required this.variant,
    required this.rows,
    this.footer,
  });

  (Color, Color, Color) get _colors => switch (variant) {
    ResultBoxVariant.green => (
      AppColors.incomeLight, AppColors.incomeBorder, AppColors.income),
    ResultBoxVariant.blue  => (
      AppColors.navyLight, AppColors.navyBorder, AppColors.navy),
    ResultBoxVariant.amber => (
      AppColors.warningLight, AppColors.warningBorder, AppColors.warning),
    ResultBoxVariant.red   => (
      AppColors.expenseLight,
      AppColors.expense.withOpacity(0.3),
      AppColors.expense),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = _colors;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          ...rows.map((r) => _ResultRowWidget(row: r, fg: fg)),
          if (footer != null) ...[
            Divider(height: 16, color: border),
            footer!,
          ],
        ],
      ),
    );
  }
}

class ResultRow {
  final String label;
  final String value;
  final bool isBig;
  final bool isDivider;

  const ResultRow({
    required this.label,
    required this.value,
    this.isBig = false,
    this.isDivider = false,
  });
}

class _ResultRowWidget extends StatelessWidget {
  final ResultRow row;
  final Color fg;

  const _ResultRowWidget({required this.row, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(row.label,
            style: AppTextStyles.body(
              row.isBig ? 12 : 11, color: fg.withOpacity(0.75))),
          Text(row.value,
            style: AppTextStyles.mono(
              row.isBig ? 18 : 13,
              color: fg,
              weight: row.isBig ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── PKP Progress Bar ─────────────────────────────────────────────────────────

class SimPkpBar extends StatelessWidget {
  final double percent;   // 0–100
  final bool   isDanger;
  final bool   isWarning;

  const SimPkpBar({
    super.key,
    required this.percent,
    required this.isDanger,
    required this.isWarning,
  });

  Color get _color {
    if (isDanger)  return AppColors.expense;
    if (isWarning) return AppColors.warning;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Progres ke batas PKP (Rp 4,8 M/tahun)',
            style: AppTextStyles.body(11, color: _color.withOpacity(0.8))),
          Text(Pct.formatValue(percent),
            style: AppTextStyles.mono(
              12, color: _color, weight: FontWeight.w600)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: _color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
        if (isWarning || isDanger) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.warning_amber_rounded, size: 13, color: _color),
            const SizedBox(width: 4),
            Expanded(child: Text(
              isDanger
                ? 'Segera konsultasi — hampir wajib PKP!'
                : 'Mendekati batas PKP. Pantau omzet Anda.',
              style: AppTextStyles.body(11, color: _color),
            )),
          ]),
        ],
      ],
    );
  }
}

// ─── Disclaimer ───────────────────────────────────────────────────────────────

class SimDisclaimer extends StatelessWidget {
  const SimDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
            size: 14, color: AppColors.stone400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hasil simulasi bersifat estimasi berdasarkan PP 23/2018 dan '
              'PMK 168/2023. Konsultasikan dengan konsultan pajak atau KPP '
              'untuk keputusan yang mengikat.',
              style: AppTextStyles.body(11, color: AppColors.stone400),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scenario Card ────────────────────────────────────────────────────────────

class ScenarioCard extends StatelessWidget {
  final String label;
  final String note;
  final double omzetTahunan;
  final double totalPajak;
  final double effectiveRate;
  final Map<String, double> breakdown;
  final bool isFeatured;

  const ScenarioCard({
    super.key,
    required this.label,
    required this.note,
    required this.omzetTahunan,
    required this.totalPajak,
    required this.effectiveRate,
    required this.breakdown,
    required this.isFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isFeatured ? AppColors.brandSurface : AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFeatured ? AppColors.brand : AppColors.stone200,
          width: isFeatured ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(label,
            style: AppTextStyles.body(10,
              color: isFeatured ? AppColors.brand : AppColors.stone400,
              weight: FontWeight.w600)),
          Text(note,
            style: AppTextStyles.body(10, color: AppColors.stone400)),
          const SizedBox(height: 8),

          // Omzet
          _ScRow('Omzet/Tahun',
            Rupiah.compact(omzetTahunan),
            small: true),

          // Breakdown
          ...breakdown.entries.map((e) =>
            _ScRow(e.key, Rupiah.format(e.value), small: true)),

          const Divider(height: 12),

          // Total
          _ScRow('Total Pajak',
            Rupiah.format(totalPajak),
            bold: true,
            color: isFeatured ? AppColors.brand : null),

          // Rate
          Row(children: [
            Text('Efektif rate: ',
              style: AppTextStyles.body(10, color: AppColors.stone400)),
            Text(Pct.format(effectiveRate, decimals: 2),
              style: AppTextStyles.mono(10,
                color: isFeatured ? AppColors.brand : AppColors.stone600,
                weight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

class _ScRow extends StatelessWidget {
  final String k;
  final String v;
  final bool small;
  final bool bold;
  final Color? color;

  const _ScRow(this.k, this.v, {this.small = false, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: AppTextStyles.body(
            small ? 10 : 12, color: AppColors.stone500)),
          Text(v, style: AppTextStyles.mono(
            small ? 10 : 12,
            color: color ?? AppColors.stone800,
            weight: bold ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Deadline Row ─────────────────────────────────────────────────────────────

class DeadlineRow extends StatelessWidget {
  final String taxType;
  final String label;
  final String period;
  final DateTime deadline;
  final String daysLabel;
  final Color dotColor;
  final Color badgeColor;
  final Color badgeText;

  const DeadlineRow({
    super.key,
    required this.taxType,
    required this.label,
    required this.period,
    required this.deadline,
    required this.daysLabel,
    required this.dotColor,
    required this.badgeColor,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        // Dot
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          margin: const EdgeInsets.only(top: 2),
        ),
        const SizedBox(width: 10),

        // Label + date
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: AppTextStyles.body(12, weight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Jatuh tempo: ${Tanggal.long(deadline)}',
              style: AppTextStyles.body(10, color: AppColors.stone400)),
          ],
        )),
        const SizedBox(width: 8),

        // Days badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(daysLabel,
            style: AppTextStyles.body(10, color: badgeText,
              weight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),

        // Tax type tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.stone100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.stone200, width: 0.5),
          ),
          child: Text(taxType,
            style: AppTextStyles.body(9, color: AppColors.stone500)),
        ),
      ]),
    );
  }
}