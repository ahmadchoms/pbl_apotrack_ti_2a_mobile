import 'package:dio/dio.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await _dio.get('/notifications', queryParameters: {
      'per_page': 50,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }
}
