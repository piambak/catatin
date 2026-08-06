// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../services/theme_notifier.dart';

// ─── AppColors — dynamic, responds to themeNotifier instantly ────────────────
//
// All existing code using AppColors.bgPage, AppColors.stone900 etc.
// will automatically get the right color for light/dark mode
// because these are now getters, not constants.
//
// Palette:
//   FFA400 → brand (amber gold)
//   009FFD → accent (bright blue)
//   2A2A72 → dark sidebar/surface
//   232528 → dark mode background
//   EAF6FF → light surface

class AppColors {
  AppColors._();

  static bool get _dark => themeNotifier.isDark;

  // ── Brand (same in both modes) ────────────────────────────
  static const brand        = Color(0xFFFFA400);
  static const brandDark    = Color(0xFFCC8300);
  static Color get brandLight   => _dark ? const Color(0xFF232528) : const Color(0xFFFFF3CC);
  static const brandSurface = Color(0xFFFFFAF0);

  // ── Accent (same in both modes) ───────────────────────────
  static const accent       = Color(0xFF009FFD);
  static const accentDark   = Color(0xFF007ACC);
  static Color get accentLight  => _dark ? const Color(0xFF232528) : const Color(0xFFEAF6FF);

  // ── Dark sidebar (same in both modes — always dark) ───────
  static const dark         = Color(0xFF2A2A72);
  static const darkMid      = Color(0xFF3D3D8F);
  static const darkMuted    = Color(0xFF8888BB);

  // ── Semantic (universal — never changes) ──────────────────
  static const income        = Color(0xFF1B8A4B);
  static Color get incomeLight   => _dark ? const Color(0xFF232528) : const Color(0xFFE6F7EE);
  static Color get incomeBorder  => _dark ? const Color(0xFF1B8A4B) : const Color(0xFF9CDDB7);
  static Color get expenseBorder => _dark ? const Color(0xFFD92B2B) : const Color(0xFFF7C1C1);
  static const expense       = Color(0xFFD92B2B);
  static Color get expenseLight  => _dark ? const Color(0xFF232528) : const Color(0xFFFCEBEB);
  static const warning       = Color(0xFFB07D2A);
  static Color get warningLight  => _dark ? const Color(0xFF232528) : const Color(0xFFFAEEDA);
  static Color get warningBorder => _dark ? const Color(0xFFB07D2A) : const Color(0xFFFAC775);
  static const navy          = Color(0xFF009FFD);
  static Color get navyLight     => _dark ? const Color(0xFF232528) : const Color(0xFFEAF6FF);
  static Color get navyBorder    => _dark ? const Color(0xFF185FA5) : const Color(0xFFB3E0FE);

  // ── Badge foreground colors (adapt for dark mode) ──────────
  static Color get incomeBadgeFg  => _dark ? const Color(0xFF7AE8A6) : const Color(0xFF27500A);
  static Color get expenseBadgeFg => _dark ? const Color(0xFFFF9A9A) : const Color(0xFF791F1F);
  static Color get warningBadgeFg => _dark ? const Color(0xFFFFCC70) : const Color(0xFF633806);
  static Color get navyBadgeFg    => _dark ? const Color(0xFF7DCFFF) : const Color(0xFF0C447C);

  // ── Backgrounds — switch between light and dark ───────────
  static Color get bgPage      => _dark
      ? const Color(0xFF232528)
      : const Color(0xFFF4F9FF);

  static Color get bgCard      => _dark
      ? const Color(0xFF2D3035)
      : const Color(0xFFFFFFFF);

  static Color get bgSecondary => _dark
      ? const Color(0xFF363A3F)
      : const Color(0xFFEAF6FF);

  // ── Neutral text / border — switch ────────────────────────
  static Color get stone50  => _dark ? const Color(0xFF2D3035) : const Color(0xFFF4F9FF);
  static Color get stone100 => _dark ? const Color(0xFF3A3F47) : const Color(0xFFE8F2FF);
  static Color get stone200 => _dark ? const Color(0xFF454B55) : const Color(0xFFCDD8E8);
  static Color get stone300 => _dark ? const Color(0xFF5A6270) : const Color(0xFFAAB8CC);
  static Color get stone400 => _dark ? const Color(0xFF7A8494) : const Color(0xFF8898AA);
  static Color get stone500 => _dark ? const Color(0xFF9AAABB) : const Color(0xFF667788);
  static Color get stone600 => _dark ? const Color(0xFFBBCCDD) : const Color(0xFF445566);
  static Color get stone700 => _dark ? const Color(0xFFCCDDEE) : const Color(0xFF334455);
  static Color get stone800 => _dark ? const Color(0xFFDDEEFF) : const Color(0xFF1E2D3D);
  static Color get stone900 => _dark ? const Color(0xFFEAF6FF) : const Color(0xFF0D1B2A);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'DMSerif',
        fontSize:   size,
        fontWeight: weight ?? FontWeight.w400,
        color:      color ?? AppColors.stone900,
        height:     1.2,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'DMSans',
        fontSize:   size,
        fontWeight: weight ?? FontWeight.w400,
        color:      color ?? AppColors.stone700,
        height:     1.5,
      );

  static TextStyle mono(double size, {Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily:      'monospace',
        fontSize:        size,
        fontWeight:      weight ?? FontWeight.w500,
        color:           color ?? AppColors.stone900,
        letterSpacing:   -0.3,
      );

  static TextStyle label({Color? color}) => TextStyle(
        fontFamily: 'DMSans',
        fontSize:   10,
        fontWeight: FontWeight.w500,
        color:      color ?? AppColors.stone400,
        letterSpacing: 2.0,
      );
}

// ─── ThemeData ────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData _build(bool isDark) => ThemeData(
        useMaterial3: true,
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor:  AppColors.brand,
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary:    AppColors.brand,
          onPrimary:  Colors.black87,
          secondary:  AppColors.accent,
          surface:    isDark ? const Color(0xFF2D3035) : Colors.white,
          background: isDark ? const Color(0xFF232528) : const Color(0xFFF4F9FF),
          error:      AppColors.expense,
        ),
        scaffoldBackgroundColor: isDark
            ? const Color(0xFF232528)
            : const Color(0xFFF4F9FF),
        fontFamily: 'DMSans',

        appBarTheme: AppBarTheme(
          // Same background as bottom nav — white in light, dark card in dark
          backgroundColor:  isDark ? const Color(0xFF2D3035) : Colors.white,
          // Title color: blue in light, yellow/amber in dark
          foregroundColor:  isDark ? const Color(0xFFFFA400) : const Color(0xFF2A2A72),
          elevation:         0,
          surfaceTintColor:  Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: 'DMSerif',
            fontSize:   17,
            fontWeight: FontWeight.w400,
            color:      isDark ? const Color(0xFFFFA400) : const Color(0xFF2A2A72),
          ),
          iconTheme: IconThemeData(
            color: isDark ? const Color(0xFFFFA400) : const Color(0xFF2A2A72)),
          shape: Border(bottom: BorderSide(
            color: isDark
                ? const Color(0xFF454B55)
                : const Color(0xFFCDD8E8),
            width: 0.5)),
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor:      isDark ? const Color(0xFF2D3035) : Colors.white,
          selectedItemColor:     AppColors.brand,
          unselectedItemColor:   isDark
              ? const Color(0xFF7A8494)
              : const Color(0xFF8898AA),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:   const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
        ),

        cardTheme: CardThemeData(
          color:     isDark ? const Color(0xFF2D3035) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark
                  ? const Color(0xFF454B55)
                  : const Color(0xFFCDD8E8),
              width: 0.5)),
          margin: EdgeInsets.zero,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled:       true,
          fillColor:    isDark ? const Color(0xFF2D3035) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF454B55) : const Color(0xFFAAB8CC),
              width: 0.5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF454B55) : const Color(0xFFAAB8CC),
              width: 0.5)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.expense, width: 1)),
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF7A8494) : const Color(0xFF8898AA)),
          errorStyle: const TextStyle(fontSize: 11, color: AppColors.expense),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.black87,
            elevation:       0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFCCDDEE) : const Color(0xFF334455),
            side: BorderSide(
              color: isDark ? const Color(0xFF454B55) : const Color(0xFFAAB8CC),
              width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),

        dividerTheme: DividerThemeData(
          color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFCDD8E8),
          thickness: 0.5, space: 0),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? AppColors.brand : Colors.white),
          trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? AppColors.brand.withOpacity(0.4)
                : (isDark ? const Color(0xFF454B55) : const Color(0xFFAAB8CC))),
        ),

        textTheme: TextTheme(
          bodyMedium: TextStyle(
            color: isDark ? const Color(0xFFEAF6FF) : const Color(0xFF0D1B2A)),
          bodySmall: TextStyle(
            color: isDark ? const Color(0xFF9AAABB) : const Color(0xFF667788)),
        ),
      );

  static ThemeData get light => _build(false);
  static ThemeData get dark  => _build(true);
}