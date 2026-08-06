// lib/widgets/accounting/tx_add_sheet.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/accounting_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// ─── Prefill data ────────────────────────────────────────────────────────────

class TxPrefill {
  final String?   type;
  final double?   amount;
  final String?   description;
  final DateTime? date;
  final String?   paymentMethod;

  const TxPrefill({
    this.type, this.amount, this.description,
    this.date, this.paymentMethod,
  });
}

class TxAddSheet extends StatefulWidget {
  final void Function(TxData) onSaved;
  final TxPrefill? prefill;
  const TxAddSheet({super.key, required this.onSaved, this.prefill});

  @override
  State<TxAddSheet> createState() => _TxAddSheetState();
}

class _TxAddSheetState extends State<TxAddSheet> {
  bool   _isIncome = true;
  String _type     = 'INCOME';

  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  DateTime _date    = DateTime.now();
  TxCategoryData? _category;
  String _payMethod = 'CASH';
  bool _saving      = false;

  // Kategori datang dari lapisan data (mock atau backend), bukan konstanta.
  List<TxCategoryData> _allCats = [];

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      if (p.type != null) {
        _type     = p.type!;
        _isIncome = _type == 'INCOME';
      }
      if (p.amount      != null) _amountCtrl.text = p.amount!.toStringAsFixed(0);
      if (p.description != null) _descCtrl.text   = p.description!;
      if (p.date        != null) _date             = p.date!;
      if (p.paymentMethod != null) _payMethod      = p.paymentMethod!;
    }
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    final cats = await AccountingService.getCategories();
    if (!mounted) return;
    setState(() => _allCats = cats);
  }

  List<TxCategoryData> get _cats =>
    _allCats.where((c) => c.type == _type).toList();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context:     context,
      initialDate: _date,
      firstDate:   DateTime(2020),
      lastDate:    DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final rawAmt = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Masukkan nominal yang valid'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih kategori transaksi'),
        behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);
    try {
      await AccountingService.createTransaction(
        businessId:    'b1',
        type:          _type,
        amount:        amount,
        categoryId:    _category!.id,
        description:   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date:          _date.toIso8601String().substring(0, 10),
        paymentMethod: _payMethod,
      );
      // Build a local TxData for immediate UI update
      final tx = TxData(
        id:            DateTime.now().millisecondsSinceEpoch.toString(),
        businessId:    'b1',
        date:          _date,
        type:          _type,
        amount:        amount,
        category:      _category!,
        description:   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        paymentMethod: _payMethod,
        createdAt:     DateTime.now(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved(tx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi berhasil disimpan'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan. Coba lagi.'),
          behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bot),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.stone200,
              borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(children: [
              Text('Catat Transaksi', style: AppTextStyles.display(16)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.stone500))),
            ]),
          ),

          // Type toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.stone100,
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _TypeBtn(label: 'Pemasukan',  active: _isIncome, color: AppColors.income,
                  onTap: () => setState(() { _isIncome = true;  _type = 'INCOME';  _category = null; })),
                _TypeBtn(label: 'Pengeluaran',active: !_isIncome,color: AppColors.expense,
                  onTap: () => setState(() { _isIncome = false; _type = 'EXPENSE'; _category = null; })),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Form fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              // Amount
              _SheetField(
                label: 'Nominal',
                prefix: 'Rp',
                hint: '0',
                controller: _amountCtrl,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
              const SizedBox(height: 10),

              // Date + pay method
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: _SheetDisplay(
                      label: 'Tanggal',
                      value: Tanggal.short(_date)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetDropdown<String>(
                    label: 'Metode Bayar',
                    value: _payMethod,
                    items: [
                      _DdItem('CASH','Tunai'), _DdItem('TRANSFER','Transfer'),
                      _DdItem('QRIS','QRIS'),  _DdItem('DEBIT','Kartu Debit'),
                    ],
                    onChanged: (v) => setState(() => _payMethod = v),
                  ),
                ),
              ]),
              const SizedBox(height: 10),

              // Category
              _SheetDropdown<TxCategoryData>(
                label: 'Kategori',
                value: _category,
                items: _cats.map((c) => _DdItem(c, '${c.icon} ${c.name}')).toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 10),

              // Description
              _SheetField(
                label: 'Keterangan (opsional)',
                hint: 'Contoh: Penjualan produk online',
                controller: _descCtrl),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                  child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : Text('Simpan Transaksi',
                        style: AppTextStyles.body(14,
                          weight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final Color  color;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.active,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: double.infinity,
        decoration: BoxDecoration(
          color: active ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: active ? Border.all(color: color.withOpacity(0.3)) : null),
        child: Center(child: Text(label,
          style: AppTextStyles.body(13,
            color: active ? color : AppColors.stone400,
            weight: active ? FontWeight.w600 : FontWeight.w400))),
      ),
    ),
  );
}

class _SheetField extends StatelessWidget {
  final String label, hint;
  final String? prefix;
  final TextEditingController? controller;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;

  const _SheetField({
    required this.label, this.hint = '', this.prefix,
    this.controller, this.keyboard, this.formatters,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.body(11, color: AppColors.stone400)),
      const SizedBox(height: 4),
      Container(
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.stone200, width: 0.5)),
        child: Row(children: [
          if (prefix != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(prefix!,
                style: AppTextStyles.body(13, color: AppColors.stone400))),
            Container(width: 0.5, height: 20, color: AppColors.stone200),
          ],
          Expanded(child: TextField(
            controller: controller,
            keyboardType: keyboard,
            inputFormatters: formatters,
            style: AppTextStyles.body(13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body(13, color: AppColors.stone300),
              border: InputBorder.none, isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 11)),
          )),
        ]),
      ),
    ],
  );
}

class _SheetDisplay extends StatelessWidget {
  final String label, value;
  const _SheetDisplay({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.body(11, color: AppColors.stone400)),
      const SizedBox(height: 4),
      Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.stone200, width: 0.5)),
        child: Row(children: [
          Expanded(child: Text(value, style: AppTextStyles.body(13))),
          Icon(Icons.calendar_today_outlined,
            size: 14, color: AppColors.stone400),
        ]),
      ),
    ],
  );
}

// Dropdown item helper — avoids Dart record syntax
class _DdItem<T> {
  final T    value;
  final String label;
  const _DdItem(this.value, this.label);
}

class _SheetDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<_DdItem<T>> items;
  final ValueChanged<T> onChanged;

  const _SheetDropdown({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  State<_SheetDropdown<T>> createState() => _SheetDropdownState<T>();
}

class _SheetDropdownState<T> extends State<_SheetDropdown<T>> {
  final _link  = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    _overlay = OverlayEntry(builder: (_) => Stack(children: [
      // Barrier to close on outside tap
      Positioned.fill(child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand())),
      // Dropdown list anchored below the field
      CompositedTransformFollower(
        link:       _link,
        showWhenUnlinked: false,
        offset:     Offset(0, size.height),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.stone200, width: .5),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, 4))]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                children: widget.items.map((item) {
                  final selected = widget.value == item.value;
                  return InkWell(
                    onTap: () {
                      widget.onChanged(item.value);
                      _close();
                    },
                    hoverColor: AppColors.brand.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                      color: selected
                        ? AppColors.brand.withOpacity(0.07)
                        : Colors.transparent,
                      child: Row(children: [
                        Expanded(child: Text(item.label,
                          style: AppTextStyles.body(13,
                            color: selected
                              ? AppColors.brand
                              : AppColors.stone700,
                            weight: selected
                              ? FontWeight.w500 : FontWeight.w400))),
                        if (selected)
                          Icon(Icons.check_rounded,
                            size: 15, color: AppColors.brand),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    ]));

    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() { _close(); super.dispose(); }

  String get _displayText {
    if (widget.value == null) return '';
    final match = widget.items.where((i) => i.value == widget.value);
    return match.isEmpty ? '' : match.first.label;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label,
        style: AppTextStyles.body(11, color: AppColors.stone400)),
      const SizedBox(height: 4),
      CompositedTransformTarget(
        link: _link,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _open ? AppColors.brand : AppColors.stone200,
                width: _open ? 1.0 : 0.5)),
            child: Row(children: [
              Expanded(child: Text(
                widget.value != null ? _displayText : 'Pilih...',
                style: AppTextStyles.body(13,
                  color: widget.value != null
                    ? AppColors.stone700 : AppColors.stone300),
                overflow: TextOverflow.ellipsis)),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.stone400)),
            ]),
          ),
        ),
      ),
    ],
  );
}

// ─── TxEditSheet — pre-filled edit form ──────────────────────────────────────

class TxEditSheet extends StatefulWidget {
  final TxData tx;
  const TxEditSheet({super.key, required this.tx});

  @override
  State<TxEditSheet> createState() => _TxEditSheetState();
}

class _TxEditSheetState extends State<TxEditSheet> {
  late bool   _isIncome;
  late String _type;

  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late DateTime        _date;
  late TxCategoryData? _category;
  late String          _payMethod;
  bool _saving = false;

  // Kategori datang dari lapisan data (mock atau backend), bukan konstanta.
  List<TxCategoryData> _allCats = [];

  @override
  void initState() {
    super.initState();
    _isIncome = widget.tx.isIncome;
    _type     = widget.tx.type;
    _date     = widget.tx.date;
    _payMethod= widget.tx.paymentMethod;
    _amountCtrl = TextEditingController(
      text: widget.tx.amount.toStringAsFixed(0));
    _descCtrl   = TextEditingController(
      text: widget.tx.description ?? '');
    // Kategori transaksi sudah ikut di payload, jadi bisa langsung dipakai
    // sambil menunggu daftar lengkap datang dari lapisan data.
    _category = widget.tx.category;
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    final cats = await AccountingService.getCategories();
    if (!mounted) return;
    setState(() {
      _allCats  = cats;
      _category = cats.firstWhere(
        (c) => c.id == widget.tx.category.id,
        orElse: () => widget.tx.category,
      );
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<TxCategoryData> get _cats =>
    _allCats.where((c) => c.type == _type).toList();

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final rawAmt = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmt);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Masukkan nominal yang valid'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pilih kategori transaksi'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      // In real app: call AccountingService.updateTransaction(...)
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan. Coba lagi.'),
          behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Row(children: [
            Text('Edit Transaksi', style: AppTextStyles.display(16)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.stone100, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded,
                  size: 16, color: AppColors.stone500))),
          ]),
          const SizedBox(height: 14),

          // Type toggle
          Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.stone100,
              borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _TypeBtn(label: 'Pemasukan', active: _isIncome,
                color: AppColors.income,
                onTap: () => setState(() {
                  _isIncome = true; _type = 'INCOME'; _category = null;
                })),
              _TypeBtn(label: 'Pengeluaran', active: !_isIncome,
                color: AppColors.expense,
                onTap: () => setState(() {
                  _isIncome = false; _type = 'EXPENSE'; _category = null;
                })),
            ]),
          ),
          const SizedBox(height: 10),

          // Amount
          _SheetField(
            label: 'Nominal', prefix: 'Rp', hint: '0',
            controller: _amountCtrl,
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]),
          const SizedBox(height: 10),

          // Date + pay method
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: _pickDate,
              child: _SheetDisplay(
                label: 'Tanggal',
                value: Tanggal.short(_date)))),
            const SizedBox(width: 10),
            Expanded(child: _SheetDropdown<String>(
              label: 'Metode Bayar',
              value: _payMethod,
              items: [
                _DdItem('CASH','Tunai'), _DdItem('TRANSFER','Transfer'),
                _DdItem('QRIS','QRIS'), _DdItem('DEBIT','Kartu Debit'),
              ],
              onChanged: (v) => setState(() => _payMethod = v))),
          ]),
          const SizedBox(height: 10),

          // Category
          _SheetDropdown<TxCategoryData>(
            label: 'Kategori',
            value: _category,
            items: _cats.map((c) => _DdItem(c, '${c.icon} ${c.name}')).toList(),
            onChanged: (v) => setState(() => _category = v)),
          const SizedBox(height: 10),

          // Description
          _SheetField(
            label: 'Keterangan (opsional)',
            hint: 'Contoh: Penjualan produk online',
            controller: _descCtrl),
          const SizedBox(height: 16),

          // Save
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
              child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : Text('Simpan Perubahan',
                    style: AppTextStyles.body(14,
                      weight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
