// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.login(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Logo
              RichText(
                text: TextSpan(
                  style: AppTextStyles.display(26, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor),
                  children: [
                    TextSpan(text: 'Nama'),
                    TextSpan(text: 'Appmu', style: TextStyle(color: AppColors.brand)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Masuk', style: AppTextStyles.display(28)),
              const SizedBox(height: 6),
              Row(children: [
                Text('Belum punya akun?', style: AppTextStyles.body(13, color: AppColors.stone500)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.register),
                  child: Text('Daftar gratis',
                    style: AppTextStyles.body(13, color: AppColors.brand, weight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 28),

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.expense.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.expense, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: AppTextStyles.body(12, color: AppColors.expense))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(children: [
                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Lupa password?', style: AppTextStyles.body(12, color: AppColors.stone500)),
                    ),
                  ),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Masuk'),
                    ),
                  ),
                ]),
              ),
                  // ─────────────────────────────────────────────────────────
                  // DEMO MODE — hapus sebelum production
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau coba dulu',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8A7860))),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6A5840),
                        side: const BorderSide(color: Color(0xFFD0C8B8), width: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
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
                        if (context.mounted) context.go(AppRoutes.dashboard);
                      },
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                      label: const Text('Masuk sebagai Demo User'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}