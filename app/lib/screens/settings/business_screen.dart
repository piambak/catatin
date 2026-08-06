// lib/screens/settings/business_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/business_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_widgets.dart';

class BusinessScreen extends StatefulWidget {
  /// When [isOnboarding] is true, shows a welcome header and
  /// redirects to dashboard after save instead of popping.
  final bool isOnboarding;

  const BusinessScreen({super.key, this.isOnboarding = false});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  // ── Controllers ───────────────────────────────────────────
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _ownerCtrl    = TextEditingController();
  final _npwpCtrl     = TextEditingController();
  final _empCtrl      = TextEditingController(text: '0');

  // ── State ─────────────────────────────────────────────────
  String  _businessType = '';
  bool    _pkpStatus    = false;
  bool    _loading      = true;
  bool    _saving       = false;
  bool    _saved        = false;
  String? _existingId;

  static const _bizTypes = [
    'Perdagangan', 'Jasa', 'Manufaktur', 'Kuliner',
    'Fashion', 'Teknologi', 'Pendidikan', 'Kesehatan', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _npwpCtrl.dispose();
    _empCtrl.dispose();
    super.dispose();
  }

  // ── Load existing profile ─────────────────────────────────

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final profile = await BusinessService.getCurrent();
    if (profile != null) {
      _existingId = profile.id;
      _nameCtrl.text   = profile.businessName;
      _ownerCtrl.text  = profile.ownerName ?? '';
      _npwpCtrl.text   = profile.npwp ?? '';
      _empCtrl.text    = profile.employeeCount.toString();
      setState(() {
        _businessType = profile.businessType;
        _pkpStatus    = profile.pkpStatus;
      });
    }
    setState(() => _loading = false);
  }

  // ── Save ─────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_businessType.isEmpty) {
      _showError('Pilih jenis usaha terlebih dahulu.');
      return;
    }

    setState(() => _saving = true);
    try {
      final empCount = int.tryParse(_empCtrl.text.trim()) ?? 0;

      if (_existingId != null) {
        await BusinessService.update(
          id:            _existingId!,
          businessName:  _nameCtrl.text.trim(),
          ownerName:     _ownerCtrl.text.trim().isEmpty
              ? null : _ownerCtrl.text.trim(),
          npwp:          _npwpCtrl.text.trim().isEmpty
              ? null : _npwpCtrl.text.trim(),
          businessType:  _businessType,
          pkpStatus:     _pkpStatus,
          employeeCount: empCount,
        );
      } else {
        await BusinessService.create(
          businessName:  _nameCtrl.text.trim(),
          ownerName:     _ownerCtrl.text.trim().isEmpty
              ? null : _ownerCtrl.text.trim(),
          npwp:          _npwpCtrl.text.trim().isEmpty
              ? null : _npwpCtrl.text.trim(),
          businessType:  _businessType,
          pkpStatus:     _pkpStatus,
          employeeCount: empCount,
        );
      }

      setState(() { _saving = false; _saved = true; });
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;
      if (widget.isOnboarding) {
        context.go(AppRoutes.dashboard);
      } else {
        context.pop();
      }
    } catch (e) {
      setState(() => _saving = false);
      _showError('Gagal menyimpan. Coba lagi.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.expense,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_saved) return _buildSuccess();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    if (widget.isOnboarding) _buildOnboardingHeader(),
                    _buildBasicInfo(),
                    const SizedBox(height: 14),
                    _buildBusinessType(),
                    const SizedBox(height: 14),
                    _buildTaxInfo(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    if (widget.isOnboarding) ...[
                      const SizedBox(height: 12),
                      _buildSkipButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ── App bar ───────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.dark,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: !widget.isOnboarding,
      leading: widget.isOnboarding
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isOnboarding ? 'Setup Usaha' : 'Profil Usaha',
            style: AppTextStyles.display(17, color: Theme.of(context).appBarTheme.foregroundColor),
          ),
          Text(
            widget.isOnboarding
                ? 'Langkah terakhir sebelum mulai'
                : 'Kelola informasi usaha Anda',
            style: AppTextStyles.body(11, color: AppColors.darkMuted),
          ),
        ],
      ),
    );
  }

  // ── Onboarding welcome ────────────────────────────────────

  Widget _buildOnboardingHeader() {
    return AppCard(
      backgroundColor: AppColors.brandSurface,
      borderColor: AppColors.brand.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.business_outlined,
            color: AppColors.brand, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hampir selesai!',
              style: AppTextStyles.body(
                14, color: AppColors.brand, weight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              'Isi profil usaha agar dashboard dan simulator bisa '
              'menampilkan data yang relevan untuk bisnis kamu.',
              style: AppTextStyles.body(12, color: AppColors.stone500),
            ),
          ],
        )),
      ]),
    );
  }

  // ── Basic info (name, owner, NPWP) ───────────────────────

  Widget _buildBasicInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Dasar',
            style: AppTextStyles.display(15)),
          const SizedBox(height: 14),

          // Business name — required
          _FieldLabel(label: 'Nama Usaha', required: true),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Contoh: Toko Budi Jaya',
              prefixIcon: Icon(Icons.store_outlined, size: 18),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Nama usaha wajib diisi'
                : v.trim().length < 2
                    ? 'Nama usaha minimal 2 karakter'
                    : null,
          ),
          const SizedBox(height: 12),

          // Owner name — optional
          _FieldLabel(label: 'Nama Pemilik', required: false),
          TextFormField(
            controller: _ownerCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Contoh: Budi Santoso',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // NPWP — optional
          _FieldLabel(label: 'NPWP', required: false),
          TextFormField(
            controller: _npwpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _NpwpFormatter(),
            ],
            decoration: const InputDecoration(
              hintText: '00.000.000.0-000.000',
              prefixIcon: Icon(Icons.badge_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Business type grid ────────────────────────────────────

  Widget _buildBusinessType() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis Usaha', style: AppTextStyles.display(15)),
          const SizedBox(height: 4),
          Text(
            'Pilih yang paling sesuai dengan jenis bisnis Anda',
            style: AppTextStyles.body(12, color: AppColors.stone400),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: _bizTypes.map((type) {
              final selected = _businessType == type;
              return GestureDetector(
                onTap: () => setState(() => _businessType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.dark : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppColors.dark
                          : AppColors.stone200,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: AppTextStyles.body(
                      12,
                      color: selected ? Colors.white : AppColors.stone600,
                      weight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Tax info (PKP + employee count) ──────────────────────

  Widget _buildTaxInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Pajak', style: AppTextStyles.display(15)),
          const SizedBox(height: 14),

          // PKP status
          _FieldLabel(label: 'Status PKP', required: false),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _PkpOption(
                label: 'Bukan PKP',
                subtitle: 'Omzet ≤ Rp 4,8 M/tahun',
                selected: !_pkpStatus,
                onTap: () => setState(() => _pkpStatus = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PkpOption(
                label: 'PKP',
                subtitle: 'Wajib pungut PPN 11%',
                selected: _pkpStatus,
                onTap: () => setState(() => _pkpStatus = true),
              ),
            ),
          ]),

          if (_pkpStatus) ...[
            const SizedBox(height: 10),
            AppCard(
              backgroundColor: AppColors.warningLight,
              borderColor: AppColors.warningBorder,
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Sebagai PKP, Anda wajib memungut PPN 11% '
                  'dan menerbitkan e-Faktur untuk setiap transaksi.',
                  style: AppTextStyles.body(11, color: AppColors.warning),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 14),

          // Employee count
          _FieldLabel(label: 'Jumlah Karyawan', required: false),
          TextFormField(
            controller: _empCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: Icon(Icons.people_outline_rounded, size: 18),
              helperText:
                'Digunakan untuk kalkulasi PPh 21 di Simulator',
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0) return 'Masukkan angka yang valid';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
            : Text(
                _existingId != null
                    ? 'Simpan Perubahan'
                    : 'Simpan Profil Usaha',
              ),
      ),
    );
  }

  // ── Skip button (onboarding only) ────────────────────────

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: () async {
          await StorageService.setOnboarded();
          if (mounted) context.go(AppRoutes.dashboard);
        },
        child: Text(
          'Lewati untuk sekarang',
          style: AppTextStyles.body(
            13, color: AppColors.stone400),
        ),
      ),
    );
  }

  // ── Success state ─────────────────────────────────────────

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.incomeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
              color: AppColors.income, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isOnboarding
                ? 'Profil Usaha Tersimpan!'
                : 'Perubahan Disimpan!',
            style: AppTextStyles.display(20)),
          const SizedBox(height: 6),
          Text(
            widget.isOnboarding
                ? 'Menuju dashboard...'
                : 'Kembali ke pengaturan...',
            style: AppTextStyles.body(13, color: AppColors.stone400)),
        ]),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text(label,
          style: AppTextStyles.body(
            12, color: AppColors.stone600, weight: FontWeight.w500)),
        if (!required) ...[
          const SizedBox(width: 4),
          Text('(opsional)',
            style: AppTextStyles.body(11, color: AppColors.stone400)),
        ],
        if (required) ...[
          const SizedBox(width: 2),
          Text(' *',
            style: AppTextStyles.body(12, color: AppColors.brand)),
        ],
      ]),
    );
  }
}

class _PkpOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PkpOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.dark : AppColors.stone200,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: AppTextStyles.body(
                13,
                color: selected ? Colors.white : AppColors.stone800,
                weight: FontWeight.w600,
              )),
            const SizedBox(height: 2),
            Text(subtitle,
              style: AppTextStyles.body(
                10,
                color: selected
                    ? AppColors.stone400
                    : AppColors.stone400,
              )),
          ],
        ),
      ),
    );
  }
}

// ─── NPWP Text Formatter ─────────────────────────────────────────────────────
// Auto-formats as user types: 00.000.000.0-000.000

class _NpwpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 15 ? digits.substring(0, 15) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 1 || i == 4 || i == 7) buffer.write('.');
      if (i == 8) buffer.write('-');
      if (i == 11) buffer.write('.');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
