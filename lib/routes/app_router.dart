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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (int index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Rentals',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Request',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);
  final authNotifier = ref.watch(authStateNotifierProvider);

  return GoRouter(
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
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
            routes: [
              GoRoute(
                path: 'item/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ItemDetailPage(listingId: id);
                },
                routes: [
                  GoRoute(
                    path: 'request',
                    builder: (context, state) {
                      final listingId = state.pathParameters['id']!;
                      return RentalRequestPage(listingId: listingId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'request/:id',
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
                builder: (context, state) => const EditProfilePage(),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: 'my-requests',
                builder: (context, state) => const MyRequestsPage(),
              ),
              GoRoute(
                path: 'my-listings',
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
