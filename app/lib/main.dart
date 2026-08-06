// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/network/app_router.dart';
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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('id_ID', null);

  // Load saved theme preference before first frame
  await themeNotifier.init();

  runApp(const MyApp());
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
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor:            Colors.transparent,
          statusBarIconBrightness:   isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:  isDark
              ? const Color(0xFF2D3035)
              : Colors.white,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp.router(
          title:                    'Catatin',
          debugShowCheckedModeBanner: false,
          theme:      AppTheme.light,
          darkTheme:  AppTheme.dark,
          themeMode:  themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}