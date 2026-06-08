import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> updateDeviceToken(Dio dio, String userId) async {
    String? token = await _fcm.getToken();

    if (token != null) {
      try {
        await dio.post(
          '/devices/token',
          data: {
            'user_id': userId,
            'fcm_token': token,
            'device_type': 'android',
          },
        );
      } catch (_) {}
    }
  }
}
