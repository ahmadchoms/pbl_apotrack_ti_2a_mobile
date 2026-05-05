import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/staff/presentation/screens/main_screen.dart' as staff;

// TODO: Import Customer screens when ready
// import '../features/customer/presentation/screens/main_screen.dart' as customer;

class AppRouter {
  static const String initial = '/';
  static const String login = '/login';
  static const String customerHome = '/customer';
  static const String staffHome = '/staff';

  static final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: initial,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: staffHome,
        builder: (context, state) => const staff.MainScreen(),
      ),
      GoRoute(
        path: customerHome,
        builder: (context, state) => const Center(child: Text('Customer Home Placeholder')),
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
