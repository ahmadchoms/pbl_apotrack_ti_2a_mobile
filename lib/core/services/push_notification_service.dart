import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static bool get _isSupported {
    if (kIsWeb) return false;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return false;
    return true;
  }

  static Future<void> updateDeviceToken(Dio dio, String userId) async {
    if (!_isSupported) return;

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('[FCM] Token is null, waiting for onTokenRefresh...');
        await _registerOnRefresh(dio, userId);
        return;
      }

      await _postToken(dio, userId, token);
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
    }
  }

  static Future<void> _postToken(Dio dio, String userId, String token) async {
    final deviceType = Platform.isAndroid ? 'android' : 'ios';
    await dio.post(
      '/devices/token',
      data: {
        'user_id': userId,
        'fcm_token': token,
        'device_type': deviceType,
      },
    );
    debugPrint('[FCM] Token registered: $token');
  }

  static Future<void> _registerOnRefresh(Dio dio, String userId) async {
    final completer = Completer<void>();
    StreamSubscription? sub;
    sub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _postToken(dio, userId, newToken);
      await sub?.cancel();
      completer.complete();
    });
    return completer.future.timeout(const Duration(seconds: 30));
  }
}
