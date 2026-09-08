// lib/screens/accounting/new_transaction_screen.dart
//
// Catat transaksi — digayakan ulang mengikuti mockup Claude Design.
//
// Ini rute halaman penuh (`/accounting/new`), bukan bottom sheet. Sesuai R-5
// di PRD: satu tugas, satu lapisan modal. Pemilih tanggal tetap dialog bawaan
// karena itu satu-satunya modal di alur ini.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/accounting_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/accounting/tx_form_widgets.dart';
import '../../widgets/common/ds_widgets.dart';

class NewTransactionScreen extends StatefulWidget {
  final String? editId; // null = buat baru, non-null = sunting
  const NewTransactionScreen({super.key, this.editId});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  bool _isIncome = true;
  final _amountCtrl = TextEditingController();
  String? _selectedCatId;
  String _paymentMethod = 'CASH';
  final _descCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  List<TxCategoryData> _categories = [];
  bool _loadingCats = true;
  bool _submitting = false;
  bool _success = false;

  String? _amountError;
  String? _catError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await AccountingService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loadingCats = false;
    });
  }

  List<TxCategoryData> get _filteredCats =>
      _categories.where((c) => c.isIncome == _isIncome).toList();

  void _onTypeChanged(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _selectedCatId = null; // kategori direset saat jenis berubah
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
          colorScheme: ColorScheme.fromSeed(
            seedColor: DS.brand,
            brightness: Theme.of(context).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  bool _validate() {
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.tryParse(raw) ?? 0;

    setState(() {
      _amountError = amount <= 0 ? 'Nominal wajib diisi' : null;
      _catError = _selectedCatId == null ? 'Pilih kategori' : null;
    });
    return _amountError == null && _catError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _submitting = true);

    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    final amount = double.parse(raw);
    final bizId = await StorageService.getBusinessId() ?? 'demo-biz';

    final ok = await AccountingService.createTransaction(
      businessId: bizId,
      date: Tanggal.api(_date),
      type: _isIncome ? 'INCOME' : 'EXPENSE',
      amount: amount,
      categoryId: _selectedCatId!,
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      receiptNote:
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Gagal menyimpan transaksi. Coba lagi.'),
        backgroundColor: DS.expense,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() {
      _submitting = false;
      _success = true;
    });
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return const _SuccessView();

    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            if (_loadingCats) {
              return Center(child: CircularProgressIndicator(color: DS.brand));
            }
            final pad = Bp.pagePadding(bp);
            return Column(
              children: [
                _header(pad, bp),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(pad, 22, pad, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TypeToggle(
                                isIncome: _isIncome, onChanged: _onTypeChanged),
                            const SizedBox(height: 26),
                            AmountInput(
                              controller: _amountCtrl,
                              isIncome: _isIncome,
                              error: _amountError,
                            ),
                            const SizedBox(height: 26),
                            CategoryGrid(
                              categories: _filteredCats,
                              selectedId: _selectedCatId,
                              onSelected: (cat) =>
                                  setState(() => _selectedCatId = cat.id),
                              error: _catError,
                            ),
                            const SizedBox(height: 26),
                            _dateField(),
                            const SizedBox(height: 26),
                            PaymentMethodPicker(
                              selected: _paymentMethod,
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v),
                            ),
                            const SizedBox(height: 26),
                            DsField(
                              label: 'Keterangan (opsional)',
                              controller: _descCtrl,
                              hint: _isIncome
                                  ? 'Penjualan baju batik ke Bu Siti'
                                  : 'Beli kain dari Pasar Tanah Abang',
                            ),
                            const SizedBox(height: 20),
                            DsField(
                              label: 'Catatan nota (opsional)',
                              controller: _noteCtrl,
                              hint: 'No. faktur, nama supplier, catatan lain',
                            ),
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                DsButton(
                                  label: 'Batal',
                                  onPressed: () => context.pop(),
                                  kind: DsButtonKind.outlined,
                                  minHeight: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DsButton(
                                    label: _submitting
                                        ? 'Menyimpan…'
                                        : _isIncome
                                            ? 'Simpan pemasukan'
                                            : 'Simpan pengeluaran',
                                    onPressed: _submitting ? null : _submit,
                                    expand: true,
                                    minHeight: 50,
                                    background:
                                        _isIncome ? DS.income : DS.expense,
                                    foreground: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(double pad, Breakpoint bp) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad - 8, 12, pad, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_rounded, color: DS.body),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.editId != null ? 'Sunting transaksi' : 'Catat transaksi',
              style: T.serif(bp.isExpanded ? 30 : 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal',
            style: T.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: 'Tanggal transaksi',
          value: Tanggal.long(_date),
          child: ExcludeSemantics(
            child: Material(
              color: DS.surface,
              borderRadius: BorderRadius.circular(Radii.sm),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: DS.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 17, color: DS.faint),
                      const SizedBox(width: 10),
                      Text(Tanggal.long(_date),
                          style: T.sans(15, color: DS.ink)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: DS.faint),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: DS.income.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: DS.income, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Transaksi tersimpan', style: T.serif(24)),
            const SizedBox(height: 8),
            Text('Mengarahkan kembali ke Pencatatan…',
                style: T.sans(14, color: DS.muted)),
          ],
        ),
      ),
    );
  }
}
