// lib/core/constants/app_constants.dart
//
// Konstanta yang tidak berubah antar-lingkungan.
// Untuk yang berubah (URL backend, timeout, mode data) lihat `core/config/app_config.dart`.

class AppConstants {
  AppConstants._();

  // ── Info aplikasi ─────────────────────────────────────────
  static const appName = 'Catatin';
  static const appVersion = '1.0.0';

  // ── Konstanta pajak (PP 23/2018, PMK 168/2023) ────────────
  static const pphFinalRate = 0.005; // 0,5%
  static const pkpThreshold = 4800000000.0; // Rp 4,8 Miliar
  static const ppnRate = 0.11; // 11%
  static const pphBadanRate = 0.22; // 22%

  // PTKP 2024
  static const ptkp = {
    'TK0': 54000000.0,
    'TK1': 58500000.0,
    'TK2': 63000000.0,
    'TK3': 67500000.0,
    'K0': 58500000.0,
    'K1': 63000000.0,
    'K2': 67500000.0,
    'K3': 72000000.0,
  };

  // TER Bulanan — Kategori A (TK/0)
  static const terTableA = [
    {'max': 5400000.0, 'rate': 0.000},
    {'max': 5650000.0, 'rate': 0.005},
    {'max': 5950000.0, 'rate': 0.005},
    {'max': 6300000.0, 'rate': 0.005},
    {'max': 6750000.0, 'rate': 0.010},
    {'max': 7500000.0, 'rate': 0.015},
    {'max': 8550000.0, 'rate': 0.020},
    {'max': 9650000.0, 'rate': 0.025},
    {'max': 10050000.0, 'rate': 0.030},
    {'max': 10350000.0, 'rate': 0.035},
    {'max': 10700000.0, 'rate': 0.040},
    {'max': 11050000.0, 'rate': 0.050},
    {'max': 11600000.0, 'rate': 0.050},
    {'max': 12500000.0, 'rate': 0.060},
    {'max': 13750000.0, 'rate': 0.070},
    {'max': 15100000.0, 'rate': 0.080},
    {'max': 16950000.0, 'rate': 0.090},
    {'max': 19750000.0, 'rate': 0.100},
    {'max': 24150000.0, 'rate': 0.110},
    {'max': 26450000.0, 'rate': 0.150},
    {'max': 28000000.0, 'rate': 0.170},
    {'max': 30050000.0, 'rate': 0.190},
    {'max': 32400000.0, 'rate': 0.210},
    {'max': 35400000.0, 'rate': 0.230},
    {'max': 39100000.0, 'rate': 0.250},
    {'max': 43850000.0, 'rate': 0.270},
    {'max': 47800000.0, 'rate': 0.290},
    {'max': 51400000.0, 'rate': 0.300},
    {'max': 56300000.0, 'rate': 0.310},
    {'max': 62200000.0, 'rate': 0.320},
    {'max': 74750000.0, 'rate': 0.330},
    {'max': double.infinity, 'rate': 0.340},
  ];
}

// ── Kunci penyimpanan lokal ───────────────────────────────────────────────────

class StorageKeys {
  StorageKeys._();

  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const userName = 'user_name';
  static const userEmail = 'user_email';
  static const businessId = 'business_id';
  static const onboarded = 'onboarded';
  static const bookmarks = 'bookmarks';
  static const themeMode = 'theme_mode';
}

// ── Nama route ────────────────────────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const library = '/library';
  static const libDetail = '/library/:id';
  static const accounting = '/accounting';
  static const newTx = '/accounting/new';
  static const txDetail = '/accounting/:id';
  static const simulator = '/simulator';
  static const settings = '/settings';
  static const bizSetup = '/settings/business';
  static const notifications = '/notifications';
}

// ── Endpoint backend ──────────────────────────────────────────────────────────
//
// Daftar lengkap path yang dipanggil aplikasi. Semuanya relatif terhadap
// `AppConfig.apiBaseUrl`. Bentuk request/response-nya ada di `docs/BACKEND.md`.

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const me = '/auth/me';

  // Profil usaha
  static const business = '/business';
  static String businessById(String id) => '/business/$id';

  // Transaksi
  static const transactions = '/transactions';
  static String transactionById(String id) => '/transactions/$id';
  static const txCategories = '/tx-categories';

  // Dashboard
  static const dashboardSummary = '/dashboard/summary';
  static const dashboardKpiHistory = '/dashboard/kpi-history';
  static const taxCalendar = '/tax-calendar';

  // Pustaka peraturan
  static const documents = '/documents';
  static String documentById(String id) => '/documents/$id';
  static const docCategories = '/documents/categories';

  // Simulator pajak murni hitungan lokal — tidak butuh endpoint.
}
