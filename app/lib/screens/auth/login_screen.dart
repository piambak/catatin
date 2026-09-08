// lib/screens/auth/login_screen.dart
//
// Layar masuk bergaya sama dengan Dashboard dan Simulator hasil redesain.
//
// Wordmark sebelumnya masih "NamaAppmu" — sisa scaffold yang tidak pernah
// diganti, padahal ini layar pertama yang dilihat siapa pun yang membuka
// aplikasi. Sekarang memakai wordmark Catatin yang sama dengan rail navigasi.
//
// Di layar lebar form dibatasi ~420px dan ditengahkan; sebelumnya membentang
// selebar layar (PRD bagian 6, "Auth").

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enterDemo() async {
    await StorageService.saveTokens(
      accessToken: 'demo-token',
      refreshToken: 'demo-refresh',
    );
    await StorageService.saveUserInfo(
      id: 'demo-user-001',
      name: 'Budi Santoso',
      email: 'budi@tokoanda.com',
    );
    await StorageService.setOnboarded();
    if (!mounted) return;
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) => Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: Bp.pagePadding(bp), vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DsWordmark(size: 28),
                      const SizedBox(height: 36),
                      Text('Masuk', style: T.serif(32)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Belum punya akun?',
                              style: T.sans(13.5, color: DS.muted)),
                          const SizedBox(width: 5),
                          _InlineLink(
                            'Daftar gratis',
                            onTap: () => context.go(AppRoutes.register),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        DsErrorBanner(message: _error!),
                        const SizedBox(height: 18),
                      ],
                      DsField(
                        label: 'Email',
                        controller: _emailCtrl,
                        hint: 'nama@usaha.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email wajib diisi';
                          if (!v.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      DsField(
                        label: 'Kata sandi',
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        suffix: IconButton(
                          tooltip: _obscure
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                            color: DS.faint,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Kata sandi wajib diisi';
                          }
                          if (v.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _InlineLink('Lupa kata sandi?',
                            color: DS.muted, onTap: () {}),
                      ),
                      const SizedBox(height: 18),
                      DsButton(
                        label: _loading ? 'Memproses…' : 'Masuk',
                        onPressed: _loading ? null : _submit,
                        expand: true,
                        minHeight: 50,
                      ),
                      const SizedBox(height: 26),
                      // ── Mode demo — hapus sebelum produksi ────────────────
                      Row(
                        children: [
                          Expanded(child: Divider(color: DS.hairline)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('atau coba dulu',
                                style: T.sans(12, color: DS.faint)),
                          ),
                          Expanded(child: Divider(color: DS.hairline)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DsButton(
                        label: 'Masuk sebagai pengguna demo',
                        onPressed: _enterDemo,
                        kind: DsButtonKind.outlined,
                        expand: true,
                        minHeight: 48,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mode demo memakai data contoh. Tidak ada koneksi ke '
                        'server dan tidak ada data asli yang tersimpan.',
                        style: T.sans(12, color: DS.faint, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineLink extends StatelessWidget {
  const _InlineLink(this.label, {required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Text(
            label,
            style: T.sans(13.5,
                weight: FontWeight.w600, color: color ?? DS.link),
          ),
        ),
      ),
    );
  }
}
