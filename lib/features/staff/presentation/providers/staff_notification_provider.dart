import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/staff_notification_service.dart';

final staffUnreadNotifProvider = FutureProvider<int>((ref) async {
  final dio = ref.watch(dioProvider);
  final service = StaffNotificationService(dio);
  final notifications = await service.getNotifications();
  return notifications.where((n) {
    final isRead = n['is_read'];
    return isRead == false || isRead == 0 || isRead == '0';
  }).length;
});
