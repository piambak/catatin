// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/network/app_router.dart';
import 'core/network/supabase_client.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sumber data ditentukan --dart-define; tanpa API_BASE_URL aplikasi jalan
  // sepenuhnya dengan data contoh. Lihat core/config/app_config.dart.
  if (kDebugMode) {
    debugPrint('[Catatin] ${AppConfig.summary}');
    final problem = AppConfig.configError;
    if (problem != null) debugPrint('[Catatin] $problem');
  }

  // D-16: potret hanya dikunci di ponsel. Web dan tablet bebas berputar —
  // di layar lebar, tata letak rail + konten memang dirancang mendatar.
  if (!kIsWeb && _isPhone()) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await initializeDateFormatting('id_ID', null);

  // Backend dan sesi siap sebelum frame pertama: klien Supabase wajib
  // terinisialisasi sebelum repository pertama dibuat, dan penjaga rute
  // langsung membaca status masuk yang sudah dibersihkan dari sisa sesi lama.
  // Dijalankan sebelum tema supaya tema dibaca dari penyimpanan yang sudah
  // dibersihkan (pembersihan sesi mempertahankan tema — lihat
  // StorageService.clearSession).
  if (AppConfig.dataSource == DataSource.supabase) {
    await SupabaseBackend.init();
  }
  await AuthService.restoreSession();

  // Load saved theme preference before first frame
  await themeNotifier.init();

  runApp(const MyApp());
}

/// Ponsel = sisi terpendek layar di bawah 600 dp, ambang tablet yang dipakai
/// Material. Dibaca dari view pertama karena belum ada `MediaQuery` sebelum
/// `runApp`. Ukuran yang belum diketahui (0) dianggap ponsel: perilakunya sama
/// dengan sebelum D-16, bukan membuka kunci tanpa alasan.
bool _isPhone() {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return true;
  final view = views.first;
  if (view.devicePixelRatio <= 0) return true;
  final logical = view.physicalSize / view.devicePixelRatio;
  return logical.shortestSide < 600;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        // Update status bar icons to match theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: isDark
                ? const Color(0xFF2D3035)
                : Colors.white,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
        );

        return MaterialApp.router(
          title: 'Catatin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
