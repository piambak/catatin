// lib/core/services/theme_notifier.dart
//
// Simple ValueNotifier-based theme manager.
// Persists preference in SharedPreferences.
// Used by main.dart to drive MaterialApp.router themeMode.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.light);

  // ── Init — load saved preference ──────────────────────────
  Future<void> init() async {
    final prefs  = await SharedPreferences.getInstance();
    final saved  = prefs.getString(_key);
    value = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Toggle ─────────────────────────────────────────────────
  Future<void> toggle() async {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }

  // ── Set explicitly ─────────────────────────────────────────
  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dark ? 'dark' : 'light');
  }

  bool get isDark => value == ThemeMode.dark;
}

// ── Global singleton — accessible anywhere ────────────────────────────────────
final themeNotifier = ThemeNotifier();
