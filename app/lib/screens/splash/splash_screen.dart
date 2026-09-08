// lib/screens/splash/splash_screen.dart
//
// Layar pembuka — digayakan ulang mengikuti mockup Claude Design.
//
// Wordmark di sini masih tertulis "NamaAppmu", dipecah jadi dua TextSpan
// ('Nama' + 'Appmu') sehingga pencarian teks utuh tidak menemukannya. Sekarang
// memakai `DsWordmark` yang sama dengan rail navigasi dan layar masuk.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;
    context.go(isLoggedIn ? AppRoutes.dashboard : AppRoutes.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.surface,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const DsWordmark(size: 38),
              const SizedBox(height: 12),
              Text(
                'Catat transaksi, hitung pajak, pahami aturan.',
                textAlign: TextAlign.center,
                style: Typo.sans(14, color: DS.muted),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DS.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
