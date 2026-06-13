import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'routes/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/customer/presentation/screens/order_datail.dart';
import 'features/staff/presentation/screens/staff_orders_screen.dart';
import 'features/staff/presentation/screens/staff_inventory_screen.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (!kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );

        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      }

      await initializeDateFormatting('id_ID', null);

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          debugPrint('FlutterError: ${details.exceptionAsString()}');
        }
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught async error: $error\n$stack');
        return true;
      };

      runApp(const ProviderScope(child: ApoTrackApp()));
    },
    (error, stack) {
      debugPrint('Unhandled zone error: $error\n$stack');
    },
  );
}

class ApoTrackApp extends ConsumerStatefulWidget {
  const ApoTrackApp({super.key});

  @override
  ConsumerState<ApoTrackApp> createState() => _ApoTrackAppState();
}

class _ApoTrackAppState extends ConsumerState<ApoTrackApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        _setupForegroundListener();
        _setupBackgroundTapListener();
        _checkInitialMessage();
        _setupTokenRefresh();
      }
    });
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Notifikasi Baru';
      final body = message.notification?.body ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $body'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Lihat', onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _navigateToScreen(message);
            }),
          ),
        );
      }
    });
  }

  void _setupBackgroundTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateToScreen);
  }

  void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final dio = ref.read(dioProvider);
        PushNotificationService.updateDeviceToken(dio, user.id);
      }
    });
  }

  void _checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _navigateToScreen(message);
    }
  }

  void _navigateToScreen(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toUpperCase();
    final referenceId = data['reference_id'];
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    final navigator = Navigator.of(context);

    if (user.isCustomer) {
      switch (type) {
        case 'ORDER':
          if (referenceId != null && referenceId.isNotEmpty) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: referenceId),
              ),
            );
          }
          break;
        default:
          break;
      }
    } else if (user.isStaff) {
      switch (type) {
        case 'ORDER':
          navigator.push(
            MaterialPageRoute(builder: (_) => const StaffOrdersScreen()),
          );
          break;
        case 'STOCK':
        case 'INVENTORY':
          navigator.push(
            MaterialPageRoute(builder: (_) => const StaffInventoryScreen()),
          );
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    return MaterialApp.router(
      title: 'ApoTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.notification?.title ?? 'Notifikasi Baru'}: ${message.notification?.body ?? ''}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Lihat', onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _navigateToScreen(message);
            }),
          ),
        );
      }
    });
  }

  void _setupBackgroundTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateToScreen);
  }

  void _registerDeviceToken() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final dio = ref.read(dioProvider);
      PushNotificationService.updateDeviceToken(dio, user.id);
    }
  }

  void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _registerDeviceToken();
    });
  }

  void _checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _navigateToScreen(message);
    }
  }

  void _navigateToScreen(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toUpperCase();
    final referenceId = data['reference_id'];
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    final navigator = Navigator.of(context);

    if (user.isCustomer) {
      switch (type) {
        case 'ORDER':
        case 'ORDER_STATUS':
          if (referenceId != null && referenceId.isNotEmpty) {
            navigator.push(
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: referenceId),
              ),
            );
          }
          break;
        default:
          break;
      }
    } else if (user.isStaff) {
      switch (type) {
        case 'ORDER':
        case 'ORDER_STATUS':
          navigator.push(
            MaterialPageRoute(builder: (_) => const StaffOrdersScreen()),
          );
          break;
        case 'STOCK':
        case 'INVENTORY':
          navigator.push(
            MaterialPageRoute(builder: (_) => const StaffInventoryScreen()),
          );
          break;
        default:
          break;
      }
    }
  }

}
