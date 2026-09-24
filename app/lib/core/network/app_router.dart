// lib/core/network/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/accounting/accounting_screen.dart';
import '../../screens/accounting/new_transaction_screen.dart';
import '../../screens/accounting/tx_detail_screen.dart';
import '../../screens/simulator/simulator_screen.dart';
import '../../screens/dashboard/notification_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/business_screen.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/theme_notifier.dart';
import '../theme/breakpoints.dart';
import '../theme/design_tokens.dart';
import '../../widgets/common/app_nav.dart';
import '../../widgets/common/ds_widgets.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: _guard,
  // Penjaga rute dievaluasi ulang setiap status masuk berubah — termasuk saat
  // backend mengakhiri sesi tanpa ada layar yang memanggil context.go.
  refreshListenable: AuthService.sessionChanges,
  routes: [
    // ── Auth ──────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => _themed(() => SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => _themed(() => LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => _themed(() => RegisterScreen()),
    ),

    // ── Onboarding (no bottom nav, forced after register) ─
    GoRoute(
      path: '/onboarding/business',
      builder: (_, __) => _themed(() => BusinessScreen(isOnboarding: true)),
    ),

    // ── Full-page routes (push, no bottom nav) ────────────
    GoRoute(
      path: AppRoutes.newTx,
      builder: (_, __) => _themed(() => NewTransactionScreen()),
    ),
    GoRoute(
      path: '/accounting/:id',
      builder: (_, s) =>
          _themed(() => TxDetailScreen(txId: s.pathParameters['id']!)),
    ),
    GoRoute(
      path: AppRoutes.bizSetup,
      builder: (_, __) => _themed(() => BusinessScreen(isOnboarding: false)),
    ),

    // ── Notifications (full-page, no bottom nav) ────────────
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => _themed(() => NotificationScreen()),
    ),

    // ── Shell utama: satu cabang per tab ──────────────────
    //
    // StatefulShellRoute (T-27) menggantikan IndexedStack buatan sendiri yang
    // membangun keempat tab sekaligus saat boot — Dashboard, Pencatatan, dan
    // Pengaturan menembak request bersamaan sebelum pengguna membuka apa pun,
    // dan itulah yang memicu balapan 401 di T-23. Di sini cabang baru dibangun
    // saat pertama dibuka, lalu tetap hidup (posisi gulir & isian tidak
    // hilang saat pindah tab).
    //
    // Urutan cabang = urutan tujuan navigasi di MainShell.
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) =>
          _themed(() => MainShell(navigationShell: shell)),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              pageBuilder: (_, __) => _fade(_themed(() => DashboardScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.simulator,
              pageBuilder: (_, __) => _fade(_themed(() => SimulatorScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.accounting,
              pageBuilder: (_, __) => _fade(_themed(() => AccountingScreen())),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              pageBuilder: (_, __) => _fade(_themed(() => SettingsScreen())),
            ),
          ],
        ),
      ],
    ),
  ],
  // Alamat yang tidak cocok rute mana pun — dulu layar kosong (T-27).
  errorBuilder: (context, state) => _themed(
    () => Scaffold(
      backgroundColor: DS.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_off_rounded, size: 34, color: DS.faint),
                const SizedBox(height: 16),
                Text(
                  'Halaman tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: Typo.serif(24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alamat ${state.uri.path} tidak ada di Catatin.',
                  textAlign: TextAlign.center,
                  style: Typo.sans(15, color: DS.body),
                ),
                const SizedBox(height: 20),
                DsButton(
                  label: 'Kembali ke Dashboard',
                  onPressed: () => context.go(AppRoutes.dashboard),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

/// Membangun ulang subtree saat mode terang/gelap berganti.
///
/// Token `DS.*` adalah getter statis yang membaca [themeNotifier] langsung —
/// tidak lewat InheritedWidget. Artinya layar yang memakainya **tidak
/// berlangganan** apa pun: saat `MaterialApp` menerima `themeMode` baru,
/// Navigator tidak punya alasan membangun ulang halamannya, jadi warnanya
/// tidak ikut berubah sampai layar itu dibuka ulang.
///
/// [build] sengaja berupa fungsi, bukan widget jadi: pemanggilnya harus
/// membuat instance BARU tiap rebuild. Kalau yang dikembalikan instance
/// `const` yang sama, Flutter melihat widget identik lalu melewati rebuild —
/// dan bug-nya kembali. State di dalamnya tetap aman karena tipe dan key-nya
/// tidak berubah, jadi Element-nya diperbarui, bukan dibuang.
Widget _themed(Widget Function() build) => ValueListenableBuilder<ThemeMode>(
  valueListenable: themeNotifier,
  builder: (_, __, ___) => build(),
);

// ── Auth guard + onboarding redirect ─────────────────────────────────────────

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final isLoggedIn = await StorageService.isLoggedIn();
  final isOnboarded = await StorageService.isOnboarded();
  final loc = state.matchedLocation;

  // Fitur Pustaka peraturan dicabut di Fase Dua — tautan lama ke /library
  // pernah tayang publik dan bisa masih di-bookmark orang. Alih-alih jatuh ke
  // layar error bawaan go_router, arahkan ke dashboard.
  if (loc.startsWith('/library')) return AppRoutes.dashboard;

  final onAuth =
      loc == AppRoutes.login ||
      loc == AppRoutes.register ||
      loc == AppRoutes.splash;
  final onOnboarding = loc == '/onboarding/business';

  // Not logged in → go to login
  if (!isLoggedIn && !onAuth) return AppRoutes.login;

  // Logged in but on auth screen → go to dashboard or onboarding
  if (isLoggedIn && onAuth && loc != AppRoutes.splash) {
    return isOnboarded ? AppRoutes.dashboard : '/onboarding/business';
  }

  // Logged in, not onboarded, going anywhere except onboarding → redirect
  if (isLoggedIn && !isOnboarded && !onOnboarding && !onAuth) {
    return '/onboarding/business';
  }

  return null;
}

CustomTransitionPage _fade(Widget child) => CustomTransitionPage(
  child: child,
  transitionsBuilder: (_, anim, __, c) =>
      FadeTransition(opacity: anim, child: c),
  transitionDuration: const Duration(milliseconds: 180),
);

// ── Main Shell ────────────────────────────────────────────────────────────────

/// Kerangka navigasi: rail di layar lebar, pil navigasi mengambang di ponsel.
/// Isi tab datang dari [navigationShell] — satu Navigator per cabang.
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Urutan mengikuti mockup Claude Design: Dashboard · Simulator ·
  // Pencatatan · Pengaturan — dan harus sama dengan urutan cabang
  // StatefulShellRoute di atas.
  static const _destinations = [
    NavDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: AppRoutes.dashboard,
    ),
    NavDestination(
      label: 'Simulator',
      icon: Icons.calculate_outlined,
      route: AppRoutes.simulator,
    ),
    NavDestination(
      label: 'Pencatatan',
      icon: Icons.receipt_long_outlined,
      route: AppRoutes.accounting,
    ),
    NavDestination(
      label: 'Pengaturan',
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
    ),
  ];

  bool _railExpanded = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    StorageService.getUserName().then((n) {
      if (mounted) setState(() => _userName = n);
    });
  }

  int get _idx => widget.navigationShell.currentIndex;

  /// Mengetuk tab yang sedang aktif membawanya kembali ke awal cabangnya.
  void _select(int i) =>
      widget.navigationShell.goBranch(i, initialLocation: i == _idx);

  @override
  Widget build(BuildContext context) {
    final content = widget.navigationShell;

    return Scaffold(
      backgroundColor: DS.surface,
      body: BreakpointBuilder(
        builder: (context, bp) {
          if (bp.usesRail) {
            return Row(
              children: [
                AppNavRail(
                  destinations: _destinations,
                  currentIndex: _idx,
                  onSelect: _select,
                  expanded: _railExpanded,
                  onToggle: () =>
                      setState(() => _railExpanded = !_railExpanded),
                  userName: _userName,
                ),
                Expanded(child: content),
              ],
            );
          }

          // Pil navigasi mengambang di atas konten, seperti di mockup.
          return Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: AppBottomNav(
                    destinations: _destinations,
                    currentIndex: _idx,
                    onSelect: _select,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
