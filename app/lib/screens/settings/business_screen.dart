// lib/screens/settings/business_screen.dart
//
// Profil usaha bergaya sama dengan layar lain hasil redesain.
//
// Dipakai dua kali: sebagai onboarding wajib (`isOnboarding: true`) dan
// sebagai layar sunting dari Pengaturan. Keduanya dipertahankan.
//
// Mengikuti R-6 di PRD: field yang tidak selalu relevan — nama pemilik, NPWP,
// dan jumlah karyawan — disembunyikan di balik "Detail tambahan", sehingga form
// terbuka dengan tiga hal saja (nama usaha, jenis usaha, status PKP) alih-alih
// enam sekaligus. Kalau salah satunya sudah terisi, bagian itu otomatis
// terbuka, dan validasi yang gagal di dalamnya juga membukanya.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/business_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

class BusinessScreen extends StatefulWidget {
  /// Saat true, menampilkan header sambutan dan mengarahkan ke dashboard
  /// setelah simpan alih-alih menutup layar.
  final bool isOnboarding;

  const BusinessScreen({super.key, this.isOnboarding = false});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _npwpCtrl = TextEditingController();
  final _empCtrl = TextEditingController(text: '0');

  String _businessType = '';
  bool _pkpStatus = false;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  bool _showMore = false;
  String? _existingId;

  static const _bizTypes = [
    'Perdagangan',
    'Jasa',
    'Manufaktur',
    'Kuliner',
    'Fashion',
    'Teknologi',
    'Pendidikan',
    'Kesehatan',
    'Lainnya',
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

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final profile = await BusinessService.getCurrent();
    if (!mounted) return;

    if (profile != null) {
      _existingId = profile.id;
      _nameCtrl.text = profile.businessName;
      _ownerCtrl.text = profile.ownerName ?? '';
      _npwpCtrl.text = profile.npwp ?? '';
      _empCtrl.text = profile.employeeCount.toString();
      setState(() {
        _businessType = profile.businessType;
        _pkpStatus = profile.pkpStatus;
        // Kalau detail tambahan sudah pernah diisi, jangan disembunyikan.
        _showMore = (profile.npwp?.isNotEmpty ?? false) ||
            (profile.ownerName?.isNotEmpty ?? false) ||
            profile.employeeCount > 0;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      // Validasi bisa gagal di field yang sedang tersembunyi — buka dulu
      // supaya pengguna melihat pesan galatnya.
      setState(() => _showMore = true);
      return;
    }
    if (_businessType.isEmpty) {
      _showError('Pilih jenis usaha terlebih dahulu.');
      return;
    }

    setState(() => _saving = true);
    try {
      final empCount = int.tryParse(_empCtrl.text.trim()) ?? 0;
      String? orNull(TextEditingController c) =>
          c.text.trim().isEmpty ? null : c.text.trim();

      if (_existingId != null) {
        await BusinessService.update(
          id: _existingId!,
          businessName: _nameCtrl.text.trim(),
          ownerName: orNull(_ownerCtrl),
          npwp: orNull(_npwpCtrl),
          businessType: _businessType,
          pkpStatus: _pkpStatus,
          employeeCount: empCount,
        );
      } else {
        await BusinessService.create(
          businessName: _nameCtrl.text.trim(),
          ownerName: orNull(_ownerCtrl),
          npwp: orNull(_npwpCtrl),
          businessType: _businessType,
          pkpStatus: _pkpStatus,
          employeeCount: empCount,
        );
      }

      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;
      if (widget.isOnboarding) {
        context.go(AppRoutes.dashboard);
      } else {
        context.pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Gagal menyimpan. Coba lagi.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: DS.expense,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _skip() async {
    await StorageService.setOnboarded();
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    if (_saved) return const _SuccessView();

    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            if (_loading) {
              return Center(child: CircularProgressIndicator(color: DS.brand));
            }
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: Bp.pagePadding(bp), vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(bp),
                        const SizedBox(height: 30),
                        DsField(
                          label: 'Nama usaha',
                          controller: _nameCtrl,
                          hint: 'Toko Berkah Jaya',
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama usaha wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 26),
                        _businessTypePicker(),
                        const SizedBox(height: 26),
                        _pkpPicker(),
                        const SizedBox(height: 20),
                        _moreDetails(),
                        const SizedBox(height: 30),
                        DsButton(
                          label: _saving
                              ? 'Menyimpan…'
                              : widget.isOnboarding
                                  ? 'Simpan dan mulai'
                                  : 'Simpan perubahan',
                          onPressed: _saving ? null : _save,
                          expand: true,
                          minHeight: 50,
                        ),
                        if (widget.isOnboarding) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: DsButton(
                              label: 'Lewati untuk sekarang',
                              onPressed: _skip,
                              kind: DsButtonKind.ghost,
                              minHeight: 44,
                              foreground: DS.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(Breakpoint bp) {
    if (widget.isOnboarding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsWordmark(size: 26),
          const SizedBox(height: 30),
          Text('Ceritakan usaha Anda',
              style: Typo.serif(bp.isExpanded ? 32 : 27)),
          const SizedBox(height: 10),
          Text(
            'Tiga hal ini menentukan skema pajak yang berlaku untuk Anda. '
            'Semuanya bisa diubah kapan saja lewat Pengaturan.',
            style: Typo.sans(15, color: DS.body, height: 1.55),
          ),
        ],
      );
    }

    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: DS.body),
          tooltip: 'Kembali',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text('Profil usaha', style: Typo.serif(bp.isExpanded ? 32 : 25)),
        ),
      ],
    );
  }

  Widget _businessTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jenis usaha',
            style: Typo.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _bizTypes)
              _SelectableChip(
                label: type,
                selected: _businessType == type,
                onTap: () => setState(() => _businessType = type),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pkpPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status PKP',
            style: Typo.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 10),
        Row(
          children: [
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
          ],
        ),
        if (_pkpStatus) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DS.brandMuted,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: DS.brandDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sebagai PKP, Anda wajib memungut PPN 11% dan '
                    'menerbitkan e-Faktur untuk setiap transaksi.',
                    style: Typo.sans(12.5, color: DS.brandInk, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _moreDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _showMore,
          label: 'Detail tambahan',
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              borderRadius: BorderRadius.circular(Radii.sm),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text('Detail tambahan',
                        style:
                            Typo.sans(14, weight: FontWeight.w600, color: DS.ink)),
                    const SizedBox(width: 6),
                    Icon(
                      _showMore
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: DS.muted,
                    ),
                    const Spacer(),
                    if (!_showMore)
                      Text('Opsional', style: Typo.sans(12.5, color: DS.faint)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showMore) ...[
          const SizedBox(height: 10),
          DsField(
            label: 'Nama pemilik',
            controller: _ownerCtrl,
            hint: 'Sesuai KTP',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          DsField(
            label: 'NPWP',
            controller: _npwpCtrl,
            hint: '00.000.000.0-000.000',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [_NpwpFormatter()],
            helper: 'Kosongkan kalau belum punya.',
          ),
          const SizedBox(height: 20),
          DsField(
            label: 'Jumlah karyawan',
            controller: _empCtrl,
            hint: '0',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helper: 'Dipakai untuk kalkulasi PPh 21 di Simulator.',
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 0) return 'Masukkan angka yang valid';
              return null;
            },
          ),
        ],
      ],
    );
  }
}

// ── Elemen kecil ─────────────────────────────────────────────────────────────

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? DS.brandMuted : DS.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(
                  color: selected ? DS.brand : DS.border,
                  width: selected ? 1.5 : 1),
            ),
            child: Text(
              label,
              style: Typo.sans(14,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? DS.brandInk : DS.body),
            ),
          ),
        ),
      ),
    );
  }
}

class _PkpOption extends StatelessWidget {
  const _PkpOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$label. $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? DS.brandMuted : DS.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                    color: selected ? DS.brand : DS.border,
                    width: selected ? 1.5 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: Typo.sans(15,
                          weight: FontWeight.w600,
                          color: selected ? DS.brandInk : DS.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: Typo.sans(12, color: DS.muted, height: 1.35)),
                ],
              ),
            ),
          ),
        ),
      ),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: DS.brandMuted, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 30, color: DS.brandDeep),
              ),
              const SizedBox(height: 20),
              Text('Tersimpan', style: Typo.serif(26)),
              const SizedBox(height: 8),
              Text(
                'Profil usaha Anda sudah diperbarui.',
                textAlign: TextAlign.center,
                style: Typo.sans(15, color: DS.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `00.000.000.0-000.000`
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
