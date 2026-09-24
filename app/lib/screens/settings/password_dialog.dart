// lib/screens/settings/password_dialog.dart
//
// Form pasang/ganti kata sandi dari Pengaturan → Cara masuk.
//
// Tujuan utamanya menyatukan dua cara masuk dalam SATU akun: pengguna yang
// daftar lewat Google memasang kata sandi, lalu bisa masuk dengan email Google
// itu + kata sandi. Tidak ada akun kedua dan tidak ada email konfirmasi —
// alamatnya sudah diverifikasi Google.

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

/// Membuka form kata sandi. `true` kalau kata sandi tersimpan.
///
/// [hasPassword] menentukan judul dan apakah kata sandi saat ini diminta.
Future<bool> showPasswordDialog(
  BuildContext context, {
  required bool hasPassword,
  required String? email,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordDialog(hasPassword: hasPassword, email: email),
    ) ??
    false;

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.hasPassword, required this.email});

  final bool hasPassword;
  final String? email;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.setPassword(
        newPassword: _newCtrl.text,
        currentPassword: widget.hasPassword ? _currentCtrl.text : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.userMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _visibilityToggle() => IconButton(
    tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
    icon: Icon(
      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      size: 19,
      color: DS.faint,
    ),
    onPressed: () => setState(() => _obscure = !_obscure),
  );

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return Dialog(
      backgroundColor: DS.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.hasPassword ? 'Ganti kata sandi' : 'Pasang kata sandi',
                  style: Typo.serif(22),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.hasPassword
                      ? 'Kata sandi baru berlaku untuk masuk dengan email.'
                      : 'Setelah ini akun yang sama bisa dibuka dengan '
                            '${email ?? 'email Google Anda'} dan kata sandi ini, '
                            'selain dengan Google.',
                  style: Typo.sans(13.5, color: DS.body, height: 1.5),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  DsErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                if (widget.hasPassword) ...[
                  DsField(
                    label: 'Kata sandi saat ini',
                    controller: _currentCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Masukkan kata sandi saat ini'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                DsField(
                  label: 'Kata sandi baru',
                  controller: _newCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  helper: 'Minimal 6 karakter.',
                  suffix: _visibilityToggle(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                    if (v.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DsField(
                  label: 'Ulangi kata sandi baru',
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saving ? null : _save(),
                  validator: (v) =>
                      v != _newCtrl.text ? 'Kata sandi tidak sama' : null,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: Text(
                        'Batal',
                        style: Typo.sans(14, color: DS.muted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DsButton(
                      label: _saving ? 'Menyimpan…' : 'Simpan',
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
