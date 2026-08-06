// lib/screens/accounting/new_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/accounting_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/accounting/tx_form_widgets.dart';

class NewTransactionScreen extends StatefulWidget {
  final String? editId; // null = create, non-null = edit
  const NewTransactionScreen({super.key, this.editId});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  // Form state
  bool   _isIncome       = true;
  final  _amountCtrl     = TextEditingController();
  String? _selectedCatId;
  String  _paymentMethod = 'CASH';
  final  _descCtrl       = TextEditingController();
  final  _noteCtrl       = TextEditingController();
  DateTime _date         = DateTime.now();

  // Data
  List<TxCategoryData> _categories = [];
  bool   _loadingCats  = true;
  bool   _submitting   = false;
  bool   _success      = false;

  // Errors
  String? _amountError;
  String? _catError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await AccountingService.getCategories();
    setState(() { _categories = cats; _loadingCats = false; });
  }

  List<TxCategoryData> get _filteredCats =>
      _categories.where((c) => c.isIncome == _isIncome).toList();

  void _onTypeChanged(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _selectedCatId = null; // reset category on type change
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool _validate() {
    bool valid = true;
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw) ?? 0;

    setState(() {
      _amountError = amount <= 0 ? 'Nominal wajib diisi' : null;
      _catError    = _selectedCatId == null ? 'Pilih kategori' : null;
    });
    if (_amountError != null || _catError != null) valid = false;
    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);

    final raw    = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.parse(raw);
    final bizId  = await StorageService.getBusinessId() ?? 'demo-biz';

    final ok = await AccountingService.createTransaction(
      businessId:    bizId,
      date:          Tanggal.api(_date),
      type:          _isIncome ? 'INCOME' : 'EXPENSE',
      amount:        amount,
      categoryId:    _selectedCatId!,
      description:   _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      receiptNote:   _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (ok && mounted) {
      setState(() { _submitting = false; _success = true; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) context.pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose(); _descCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.editId != null ? 'Edit Transaksi' : 'Catat Transaksi'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loadingCats
        ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type toggle
                  TypeToggle(isIncome: _isIncome, onChanged: _onTypeChanged),
                  const SizedBox(height: 20),

                  // Amount
                  AmountInput(
                    controller: _amountCtrl,
                    isIncome: _isIncome,
                    error: _amountError,
                  ),
                  const SizedBox(height: 20),

                  // Category grid
                  CategoryGrid(
                    categories: _filteredCats,
                    selectedId: _selectedCatId,
                    onSelected: (cat) => setState(() => _selectedCatId = cat.id),
                    error: _catError,
                  ),
                  const SizedBox(height: 20),

                  // Date row
                  _buildSectionLabel('Tanggal'),
                  const SizedBox(height: 6),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // Payment method
                  PaymentMethodPicker(
                    selected: _paymentMethod,
                    onChanged: (v) => setState(() => _paymentMethod = v),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildSectionLabel('Keterangan (opsional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      hintText: _isIncome
                        ? 'Contoh: Penjualan baju batik ke Bu Siti'
                        : 'Contoh: Beli kain dari Pasar Tanah Abang',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),

                  // Receipt note
                  _buildSectionLabel('Catatan Nota (opsional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'No. faktur, nama supplier, atau catatan lain...',
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  Row(children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isIncome
                            ? AppColors.income : AppColors.expense,
                        ),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : Text(_isIncome
                              ? 'Simpan Pemasukan'
                              : 'Simpan Pengeluaran'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String text) => Text(text,
    style: AppTextStyles.body(13, weight: FontWeight.w500));

  Widget _buildDatePicker() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stone300, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined,
          size: 16, color: AppColors.stone400),
        const SizedBox(width: 8),
        Text(Tanggal.long(_date),
          style: AppTextStyles.body(13)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.stone300),
      ]),
    ),
  );

  Widget _buildSuccess() => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppColors.incomeLight, shape: BoxShape.circle),
          child: Icon(Icons.check_rounded,
            color: AppColors.income, size: 38),
        ),
        const SizedBox(height: 16),
        Text('Transaksi Tersimpan!',
          style: AppTextStyles.display(20)),
        const SizedBox(height: 6),
        Text('Mengarahkan ke pembukuan...',
          style: AppTextStyles.body(13, color: AppColors.stone400)),
        const SizedBox(height: 24),
        const CircularProgressIndicator(
          strokeWidth: 2, color: AppColors.brand),
      ]),
    ),
  );
}