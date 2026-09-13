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
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/auth/google_sign_in_button.dart';
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
  void initState() {
    super.initState();
    // Kembalian masuk dengan Google yang gagal atau dibatalkan mendarat di
    // layar ini — web saat halaman dimuat ulang, Android lewat pendengar sesi.
    _error = _takeOAuthError();
    AuthService.oauthError.addListener(_onOAuthError);
  }

  @override
  void dispose() {
    AuthService.oauthError.removeListener(_onOAuthError);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Mengambil pesan galat Google sekali saja, supaya tidak muncul lagi saat
  /// layar ini dibuka ulang.
  String? _takeOAuthError() {
    final message = AuthService.oauthError.value;
    if (message != null) AuthService.oauthError.value = null;
    return message;
  }

  void _onOAuthError() {
    final message = _takeOAuthError();
    if (message != null && mounted) setState(() => _error = message);
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

  /// Pemulihan lewat email belum ada (butuh custom SMTP, T-18). Akun yang
  /// terhubung Google tetap bisa dibuka, lalu kata sandinya diganti di
  /// Pengaturan.
  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AuthService.googleSignInAvailable
          ? 'Masuk dengan Google, lalu ganti kata sandi di Pengaturan → '
              'Cara masuk. Pemulihan lewat email belum tersedia.'
          : 'Pemulihan kata sandi belum tersedia.'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _enterDemo() async {
    // Sesi demo selalu memakai data contoh, juga di build yang tersambung
    // backend — lihat AuthService.enterDemo.
    await AuthService.enterDemo();
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
                      Text('Masuk', style: Typo.serif(32)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Belum punya akun?',
                              style: Typo.sans(13.5, color: DS.muted)),
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
                      if (AuthService.googleSignInAvailable) ...[
                        GoogleSignInButton(
                          label: 'Masuk dengan Google',
                          onError: (m) => setState(() => _error = m),
                        ),
                        const SizedBox(height: 22),
                        const DsLabeledDivider('atau masuk dengan email'),
                        const SizedBox(height: 22),
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
                            color: DS.muted, onTap: _forgotPassword),
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
                      const DsLabeledDivider('atau coba dulu'),
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
                        style: Typo.sans(12, color: DS.faint, height: 1.45),
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
            style: Typo.sans(13.5,
                weight: FontWeight.w600, color: color ?? DS.link),
          ),
        ),
      ),
    );
  }
}
