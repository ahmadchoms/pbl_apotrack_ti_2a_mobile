import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/local_notification_service.dart';
import 'routes/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/customer/presentation/providers/customer_order_provider.dart';
import 'features/customer/presentation/screens/order_detail_screen.dart';
import 'features/customer/presentation/screens/order_history_screen.dart';
import 'features/staff/presentation/screens/staff_orders_screen.dart';
import 'features/staff/presentation/screens/staff_inventory_screen.dart';
import 'features/staff/presentation/providers/staff_provider.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

bool get _supportsFcm {
  if (kIsWeb) return false;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;
  return true;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (DefaultFirebaseOptions.android.apiKey.isNotEmpty) {
      if (message.notification != null) {
        // OS will automatically display notifications containing a notification block.
        // Avoid creating a duplicate local notification.
        return;
      }
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await LocalNotificationService.init();
      final data = message.data;
      await LocalNotificationService.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: (data['title'] ?? 'Notifikasi Baru') as String,
        body: (data['body'] ?? '') as String,
        payload: data.toString(),
      );
    }
  } catch (e) {
    debugPrint('Error in background message handler: $e');
  }
}

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      bool firebaseInitialized = false;
      if (_supportsFcm) {
        try {
          if (DefaultFirebaseOptions.android.apiKey.isNotEmpty) {
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
            firebaseInitialized = true;
          } else {
            debugPrint('Firebase API Key is empty. Skipping Firebase initialization.');
          }
        } catch (e) {
          debugPrint('Failed to initialize Firebase: $e');
        }
      }

      await initializeDateFormatting('id_ID', null);

      if (_supportsFcm && firebaseInitialized) {
        try {
          await LocalNotificationService.init();
        } catch (e) {
          debugPrint('Failed to initialize Local Notification Service: $e');
        }
      }

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
      if (_supportsFcm) {
        _setupForegroundListener();
        _setupBackgroundTapListener();
        _checkInitialMessage();
        _setupTokenRefresh();

        // Register token if user is already logged in at startup
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final dio = ref.read(dioProvider);
          PushNotificationService.updateDeviceToken(dio, user.id);
        }
      }
    });
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final title = data['title'] ?? message.notification?.title ?? 'Notifikasi Baru';
      final body = data['body'] ?? message.notification?.body ?? '';

      // Auto-refresh order data if push notification indicates an order update
      final type = (data['type'] ?? '').toString().toUpperCase();
      final referenceId = data['reference_id']?.toString();

      if (type == 'STAFF_REMOVED') {
        LocalNotificationService.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: data.toString(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navContext = AppRouter.navigatorKey.currentContext;
          if (navContext != null) {
            showDialog(
              context: navContext,
              barrierDismissible: false,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                content: Text(body),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop(); // Dismiss dialog
                      ref.read(authNotifierProvider.notifier).restoreSession();
                      ref.read(profileProvider.notifier).loadAll();
                      ref.read(AppRouter.routerProvider).go(AppRouter.splash);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
        return;
      }

      if (type == 'ORDER' || type == 'ORDER_STATUS') {
        // Refresh active/history order lists
        ref.read(customerOrderProvider.notifier).loadAll();
        // Refresh the detail screen of the specific order if it is open
        if (referenceId != null && referenceId.isNotEmpty) {
          ref.invalidate(orderDetailProvider(referenceId));
        }
      }

      LocalNotificationService.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: data.toString(),
      );
    });
  }

  void _setupBackgroundTapListener() {
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateToScreen);
    LocalNotificationService.onNotificationTap = (payload) {
      if (payload == null || payload.isEmpty) return;
      final navContext = AppRouter.navigatorKey.currentContext;
      if (navContext == null) return;
      try {
        final data = _parsePayload(payload);
        _navigateByData(context: navContext, data: data);
      } catch (_) {}
    };
  }

  void _navigateByData({required BuildContext context, required Map<String, dynamic> data}) {
    final type = (data['type'] ?? '').toString().toUpperCase();
    final referenceId = data['reference_id'];

    if (type == 'STAFF_REMOVED') {
      final title = data['title'] ?? 'Pemberhentian Staff';
      final body = data['message'] ?? data['body'] ?? 'Anda telah diberhentikan sebagai staff di apotek.';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(); // Dismiss dialog
                ref.read(authNotifierProvider.notifier).restoreSession();
                ref.read(profileProvider.notifier).loadAll();
                ref.read(AppRouter.routerProvider).go(AppRouter.splash);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final navigator = Navigator.of(context);
    if (user.isCustomer) {
      switch (type) {
        case 'ORDER':
        case 'ORDER_STATUS':
          if (referenceId != null && referenceId.toString().isNotEmpty) {
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
            navigator.push(
              MaterialPageRoute(
                builder: (_) => CustomerOrderDetailScreen(orderId: referenceId.toString()),
              ),
            );
          }
          break;
      }
    } else if (user.isStaff) {
      switch (type) {
        case 'ORDER':
        case 'ORDER_STATUS':
          navigator.push(MaterialPageRoute(builder: (_) => const StaffOrdersScreen()));
          break;
        case 'STOCK':
        case 'INVENTORY':
          navigator.push(MaterialPageRoute(builder: (_) => const StaffInventoryScreen()));
          break;
      }
    }
  }

  Map<String, dynamic> _parsePayload(String payload) {
    final map = <String, dynamic>{};
    for (final entry in payload.replaceAll('{', '').replaceAll('}', '').split(', ')) {
      final parts = entry.split(': ');
      if (parts.length == 2) map[parts[0]] = parts[1];
    }
    return map;
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
      if (!context.mounted) return;
      _navigateToScreen(message);
    }
  }

  void _navigateToScreen(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toUpperCase();
    final referenceId = data['reference_id'];

    if (type == 'STAFF_REMOVED') {
      final title = data['title'] ?? message.notification?.title ?? 'Pemberhentian Staff';
      final body = data['message'] ?? data['body'] ?? message.notification?.body ?? 'Anda telah diberhentikan sebagai staff di apotek.';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(); // Dismiss dialog
                ref.read(authNotifierProvider.notifier).restoreSession();
                ref.read(profileProvider.notifier).loadAll();
                ref.read(AppRouter.routerProvider).go(AppRouter.splash);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);

    if (user == null) return;

    final navigator = Navigator.of(context);

    if (user.isCustomer) {
      switch (type) {
        case 'ORDER':
        case 'ORDER_STATUS':
          if (referenceId != null && referenceId.isNotEmpty) {
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
            navigator.push(
              MaterialPageRoute(
                builder: (_) => CustomerOrderDetailScreen(orderId: referenceId),
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

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);

    ref.listen(currentUserProvider, (previous, next) {
      if (next != null && _supportsFcm) {
        final dio = ref.read(dioProvider);
        PushNotificationService.updateDeviceToken(dio, next.id);
      }
    });

    return MaterialApp.router(
      title: 'ApoTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }
}
