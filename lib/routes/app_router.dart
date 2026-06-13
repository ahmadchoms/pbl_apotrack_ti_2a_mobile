import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

import '../features/customer/presentation/screens/main_screen.dart';
import '../features/customer/presentation/screens/pharmacy_search_screen.dart';

import '../features/staff/presentation/screens/main_screen.dart' as staff;
import '../features/staff/presentation/screens/staff_orders_screen.dart';
import '../features/staff/presentation/screens/staff_inventory_screen.dart';
import '../features/staff/presentation/screens/order_detail_screen.dart';
import '../features/staff/presentation/screens/notification_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String customerHome = '/customer';
  static const String customerPharmacySearch = '/customer/pharmacy-search';
  static const String staffHome = '/staff';
  static const String staffOrders = '/staff/orders';
  static const String staffInventory = '/staff/inventory';
  static const String staffNotifications = '/staff/notifications';
  static const String staffOrderDetail = '/staff/order-detail';

  static final routerProvider = Provider<GoRouter>((ref) {
    final notifier = ref.read(routerNotifierProvider);

    return GoRouter(
      initialLocation: splash,
      refreshListenable: notifier,

      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final isAuthenticated = authState.user != null;
        final isLoading = authState.isLoading;

        final matchedLoc = state.matchedLocation;
        final isLoggingIn = matchedLoc == login;
        final isRegistering = matchedLoc == register;
        final isForgotPw = matchedLoc == forgotPassword;
        final isSplash = matchedLoc == splash;

        final isAuthPage = isLoggingIn || isRegistering || isForgotPw;

        if (!isAuthenticated) {
          if (isAuthPage) return null;
          if (isSplash) return isLoading ? null : login;
          return login;
        }

        if (isAuthenticated) {
          final user = authState.user;
          if (isSplash || isAuthPage) {
            if (user != null && user.isStaff) {
              return staffHome;
            }
            return customerHome;
          }
        }

        return null;
      },

      routes: [
        GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(path: register, builder: (context, state) => const RegisterScreen()),
        GoRoute(path: forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
        GoRoute(path: customerHome, builder: (context, state) => const CustomerMainScreen()),
        GoRoute(path: customerPharmacySearch, builder: (context, state) => const PharmacySearchScreen()),
        GoRoute(path: staffHome, builder: (context, state) => const staff.MainScreen()),
        GoRoute(path: staffOrders, builder: (context, state) => const StaffOrdersScreen()),
        GoRoute(path: staffInventory, builder: (context, state) => const StaffInventoryScreen()),
        GoRoute(path: staffNotifications, builder: (context, state) => const NotificationScreen()),
        GoRoute(
          path: staffOrderDetail,
          builder: (context, state) => OrderDetailScreen(order: state.extra as dynamic),
        ),
      ],
    );
  });
}

final routerNotifierProvider = ChangeNotifierProvider((ref) {
  final notifier = RouterNotifier();

  ref.listen(authNotifierProvider, (previous, next) {
    if (previous?.user != next.user) {
      notifier.notify();
    }
  });

  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
