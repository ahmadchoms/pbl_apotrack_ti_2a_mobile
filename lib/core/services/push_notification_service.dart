import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static String _detectDeviceType() {
    if (kIsWeb) return 'web';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) return 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
      if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    } catch (_) {}
    return 'unknown';
  }

  static Future<void> updateDeviceToken(Dio dio, String userId) async {
    try {
      String? token = await _fcm.getToken();
      debugPrint('[FCM] Token: $token');

      if (token == null) return;

      final response = await dio.post(
        '/devices/token',
        data: {
          'user_id': userId,
          'fcm_token': token,
          'device_type': _detectDeviceType(),
        },
      );
      debugPrint('[FCM] Token registered: ${response.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }
}
