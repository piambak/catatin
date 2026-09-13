// lib/widgets/auth/google_sign_in_button.dart
//
// Tombol "Masuk/Daftar dengan Google" untuk layar masuk dan daftar.
//
// Menekannya meninggalkan aplikasi: di web halaman ini pindah ke Google lalu
// dimuat ulang saat kembali, di Android browser eksternal terbuka. Jadi tidak
// ada navigasi sesudah `await` — sesi diadopsi `AuthService`, dan router
// berpindah sendiri lewat `sessionChanges`.

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/services/auth_service.dart';
import '../common/ds_widgets.dart';
import '../common/google_logo.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onError,
  });

  final String label;

  /// Dipanggil dengan pesan siap tampil kalau halaman Google gagal dibuka.
  final ValueChanged<String> onError;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _opening = false;

  Future<void> _start() async {
    setState(() => _opening = true);
    try {
      await AuthService.signInWithGoogle();
    } on ApiException catch (e) {
      if (mounted) widget.onError(e.userMessage);
    } finally {
      // Di web halaman sudah ditinggalkan; di Android pengguna bisa kembali
      // tanpa menyelesaikan login, jadi tombolnya harus bisa ditekan lagi.
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => DsButton(
        label: _opening ? 'Membuka Google…' : widget.label,
        onPressed: _opening ? null : _start,
        kind: DsButtonKind.outlined,
        leading: const GoogleLogo(size: 18),
        expand: true,
        minHeight: 50,
      );
}
