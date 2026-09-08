// lib/screens/settings/settings_screen.dart
//
// Pengaturan bergaya sama dengan Dashboard dan Simulator hasil redesain.
//
// Di layar lebar jadi dua panel (daftar bagian di kiri, isinya di kanan)
// seperti arahan brief; di ponsel tetap satu kolom bergulir.
//
// Sakelar mode gelap BARU ditambahkan di sini. Sebelumnya `themeNotifier`
// hanya dibaca — tidak ada satu pun tempat di UI yang memanggil `toggle()`
// atau `setDark()`, jadi mode gelap yang dijanjikan README sebenarnya tidak
// bisa dinyalakan pengguna.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/business_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/theme_notifier.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _name;
  String? _email;
  BusinessProfile? _business;
  bool _loading = true;

  /// Bagian yang sedang dipilih di panel kiri (hanya dipakai di layar lebar).
  int _section = 0;

  static const _sections = ['Profil usaha', 'Tampilan', 'Tentang', 'Akun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final name = await StorageService.getUserName();
    final email = await StorageService.getUserEmail();
    final business = await BusinessService.getCurrent();
    if (!mounted) return;
    setState(() {
      _name = name;
      _email = email;
      _business = business;
      _loading = false;
    });
  }

  Future<void> _editBusiness() async {
    await context.push(AppRoutes.bizSetup);
    if (mounted) await _load();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.lg)),
        title: Text('Keluar dari akun?', style: Typo.serif(20)),
        content: Text(
          'Anda perlu masuk lagi untuk melihat catatan dan simulasi pajak.',
          style: Typo.sans(14, color: DS.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: Typo.sans(14, color: DS.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ya, keluar',
                style: Typo.sans(14, weight: FontWeight.w600, color: DS.expense)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await AuthService.logout();
    // Cek ulang sesudah await — widget bisa saja sudah dilepas selama logout.
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            if (_loading) return const _SettingsSkeleton();
            return bp.isExpanded ? _wide(bp) : _narrow(bp);
          },
        ),
      ),
    );
  }

  // ── Sempit: satu kolom ────────────────────────────────────────────────────

  Widget _narrow(Breakpoint bp) {
    final pad = Bp.pagePadding(bp);
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 32 + Bp.bottomInset(bp)),
      children: [
        Text('Pengaturan', style: Typo.serif(25)),
        const SizedBox(height: 24),
        _identity(),
        const SizedBox(height: 30),
        _businessSection(),
        const SizedBox(height: 26),
        _appearanceSection(),
        const SizedBox(height: 26),
        _aboutSection(),
        const SizedBox(height: 30),
        _logoutButton(),
      ],
    );
  }

  // ── Lebar: dua panel ──────────────────────────────────────────────────────

  Widget _wide(Breakpoint bp) {
    final pad = Bp.pagePadding(bp);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Bp.contentMax),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 34, pad, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pengaturan', style: Typo.serif(34)),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 240, child: _sectionList()),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: 30),
                        decoration: BoxDecoration(
                          border:
                              Border(left: BorderSide(color: DS.hairline)),
                        ),
                        child: SingleChildScrollView(
                          child: switch (_section) {
                            0 => _businessSection(topBorder: false),
                            1 => _appearanceSection(topBorder: false),
                            2 => _aboutSection(topBorder: false),
                            _ => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _identity(),
                                  const SizedBox(height: 30),
                                  _logoutButton(),
                                ],
                              ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionList() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Semantics(
                selected: _section == i,
                button: true,
                child: Material(
                  color: _section == i ? DS.sunken : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: InkWell(
                    onTap: () => setState(() => _section = i),
                    borderRadius: BorderRadius.circular(Radii.pill),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _sections[i],
                        style: Typo.sans(14.5,
                            weight: _section == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _section == i ? DS.ink : DS.body),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  // ── Bagian-bagian ─────────────────────────────────────────────────────────

  Widget _identity() {
    final initial =
        (_name?.trim().isNotEmpty ?? false) ? _name!.trim()[0].toUpperCase() : 'U';
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: DS.wordmark, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initial,
              style: Typo.sans(20, weight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_name ?? '—',
                  style: Typo.sans(16, weight: FontWeight.w600, color: DS.ink)),
              const SizedBox(height: 2),
              Text(_email ?? '—', style: Typo.sans(13, color: DS.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _businessSection({bool topBorder = true}) {
    final b = _business;
    return DsSection(
      label: 'Profil usaha',
      topBorder: topBorder,
      action: _EditLink(onTap: _editBusiness),
      child: b == null
          ? _SetupPrompt(onTap: _editBusiness)
          : Column(
              children: [
                DsListRow(title: 'Nama usaha', trailing: b.businessName),
                if (b.ownerName != null)
                  DsListRow(title: 'Pemilik', trailing: b.ownerName!),
                DsListRow(title: 'Jenis usaha', trailing: b.businessType),
                if (b.npwp != null) DsListRow(title: 'NPWP', trailing: b.npwp!),
                DsListRow(
                    title: 'Karyawan',
                    trailing: '${b.employeeCount} orang'),
                DsListRow(
                  title: 'Status PKP',
                  trailing: b.pkpStatus ? 'PKP' : 'Non-PKP',
                  trailingStyle: Typo.sans(14,
                      weight: FontWeight.w600,
                      color: b.pkpStatus ? DS.brandDeep : DS.income),
                  showDivider: false,
                ),
              ],
            ),
    );
  }

  Widget _appearanceSection({bool topBorder = true}) {
    return DsSection(
      label: 'Tampilan',
      topBorder: topBorder,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, _) {
          final dark = mode == ThemeMode.dark;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mode gelap',
                        style: Typo.sans(15, color: DS.body, height: 1.3)),
                    const SizedBox(height: 2),
                    Text(
                      dark
                          ? 'Sedang aktif — berlaku di seluruh aplikasi.'
                          : 'Nyalakan untuk tampilan gelap di seluruh aplikasi.',
                      style: Typo.sans(12.5, color: DS.faint, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: 'Mode gelap',
                toggled: dark,
                child: Switch(
                  value: dark,
                  activeThumbColor: DS.brand,
                  onChanged: (v) => themeNotifier.setDark(v),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _aboutSection({bool topBorder = true}) {
    return DsSection(
      label: 'Tentang',
      topBorder: topBorder,
      child: Column(
        children: const [
          DsListRow(title: 'Versi aplikasi', trailing: '1.0.0'),
          DsListRow(title: 'Basis hukum PPh Final', trailing: 'PP 23/2018'),
          DsListRow(title: 'Basis hukum PPh 21', trailing: 'PMK 168/2023'),
          DsListRow(
              title: 'Basis hukum PPN',
              trailing: 'UU HPP 2021',
              showDivider: false),
        ],
      ),
    );
  }

  Widget _logoutButton() => DsButton(
        label: 'Keluar dari akun',
        onPressed: _logout,
        kind: DsButtonKind.outlined,
        expand: true,
        minHeight: 50,
        foreground: DS.expense,
      );
}

// ── Elemen kecil ─────────────────────────────────────────────────────────────

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text('Ubah',
                style:
                    Typo.sans(13.5, weight: FontWeight.w500, color: DS.link)),
          ),
        ),
      );
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil usaha belum diisi. Simulator memakai data ini untuk '
          'menentukan skema pajak yang berlaku.',
          style: Typo.sans(14, color: DS.body, height: 1.5),
        ),
        const SizedBox(height: 14),
        DsButton(label: 'Isi profil usaha', onPressed: onTap),
      ],
    );
  }
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: DS.hairline,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(180, 28),
          const SizedBox(height: 20),
          bar(double.infinity, 52),
          const SizedBox(height: 20),
          bar(120, 12),
          bar(double.infinity, 140),
        ],
      ),
    );
  }
}
