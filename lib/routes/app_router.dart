import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/staff/data/models/medicine.dart';
import '../features/staff/data/models/order.dart';
import '../features/staff/data/models/audit_log.dart';

// Auth
import '../core/auth/auth_state_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';

// Customer
import '../features/customer/presentation/screens/main_screen.dart';
import '../features/customer/presentation/screens/customer_profile_screen.dart';
import '../features/customer/presentation/screens/order_detail_screen.dart'
    as customer_order;
import '../features/customer/presentation/screens/track_order_screen.dart';
import '../features/customer/data/models/customer_address.dart';
import '../features/customer/presentation/screens/pharma_scan_map_screen.dart';
import '../features/customer/presentation/screens/medicine_list_screen.dart';
import '../features/customer/presentation/screens/qris_payment_screen.dart';
import '../features/customer/presentation/screens/beri_ulasan_screen.dart';

// Staff
import '../features/staff/presentation/screens/main_screen.dart'
    as staff_main;
import '../features/staff/presentation/screens/edit_profile_screen.dart'
    as staff_edit_profile;
import '../features/staff/presentation/screens/change_password_screen.dart'
    as staff_change_password;
import '../features/staff/presentation/screens/edit_address_screen.dart'
    as staff_edit_address;
import '../features/staff/presentation/screens/order_detail_screen.dart'
    as staff_order_detail;
import '../features/staff/presentation/screens/medicine_detail_screen.dart';
import '../features/staff/presentation/screens/medicine_form_screen.dart';
import '../features/staff/presentation/screens/notification_screen.dart';
import '../features/staff/presentation/screens/pos_screen.dart';
import '../features/staff/presentation/screens/audit_log_detail_screen.dart';
import '../features/staff/presentation/screens/activity_history_screen.dart';
import '../features/staff/presentation/screens/staff_inventory_screen.dart';
import '../features/staff/presentation/screens/scanner_screen.dart';
import '../features/staff/presentation/screens/staff_orders_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String customerHome = '/customer';
  static const String customerPharmacySearch = '/customer/pharmacy-search';
  static const String staffHome = '/staff';

  static const String customerAccountHub = '/customer/account-hub';
  static const String customerEditProfile = '/customer/edit-profile';
  static const String customerChangePassword = '/customer/change-password';
  static const String customerEditAddress = '/customer/edit-address';
  static const String customerOrderDetail = '/customer/order-detail';
  static const String customerTrackOrder = '/customer/track-order';
  static const String customerMedicineList = '/customer/medicine-list';
  static const String customerPayment = '/customer/payment';
  static const String customerUlasan = '/customer/ulasan';

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
  static const String staffScanner = '/staff/scanner';

  static final routerProvider = Provider<GoRouter>((ref) {
    final notifier = ref.read(routerNotifierProvider);

    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: splash,
      refreshListenable: notifier,

      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final isAuthenticated = authState.user != null;
        final isLoading = authState.isLoading;

        if (isLoading) return null;

        final matchedLoc = state.matchedLocation;
        final isLoggingIn = matchedLoc == login;
        final isRegistering = matchedLoc == register;
        final isForgotPw = matchedLoc == forgotPassword;
        final isSplash = matchedLoc == splash;
        final isAuthPage = isLoggingIn || isRegistering || isForgotPw;

        if (!isAuthenticated) {
          if (isLoggingIn || isRegistering || isForgotPw) return null;
          return login;
        }

        if (isSplash || isAuthPage) {
          return authState.user?.role == 'STAFF' ? staffHome : customerHome;
        }

        return null;
      },

      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // ── Customer ──────────────────────────────────────────────
        GoRoute(
          path: customerHome,
          builder: (context, state) => const CustomerMainScreen(),
        ),
        GoRoute(
          path: customerAccountHub,
          builder: (context, state) => const AccountHubScreen(),
        ),
        GoRoute(
          path: customerEditProfile,
          builder: (context, state) =>
              const staff_edit_profile.EditProfileScreen(),
        ),
        GoRoute(
          path: customerChangePassword,
          builder: (context, state) =>
              const staff_change_password.ChangePasswordScreen(),
        ),
        GoRoute(
          path: customerEditAddress,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final isAdd = extra?['isAdd'] as bool? ?? false;
            final address = extra?['address'] as CustomerAddress?;
            return staff_edit_address.EditAddressScreen(
              isAdd: isAdd,
              address: address,
            );
          },
        ),
        GoRoute(
          path: customerOrderDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Order) {
              return customer_order.CustomerOrderDetailScreen(order: extra);
            }
            if (extra is String) {
              return customer_order.CustomerOrderDetailScreen(orderId: extra);
            }
            final queryId = state.uri.queryParameters['id'];
            if (queryId != null) {
              return customer_order.CustomerOrderDetailScreen(orderId: queryId);
            }
            if (extra is Map<String, dynamic>) {
              return customer_order.CustomerOrderDetailScreen(
                order: Order.fromJson(extra),
              );
            }
            return const Scaffold(
              body: Center(
                child: Text('Pesanan tidak ditemukan'),
              ),
            );
          },
        ),
        GoRoute(
          path: customerTrackOrder,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Order) return TrackOrderScreen(order: extra);
            return TrackOrderScreen(
              order: Order.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: customerPharmacySearch,
          builder: (context, state) => const PharmaScanMapScreen(),
        ),
        GoRoute(
          path: customerMedicineList,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return MedicineListScreen(
              pharmacyId: extra['pharmacyId'] as String,
              pharmacyName: extra['pharmacyName'] as String,
              pharmacyRating:
                  (extra['pharmacyRating'] as num?)?.toDouble() ?? 4.5,
              pharmacyDistance: extra['pharmacyDistance'] as String? ?? '-',
              pharmacyArea: extra['pharmacyArea'] as String? ?? '-',
            );
          },
        ),
        GoRoute(
          path: customerPayment,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return QrisPaymentScreen(
              pharmacyId: extra['pharmacyId'] as String,
              pharmacyName: extra['pharmacyName'] as String,
              items: List<Map<String, dynamic>>.from(extra['items'] as List),
              subtotal: extra['subtotal'] as int,
              shippingCost: extra['shippingCost'] as int? ?? 0,
              deliveryMethod: extra['deliveryMethod'] as String,
              addressId: extra['addressId'] as String?,
              notes: extra['notes'] as String?,
              courierCode: extra['courierCode'] as String?,
              courierService: extra['courierService'] as String?,
            );
          },
        ),
        GoRoute(
          path: customerUlasan,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return BeriUlasanScreen(
              orderNumber: extra['orderNumber'] as String,
              pharmacyId: extra['pharmacyId'] as String,
              pharmacyName: extra['pharmacyName'] as String,
              items: extra['items'] != null
                  ? List<Map<String, dynamic>>.from(extra['items'] as List)
                  : [],
            );
          },
        ),

        // ── Staff ─────────────────────────────────────────────────
        GoRoute(
          path: staffHome,
          builder: (context, state) => const staff_main.MainScreen(),
        ),
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
            if (extra is Order) {
              return staff_order_detail.OrderDetailScreen(order: extra);
            }
            return staff_order_detail.OrderDetailScreen(
              order: Order.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffMedicineDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Medicine) {
              return MedicineDetailScreen(medicine: extra);
            }
            return MedicineDetailScreen(
              medicine: Medicine.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffMedicineForm,
          builder: (context, state) {
            final extra = state.extra;
            if (extra == null) {
              return const MedicineFormScreen(medicine: null);
            }
            if (extra is Medicine) {
              return MedicineFormScreen(medicine: extra);
            }
            return MedicineFormScreen(
              medicine: Medicine.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffNotifications,
          builder: (context, state) => const NotificationScreen(),
        ),
        GoRoute(
          path: staffPos,
          builder: (context, state) => const PosScreen(),
        ),
        GoRoute(
          path: staffAuditLogDetail,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is AuditLog) {
              return AuditLogDetailScreen(activity: extra);
            }
            return AuditLogDetailScreen(
              activity: AuditLog.fromJson(extra as Map<String, dynamic>),
            );
          },
        ),
        GoRoute(
          path: staffEditProfile,
          builder: (context, state) =>
              const staff_edit_profile.EditProfileScreen(),
        ),
        GoRoute(
          path: staffChangePassword,
          builder: (context, state) =>
              const staff_change_password.ChangePasswordScreen(),
        ),
        GoRoute(
          path: staffActivityHistory,
          builder: (context, state) => const ActivityHistoryScreen(),
        ),
        GoRoute(
          path: staffScanner,
          builder: (context, state) => const ScannerScreen(),
        ),
      ],
    );

    ref.listen<bool>(authExpiredProvider, (_, expired) {
      if (expired) {
        ref.read(authExpiredProvider.notifier).state = false;
        router.go(login);
      }
    });

    return router;
  });
}

final routerNotifierProvider = ChangeNotifierProvider((ref) {
  final notifier = RouterNotifier();

  ref.listen(authNotifierProvider, (previous, next) {
    if (previous?.user != next.user || previous?.isLoading != next.isLoading) {
      notifier.notify();
    }
  });
  return notifier;
});

class RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
