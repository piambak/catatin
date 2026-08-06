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
import '../../screens/library/bookmark_screen.dart';
import '../../screens/library/library_screen.dart';
import '../../screens/library/doc_detail_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/business_screen.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

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
      path: '/library/bookmarks',
      builder: (_, __) => const BookmarkScreen(),
    ),
    GoRoute(
      path: '/library/:id',
      builder: (_, s) =>
          DocDetailScreen(docId: s.pathParameters['id']!),
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
          path: AppRoutes.library,
          pageBuilder: (_, __) => _fade(const LibraryScreen()),
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
  static const _tabs = [
    AppRoutes.dashboard,
    AppRoutes.library,
    AppRoutes.accounting,
    AppRoutes.simulator,
    AppRoutes.settings,
  ];

  // Each tab screen is created ONCE and kept alive in IndexedStack
  final _screens = const [
    _DashboardTab(),
    _LibraryTab(),
    _AccountingTab(),
    _SimulatorTab(),
    _SettingsTab(),
  ];

  int get _idx {
    final i = _tabs.indexWhere((t) => widget.location.startsWith(t));
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all screens mounted, just hides inactive ones
      body: IndexedStack(
        index: _idx,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.stone200, width: 0.5))),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => context.go(_tabs[i]),
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: AppColors.stone400,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Perpustakaan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pembukuan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate_rounded),
              label: 'Simulator',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
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

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();
  @override
  Widget build(BuildContext context) => const LibraryScreen();
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