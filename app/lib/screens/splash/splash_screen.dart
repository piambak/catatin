// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

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
      backgroundColor: AppColors.dark,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // App name
              RichText(
                text: TextSpan(
                  style: AppTextStyles.display(28, weight: FontWeight.w600, color: Colors.white),
                  children: const [
                    TextSpan(text: 'Nama'),
                    TextSpan(
                      text: 'Appmu',
                      style: TextStyle(color: AppColors.brand),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Platform Perpajakan UMKM Indonesia',
                style: AppTextStyles.body(13, color: AppColors.darkMuted),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}