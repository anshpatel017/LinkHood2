import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/pages/login_page.dart';

import '../features/auth/presentation/pages/otp_page.dart';
import '../features/auth/presentation/pages/password_setup_page.dart';
import '../features/auth/presentation/pages/onboarding_profile_page.dart';
import '../features/auth/presentation/pages/onboarding_inventory_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/item_detail_page.dart';
import '../features/listings/presentation/pages/add_listing_page.dart';
import '../features/rentals/presentation/pages/my_rentals_page.dart';
import '../features/rentals/presentation/pages/rental_request_page.dart';
import '../features/requests/presentation/pages/request_detail_page.dart';
import '../features/requests/presentation/pages/post_request_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/edit_profile_page.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/profile/presentation/pages/my_listings_page.dart';
import '../features/requests/presentation/pages/my_requests_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

/// App shell with bottom navigation
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BuildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                selectedIndex: _calculateSelectedIndex(context),
                onTap: (i) => _onItemTapped(i, context),
              ),
              _BuildNavItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Rentals',
                index: 1,
                selectedIndex: _calculateSelectedIndex(context),
                onTap: (i) => _onItemTapped(i, context),
              ),
              _BuildNavItem(
                icon: Icons.add_box_outlined,
                label: 'Request',
                index: 2,
                selectedIndex: _calculateSelectedIndex(context),
                onTap: (i) => _onItemTapped(i, context),
              ),
              _BuildNavItem(
                icon: Icons.notifications_none_rounded,
                label: 'Alerts',
                index: 3,
                selectedIndex: _calculateSelectedIndex(context),
                onTap: (i) => _onItemTapped(i, context),
              ),
              _BuildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 4,
                selectedIndex: _calculateSelectedIndex(context),
                onTap: (i) => _onItemTapped(i, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/rentals')) return 1;
    if (location.startsWith('/request')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/rentals');
        break;
      case 2:
        context.go('/request');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

class _BuildNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;

  const _BuildNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = isSelected ? primaryColor : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
        ],
      ),
    );
  }
}

/// A ChangeNotifier that listens to Supabase auth state changes
/// and notifies GoRouter to re-evaluate its redirect logic.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}

/// Global auth state notifier for router refresh
final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier();
});

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);
  final authNotifier = ref.watch(authStateNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final isAuthenticated = user != null;
      final path = state.uri.path;
      final isLoginOrOtp =
          path.startsWith('/login') || path.startsWith('/otp');
      final isSetupPassword = path.startsWith('/setup-password');
      final isOnboardingRoute = path.startsWith('/onboarding');

      // Not authenticated — allow login, OTP, and setup-password; redirect others
      if (!isAuthenticated) {
        if (isLoginOrOtp || isSetupPassword) return null;
        return '/login';
      }

      // Authenticated user still on login/otp — move forward
      if (isAuthenticated && isLoginOrOtp) {
        if (user.fullName.isEmpty) return '/onboarding';
        return '/home';
      }

      // Allow setup-password for authenticated users (they just verified OTP)
      if (isAuthenticated && isSetupPassword) return null;

      // Authenticated user trying to skip onboarding
      if (isAuthenticated && !isOnboardingRoute && user.fullName.isEmpty) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/setup-password',
        builder: (context, state) => const PasswordSetupPage(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingProfilePage(),
        routes: [
          GoRoute(
            path: 'inventory',
            builder: (context, state) => const OnboardingInventoryPage(),
          ),
        ],
      ),

      // Main app routes with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
            routes: [
              GoRoute(
                path: 'item/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ItemDetailPage(listingId: id);
                },
                routes: [
                  GoRoute(
                    path: 'request',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final listingId = state.pathParameters['id']!;
                      return RentalRequestPage(listingId: listingId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'request/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return RequestDetailPage(requestId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/rentals',
            builder: (context, state) => const MyRentalsPage(),
          ),
          GoRoute(
            path: '/request',
            builder: (context, state) => const PostRequestPage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EditProfilePage(),
              ),
              GoRoute(
                path: 'settings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: 'my-requests',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MyRequestsPage(),
              ),
              GoRoute(
                path: 'my-listings',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const MyListingsPage(),
              ),
            ],
          ),
        ],
      ),

      // Standalone routes (outside bottom nav)
      GoRoute(
        path: '/add-listing',
        builder: (context, state) => const AddListingPage(),
      ),
    ],
  );
});
