// lib/widgets/accounting/tx_form_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// ── Type Toggle (Pemasukan / Pengeluaran) ─────────────────────────────────────

class TypeToggle extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const TypeToggle({
    super.key,
    required this.isIncome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Row(children: [
        _TypeBtn(
          label: 'Pemasukan',
          icon: Icons.arrow_upward_rounded,
          isSelected: isIncome,
          selectedColor: AppColors.income,
          onTap: () => onChanged(true),
        ),
        _TypeBtn(
          label: 'Pengeluaran',
          icon: Icons.arrow_downward_rounded,
          isSelected: !isIncome,
          selectedColor: AppColors.expense,
          onTap: () => onChanged(false),
        ),
      ]),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label, required this.icon,
    required this.isSelected, required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                color: isSelected ? Colors.white : AppColors.stone400),
              const SizedBox(width: 6),
              Text(label,
                style: AppTextStyles.body(13,
                  color: isSelected ? Colors.white : AppColors.stone400,
                  weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Amount Input ──────────────────────────────────────────────────────────────

class AmountInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isIncome;
  final String? error;

  const AmountInput({
    super.key,
    required this.controller,
    required this.isIncome,
    this.error,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  @override
  Widget build(BuildContext context) {
    final color = widget.isIncome ? AppColors.income : AppColors.expense;
    final rawText = widget.controller.text.replaceAll('.', '').replaceAll(',', '');
    final parsedAmount = double.tryParse(rawText) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isIncome ? 'Jumlah Pemasukan' : 'Jumlah Pengeluaran',
          style: AppTextStyles.body(13, weight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.error != null
                ? AppColors.expense
                : AppColors.stone300,
              width: widget.error != null ? 1 : 0.5,
            ),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text('Rp',
                style: AppTextStyles.mono(14, color: AppColors.stone400)),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandSeparatorFormatter(),
                ],
                textAlign: TextAlign.right,
                style: AppTextStyles.mono(20,
                  color: color, weight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.mono(20, color: AppColors.stone300),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  filled: false,
                ),
              ),
            ),
          ]),
        ),
        if (parsedAmount > 0 && widget.error == null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              Rupiah.format(parsedAmount),
              style: AppTextStyles.body(11, color: AppColors.stone400),
            ),
          ),
        ],
        if (widget.error != null) ...[
          const SizedBox(height: 4),
          Text(widget.error!,
            style: AppTextStyles.body(11, color: AppColors.expense)),
        ],
      ],
    );
  }
}

class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('.', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final num = int.tryParse(digits) ?? 0;
    final formatted = num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Category Grid ─────────────────────────────────────────────────────────────

class CategoryGrid extends StatelessWidget {
  final List<TxCategoryData> categories;
  final String? selectedId;
  final ValueChanged<TxCategoryData> onSelected;
  final String? error;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori',
          style: AppTextStyles.body(13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.8,
          ),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            final isSelected = cat.id == selectedId;
            return GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                    ? cat.flutterColor.withOpacity(0.12)
                    : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected ? cat.flutterColor : AppColors.stone200,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.name,
                        style: AppTextStyles.body(11,
                          color: isSelected ? cat.flutterColor : AppColors.stone700,
                          weight: isSelected ? FontWeight.w600 : FontWeight.w400),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (cat.taxRelevant || cat.isCogs)
                        Text(
                          [if (cat.isCogs) 'HPP', if (cat.taxRelevant) 'Pajak'].join(' · '),
                          style: AppTextStyles.body(9, color: AppColors.stone400),
                        ),
                    ],
                  )),
                ]),
              ),
            );
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: AppTextStyles.body(11, color: AppColors.expense)),
        ],
      ],
    );
  }
}

// ── Payment Method Picker ─────────────────────────────────────────────────────

class PaymentMethodPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metode Pembayaran',
          style: AppTextStyles.body(13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethodData.all.map((pm) {
            final isSelected = pm.value == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(pm.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(
                    right: pm.value == PaymentMethodData.all.last.value ? 0 : 5),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.dark : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.dark : AppColors.stone200,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pm.icon,
                        style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(pm.label,
                        style: AppTextStyles.body(9,
                          color: isSelected ? Colors.white : AppColors.stone500),
                        textAlign: TextAlign.center,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}