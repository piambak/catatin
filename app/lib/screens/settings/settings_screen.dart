// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/business_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String?          _name;
  String?          _email;
  BusinessProfile? _business;
  bool             _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final name     = await StorageService.getUserName();
    final email    = await StorageService.getUserEmail();
    final business = await BusinessService.getCurrent();
    setState(() {
      _name     = name;
      _email    = email;
      _business = business;
      _loading  = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda akan keluar dari NamaAppmu. '
          'Data usaha tetap tersimpan dan bisa diakses kembali setelah login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          // ── Dark App Bar ───────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.dark,
            automaticallyImplyLeading: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Text('Pengaturan',
                style: AppTextStyles.display(17, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _loading ? [_buildShimmer()] : _buildContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content sections ──────────────────────────────────────

  List<Widget> _buildContent() => [
    // ── User profile card ──────────────────────────────────
    AppCard(
      child: Row(children: [
        // Avatar
        Container(
          width: 52, height: 52,
          decoration: const BoxDecoration(
            color: AppColors.brand, shape: BoxShape.circle),
          child: Center(
            child: Text(
              _name?.isNotEmpty == true
                  ? _name![0].toUpperCase() : 'U',
              style: AppTextStyles.body(
                22, weight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name ?? '—',
              style: AppTextStyles.body(
                15, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(_email ?? '—',
              style: AppTextStyles.body(
                12, color: AppColors.stone400)),
          ],
        )),
      ]),
    ),

    const SizedBox(height: 14),

    // ── Business profile card ──────────────────────────────
    AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profil Usaha', style: AppTextStyles.display(15)),
              GestureDetector(
                onTap: () async {
                  await context.push(AppRoutes.bizSetup);
                  _load();
                },
                child: Text('Edit',
                  style: AppTextStyles.body(
                    13, color: AppColors.brand,
                    weight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_business == null)
            _SetupPrompt(
              onTap: () async {
                await context.push(AppRoutes.bizSetup);
                _load();
              },
            )
          else ...[
            _BizRow(
              icon: Icons.store_outlined,
              label: 'Nama Usaha',
              value: _business!.businessName),
            if (_business!.ownerName != null)
              _BizRow(
                icon: Icons.person_outline_rounded,
                label: 'Pemilik',
                value: _business!.ownerName!),
            _BizRow(
              icon: Icons.category_outlined,
              label: 'Jenis Usaha',
              value: _business!.businessType),
            if (_business!.npwp != null)
              _BizRow(
                icon: Icons.badge_outlined,
                label: 'NPWP',
                value: _business!.npwp!),
            _BizRow(
              icon: Icons.people_outline_rounded,
              label: 'Karyawan',
              value: '${_business!.employeeCount} orang'),
            _BizRow(
              icon: Icons.receipt_long_outlined,
              label: 'Status PKP',
              value: _business!.pkpStatus ? 'PKP' : 'Non-PKP',
              valueWidget: StatusBadge(
                _business!.pkpStatus ? 'PKP' : 'Non-PKP',
                variant: _business!.pkpStatus
                    ? BadgeVariant.amber : BadgeVariant.green,
              ),
            ),
          ],
        ],
      ),
    ),

    const SizedBox(height: 14),

    // ── App info ───────────────────────────────────────────
    AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tentang Aplikasi', style: AppTextStyles.display(15)),
          const SizedBox(height: 10),
          _InfoRow(label: 'Versi Aplikasi', value: '1.0.0'),
          const Divider(height: 1),
          _InfoRow(label: 'Basis Hukum PPh Final',
            value: 'PP 23/2018'),
          const Divider(height: 1),
          _InfoRow(label: 'Basis Hukum PPh 21',
            value: 'PMK 168/2023'),
          const Divider(height: 1),
          _InfoRow(label: 'Basis Hukum PPN',
            value: 'UU HPP 2021'),
        ],
      ),
    ),

    const SizedBox(height: 24),

    // ── Logout ─────────────────────────────────────────────
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.expense,
          side: BorderSide(
            color: AppColors.expense.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Keluar dari Akun'),
      ),
    ),
  ];

  // ── Shimmer loading ───────────────────────────────────────

  Widget _buildShimmer() {
    return Column(children: [
      const ShimmerBox(width: double.infinity, height: 80, radius: 12),
      const SizedBox(height: 12),
      const ShimmerBox(width: double.infinity, height: 200, radius: 12),
    ]);
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _BizRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  const _BizRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.stone400),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: AppTextStyles.body(11, color: AppColors.stone400)),
            const SizedBox(height: 2),
            valueWidget ??
                Text(value,
                  style: AppTextStyles.body(
                    13, weight: FontWeight.w500)),
          ],
        )),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: AppTextStyles.body(13, color: AppColors.stone600)),
          Text(value,
            style: AppTextStyles.body(
              13, weight: FontWeight.w500, color: AppColors.stone800)),
        ],
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.brandSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.brand.withOpacity(0.3), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.add_business_outlined,
            color: AppColors.brand, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lengkapi profil usaha untuk mengaktifkan semua fitur.',
              style: AppTextStyles.body(12, color: AppColors.stone600),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
            color: AppColors.stone300, size: 18),
        ]),
      ),
    );
  }
}
