// lib/widgets/accounting/tx_form_widgets.dart
//
// Komponen form transaksi, digayakan ulang mengikuti mockup Claude Design.
//
// Berkas ini dipakai dua tempat sekaligus — `new_transaction_screen.dart` dan
// `tx_add_sheet.dart` — jadi menggayakan ulang di sini otomatis mengangkat
// keduanya.
//
// Kolom nominal sengaja memakai pola yang sama dengan input penghasilan di
// Simulator: garis bawah warna merek, angka besar, tanpa kotak. Satu pola
// untuk "masukkan nominal rupiah" di seluruh aplikasi.
//
// Ikon kategori dan metode bayar tetap emoji karena datang dari data
// (`cat.icon`, `pm.icon`), bukan dari kode. Menggantinya dengan ikon vektor
// perlu perubahan di sisi data — dicatat, tidak dikerjakan di sini.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/accounting_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';

// ── Pemasukan / Pengeluaran ──────────────────────────────────────────────────

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
        color: DS.sunken,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: DS.hairline),
      ),
      child: Row(
        children: [
          _TypeBtn(
            label: 'Pemasukan',
            icon: Icons.arrow_upward_rounded,
            selected: isIncome,
            accent: DS.income,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 4),
          _TypeBtn(
            label: 'Pengeluaran',
            icon: Icons.arrow_downward_rounded,
            selected: !isIncome,
            accent: DS.expense,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16, color: selected ? Colors.white : DS.faint),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: T.sans(13.5,
                          weight: FontWeight.w600,
                          color: selected ? Colors.white : DS.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nominal ──────────────────────────────────────────────────────────────────

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
    final accent = widget.isIncome ? DS.income : DS.expense;
    final raw =
        widget.controller.text.replaceAll('.', '').replaceAll(',', '');
    final parsed = double.tryParse(raw) ?? 0;
    final hasError = widget.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isIncome ? 'Jumlah pemasukan' : 'Jumlah pengeluaran',
          style: T.sans(13, weight: FontWeight.w500, color: DS.body),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: hasError ? DS.expense : DS.brand,
                width: 2,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rp', style: T.mono(18, color: DS.faint)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandSeparatorFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: T.mono(28, color: accent, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '0',
                    hintStyle: T.mono(28, color: DS.hairline),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.error!, style: T.sans(12, color: DS.expense)),
        ] else if (parsed > 0) ...[
          const SizedBox(height: 6),
          Text(Rupiah.format(parsed), style: T.sans(12, color: DS.faint)),
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
    final value = int.tryParse(digits) ?? 0;
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Kategori ─────────────────────────────────────────────────────────────────

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
            style: T.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          Text('Tidak ada kategori untuk jenis transaksi ini.',
              style: T.sans(13, color: DS.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in categories)
                _CategoryChip(
                  category: cat,
                  selected: cat.id == selectedId,
                  onTap: () => onSelected(cat),
                ),
            ],
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: T.sans(12, color: DS.expense)),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TxCategoryData category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tags = [
      if (category.isCogs) 'HPP',
      if (category.taxRelevant) 'Pajak',
    ];

    return Semantics(
      selected: selected,
      button: true,
      label: [category.name, ...tags].join(', '),
      child: ExcludeSemantics(
        child: Material(
          color: selected
              ? category.flutterColor.withValues(alpha: 0.12)
              : DS.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: selected ? category.flutterColor : DS.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: T.sans(13.5,
                            weight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? category.flutterColor
                                : DS.body,
                            height: 1.25),
                      ),
                      if (tags.isNotEmpty)
                        Text(tags.join(' · '),
                            style:
                                T.sans(10.5, color: DS.faint, height: 1.25)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metode pembayaran ────────────────────────────────────────────────────────

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
        Text('Metode pembayaran',
            style: T.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pm in PaymentMethodData.all)
              _PaymentChip(
                icon: pm.icon,
                label: pm.label,
                selected: pm.value == selected,
                onTap: () => onChanged(pm.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? DS.brandMuted : DS.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: selected ? DS.brand : DS.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: T.sans(13.5,
                        weight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? DS.brandInk : DS.body),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
