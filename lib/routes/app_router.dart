import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/staff/presentation/screens/order_detail_screen.dart';
import 'package:mobile/features/customer/presentation/screens/main_screen.dart'
    as customer;
import '../features/staff/presentation/screens/main_screen.dart' as staff;
import '../features/staff/presentation/screens/pos_screen.dart';
import '../features/staff/presentation/screens/scanner_screen.dart';
import '../features/staff/presentation/screens/medicine_detail_screen.dart';
import '../features/staff/presentation/screens/medicine_form_screen.dart';
import '../features/staff/presentation/screens/audit_log_detail_screen.dart';
import '../features/staff/presentation/screens/notification_screen.dart';
import '../features/staff/presentation/screens/edit_profile_screen.dart';
import '../features/staff/presentation/screens/change_password_screen.dart';
import '../features/staff/presentation/screens/activity_history_screen.dart';

// Sub-routes for staff

class AppRouter {
  static const String initial = '/';
  static const String login = '/login';
  static const String customerHome = '/customer';
  static const String staffHome = '/staff';

  // Sub-routes for staff
  static const String staffPos = '/staff/pos';
  static const String staffScanner = '/staff/scanner';
  static const String staffOrderDetail = '/staff/order-detail';
  static const String staffMedicineDetail = '/staff/medicine-detail';
  static const String staffMedicineForm = '/staff/medicine-form';
  static const String staffAuditLogDetail = '/staff/audit-log-detail';
  static const String staffNotifications = '/staff/notifications';
  static const String staffOrders = '/staff/orders';
  static const String staffInventory = '/staff/inventory';
  static const String staffEditProfile = '/staff/edit-profile';
  static const String staffChangePassword = '/staff/change-password';
  static const String staffActivityHistory = '/staff/activity-history';

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: initial, builder: (context, state) => const SplashScreen()),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: staffHome,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final index = tab != null ? int.tryParse(tab) ?? 0 : 0;
          return staff.MainScreen(initialIndex: index);
        },
      ),
      GoRoute(path: staffPos, builder: (context, state) => const PosScreen()),
      GoRoute(
        path: staffScanner,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: staffOrderDetail,
        builder: (context, state) => const OrderDetailScreen(),
      ),
      GoRoute(
        path: staffMedicineDetail,
        builder: (context, state) => const MedicineDetailScreen(),
      ),
      GoRoute(
        path: staffMedicineForm,
        builder: (context, state) {
          final med = state.extra as Map<String, dynamic>?;
          return MedicineFormScreen(medicine: med);
        },
      ),
      GoRoute(
        path: staffAuditLogDetail,
        builder: (context, state) {
          final activity = state.extra as Map<String, dynamic>;
          return AuditLogDetailScreen(activity: activity);
        },
      ),
      GoRoute(
        path: staffNotifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: staffOrders,
        builder: (context, state) => const staff.MainScreen(initialIndex: 1),
      ),
      GoRoute(
        path: staffInventory,
        builder: (context, state) => const staff.MainScreen(initialIndex: 2),
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
      GoRoute(
        path: customerHome,
        builder: (context, state) => const customer.CustomerMainScreen(),
      ),
    ],
    // Logic for redirection can be added here or handled in the Login logic
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint("--- [DEBUG] Memulai Inisialisasi Startup ---");

      // Simulasi/Panggilan API Cek Sesi (Token Check)
      // Gunakan .timeout() agar tidak stuck selamanya jika server tidak merespons
      await Future.delayed(const Duration(seconds: 2)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception("Connection Timeout"),
      );

      // Dummy Check: Dalam realita, cek SecureStorage untuk token & Fetch Profile
      // const String? role = null; // Ganti dengan logika fetch role

      if (!mounted) return;

      // Jika tidak ada sesi, arahkan ke Login
      context.go(AppRouter.login);
    } catch (e) {
      debugPrint("--- [ERROR] Gagal Inisialisasi: $e ---");

      if (!mounted) return;

      // Jika error (server mati / IP salah), JANGAN STUCK, arahkan ke Login
      // Anda bisa menambahkan SnackBar untuk memberitahu user
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Menghubungkan ke Server...',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _handleLogin(context, 'USER'),
              child: const Text('Login as Customer'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleLogin(context, 'STAFF'),
              child: const Text('Login as Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, String role) {
    // Logic as requested by USER:
    if (role == 'USER') {
      context.go(AppRouter.customerHome);
    } else if (role == 'STAFF' || role == 'APOTEKER') {
      context.go(AppRouter.staffHome);
    }
  }
}
