// lib/screens/auth/register_screen.dart
//
// Layar daftar, bergaya sama dengan layar masuk hasil redesain.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.register(
        name: _nameCtrl.text.trim(),
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
                      Text('Buat akun', style: Typo.serif(32)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Sudah punya akun?',
                              style: Typo.sans(13.5, color: DS.muted)),
                          const SizedBox(width: 5),
                          Semantics(
                            button: true,
                            child: InkWell(
                              onTap: () => context.go(AppRoutes.login),
                              borderRadius:
                                  BorderRadius.circular(Radii.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 4),
                                child: Text('Masuk',
                                    style: Typo.sans(13.5,
                                        weight: FontWeight.w600,
                                        color: DS.link)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (_error != null) ...[
                        DsErrorBanner(message: _error!),
                        const SizedBox(height: 18),
                      ],
                      DsField(
                        label: 'Nama lengkap',
                        controller: _nameCtrl,
                        hint: 'Nama Anda',
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 18),
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
                        textInputAction: TextInputAction.next,
                        helper: 'Minimal 6 karakter.',
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
                      const SizedBox(height: 18),
                      DsField(
                        label: 'Ulangi kata sandi',
                        controller: _confCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) => v != _passCtrl.text
                            ? 'Kata sandi tidak sama'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      DsButton(
                        label: _loading ? 'Memproses…' : 'Daftar',
                        onPressed: _loading ? null : _submit,
                        expand: true,
                        minHeight: 50,
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
