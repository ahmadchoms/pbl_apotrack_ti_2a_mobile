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
import 'features/customer/presentation/screens/order_detail_screen.dart';
import 'features/customer/presentation/screens/order_history_screen.dart';
import 'features/staff/presentation/screens/staff_orders_screen.dart';
import 'features/staff/presentation/screens/staff_inventory_screen.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

bool get _supportsFcm {
  if (kIsWeb) return false;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;
  return true;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (_supportsFcm) {
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

      if (_supportsFcm) {
        await LocalNotificationService.init();
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
      }
    });
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final title = data['title'] ?? message.notification?.title ?? 'Notifikasi Baru';
      final body = data['body'] ?? message.notification?.body ?? '';

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

    return MaterialApp.router(
      title: 'ApoTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }
}
