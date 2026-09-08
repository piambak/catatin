// lib/core/network/app_router.dart — FINAL (Settings + Onboarding wired)

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
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
import '../theme/design_tokens.dart';
import '../../widgets/common/app_nav.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: _guard,
  routes: [
    // ── Auth ──────────────────────────────────────────────
    GoRoute(path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.login,
      builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.register,
      builder: (_, __) => const RegisterScreen()),

    // ── Onboarding (no bottom nav, forced after register) ─
    GoRoute(
      path: '/onboarding/business',
      builder: (_, __) => const BusinessScreen(isOnboarding: true),
    ),

    // ── Full-page routes (push, no bottom nav) ────────────
    GoRoute(
      path: AppRoutes.newTx,
      builder: (_, __) => const NewTransactionScreen(),
    ),
    GoRoute(
      path: '/accounting/:id',
      builder: (_, s) =>
          TxDetailScreen(txId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.bizSetup,
      builder: (_, __) => const BusinessScreen(isOnboarding: false),
    ),

    // ── Notifications (full-page, no bottom nav) ────────────
    GoRoute(
      path: AppRoutes.notifications,
      builder: (_, __) => const NotificationScreen(),
    ),

    // ── Main shell with bottom nav ─────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(
        location: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (_, __) => _fade(const DashboardScreen()),
        ),
        GoRoute(
          path: AppRoutes.accounting,
          pageBuilder: (_, __) => _fade(const AccountingScreen()),
        ),
        GoRoute(
          path: AppRoutes.simulator,
          pageBuilder: (_, __) => _fade(const SimulatorScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (_, __) => _fade(const SettingsScreen()),
        ),
      ],
    ),
  ],
);

// ── Auth guard + onboarding redirect ─────────────────────────────────────────

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final isLoggedIn  = await StorageService.isLoggedIn();
  final isOnboarded = await StorageService.isOnboarded();
  final loc = state.matchedLocation;

  // Fitur Pustaka peraturan dicabut di Fase Dua — tautan lama ke /library
  // pernah tayang publik dan bisa masih di-bookmark orang. Alih-alih jatuh ke
  // layar error bawaan go_router, arahkan ke dashboard.
  if (loc.startsWith('/library')) return AppRoutes.dashboard;

  final onAuth = loc == AppRoutes.login ||
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

// ── Main Shell — IndexedStack keeps all tabs alive in memory ─────────────────

class MainShell extends StatefulWidget {
  final String location;
  final Widget child;
  const MainShell({super.key, required this.location, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Urutan mengikuti mockup Claude Design: Dashboard · Simulator ·
  // Pencatatan · Pengaturan. Rutenya sendiri tidak berubah.
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

  // Each tab screen is created ONCE and kept alive in IndexedStack
  final _screens = const [
    _DashboardTab(),
    _SimulatorTab(),
    _AccountingTab(),
    _SettingsTab(),
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

  int get _idx {
    final i = _destinations
        .indexWhere((d) => widget.location.startsWith(d.route));
    return i >= 0 ? i : 0;
  }

  void _select(int i) => context.go(_destinations[i].route);

  @override
  Widget build(BuildContext context) {
    // IndexedStack menjaga semua tab tetap hidup, hanya menyembunyikan
    // yang tidak aktif.
    final content = IndexedStack(index: _idx, children: _screens);

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

// ── Tab wrapper widgets — these stay alive via IndexedStack ──────────────────
// They import their real screen but wrap it so GoRouter child is not needed

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();
  @override
  Widget build(BuildContext context) => const DashboardScreen();
}

class _AccountingTab extends StatelessWidget {
  const _AccountingTab();
  @override
  Widget build(BuildContext context) => const AccountingScreen();
}

class _SimulatorTab extends StatelessWidget {
  const _SimulatorTab();
  @override
  Widget build(BuildContext context) => const SimulatorScreen();
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) => const SettingsScreen();
}