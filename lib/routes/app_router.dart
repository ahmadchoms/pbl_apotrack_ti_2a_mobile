import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/staff/presentation/screens/staff_orders_screen.dart';
import '../features/staff/data/models/medicine.dart';
import '../features/staff/data/models/order.dart';
import '../features/staff/data/models/audit_log.dart';

// Auth & General
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

// Customer
import '../features/customer/presentation/screens/home_screen.dart';
import '../features/customer/presentation/screens/customer_profile_screen.dart';
import '../features/customer/presentation/screens/edit_profile_screen.dart';
import '../features/customer/presentation/screens/change_password_screen.dart';
import '../features/customer/presentation/screens/edit_address_screen.dart';
import '../features/customer/data/models/customer_address.dart';

// Staff
import '../features/staff/presentation/screens/main_screen.dart';
import '../features/staff/presentation/screens/order_detail_screen.dart';
import '../features/staff/presentation/screens/medicine_detail_screen.dart';
import '../features/staff/presentation/screens/medicine_form_screen.dart';
import '../features/staff/presentation/screens/notification_screen.dart';
import '../features/staff/presentation/screens/pos_screen.dart';
import '../features/staff/presentation/screens/audit_log_detail_screen.dart';
import '../features/staff/presentation/screens/edit_profile_screen.dart';
import '../features/staff/presentation/screens/change_password_screen.dart';
import '../features/staff/presentation/screens/activity_history_screen.dart';
import '../features/staff/presentation/screens/staff_inventory_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String customerHome = '/customer';
  static const String staffHome = '/staff';

  static const String customerAccountHub = '/customer/account-hub';
  static const String customerEditProfile = '/customer/edit-profile';
  static const String customerChangePassword = '/customer/change-password';
  static const String customerEditAddress = '/customer/edit-address';
  static const String customerOrderDetail = '/customer/order-detail';
  static const String customerTrackOrder = '/customer/track-order';

  static const String staffInventory = '/staff/inventory';
  static const String staffOrderDetail = '/staff/order-detail';
  static const String staffOrders = '/staff/orders';
  static const String staffMedicineDetail = '/staff/medicine-detail';
  static const String staffMedicineForm = '/staff/medicine-form';
  static const String staffNotifications = '/staff/notifications';
  static const String staffPos = '/staff/pos';
  static const String staffAuditLogDetail = '/staff/audit-log-detail';

  static const String staffEditProfile = '/staff/edit-profile';
  static const String staffChangePassword = '/staff/change-password';
  static const String staffActivityHistory = '/staff/activity-history';

  static final routerProvider = Provider<GoRouter>((ref) {
    // Gunakan ref.read agar GoRouter tidak di-rebuild saat notifier berubah.
    // GoRouter akan merespon perubahan lewat refreshListenable secara internal.
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

        // 1. Jika BELUM Login
        if (!isAuthenticated) {
          // A. Jika di halaman Auth (Login/Register/Lupa Password), tetap di sana
          if (isAuthPage) return null;

          // B. Jika di Splash: tetap di sana jika sedang loading (cek session), ke login jika sudah selesai
          if (isSplash) {
            return isLoading ? null : login;
          }

          // C. Jika di halaman internal lain, lempar ke login
          return login;
        }

        // 2. Jika SUDAH Login
        if (isAuthenticated) {
          if (isSplash || isAuthPage) {
            return authState.user?.role == 'STAFF' ? staffHome : customerHome;
          }
        }

        return null;
      },

      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: customerHome,
          builder: (context, state) => const CustomerHomeScreen(),
        ),

        // Dashboard Utama (MainScreen mengelola tab Pesanan & Profile)
        GoRoute(
          path: staffHome,
          builder: (context, state) => const MainScreen(),
        ),
        GoRoute(
          path: customerAccountHub,
          builder: (context, state) => const AccountHubScreen(),
        ),

        GoRoute(
          path: customerEditProfile,
          builder: (context, state) => const CustomerEditProfileScreen(),
        ),

        GoRoute(
          path: customerChangePassword,
          builder: (context, state) => const CustomerChangePasswordScreen(),
        ),

        GoRoute(
          path: customerEditAddress,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            final isAdd = extra?['isAdd'] as bool? ?? false;

            final address = extra?['address'] as CustomerAddress?;

            return CustomerEditAddressScreen(isAdd: isAdd, address: address);
          },
        ),

        // Halaman yang berdiri sendiri
        GoRoute(
          path: staffInventory,
          builder: (context, state) => const StaffInventoryScreen(),
        ),
        GoRoute(
          path: staffOrders,
          builder: (context, state) => const StaffOrdersScreen(),
        ),
        GoRoute(
          path: staffOrderDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Order) return OrderDetailScreen(order: extra);
            return OrderDetailScreen(
              order: Order.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffMedicineDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Medicine) return MedicineDetailScreen(medicine: extra);
            return MedicineDetailScreen(
              medicine: Medicine.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffMedicineForm,
          builder: (context, state) {
            final extra = state.extra;
            if (extra == null) return const MedicineFormScreen(medicine: null);
            if (extra is Medicine) return MedicineFormScreen(medicine: extra);
            return MedicineFormScreen(
              medicine: Medicine.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffNotifications,
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(path: staffPos, builder: (context, state) => const PosScreen()),
        GoRoute(
          path: staffAuditLogDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is AuditLog) return AuditLogDetailScreen(activity: extra);
            return AuditLogDetailScreen(
              activity: AuditLog.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),

        GoRoute(
          path: staffEditProfile,
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: staffChangePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: staffActivityHistory,
          builder: (context, state) => const ActivityHistoryScreen(),
        ),
      ],
    );
  });
}

final routerNotifierProvider = ChangeNotifierProvider((ref) {
  final notifier = RouterNotifier();

  // Hanya picu refresh navigasi jika objek user berubah (Login/Logout)
  // Abaikan perubahan status isLoading agar halaman tidak ter-reset saat API bekerja
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
