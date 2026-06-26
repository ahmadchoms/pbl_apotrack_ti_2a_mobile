import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static void Function(String? payload)? onNotificationTap;
  static bool _initialized = false;
  static int _notificationId = 0;

  static const String _channelId = 'apotrack_notifications_v3';
  static const String _channelName = 'ApoTrack Notifications';
  static const String _channelDescription = 'Notifikasi pesanan dan resep ApoTrack';

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
  }

  static Future<void> show({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    _notificationId++;
    final notifId = id ?? _notificationId;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(notifId, title, body, details, payload: payload);
  }
}
