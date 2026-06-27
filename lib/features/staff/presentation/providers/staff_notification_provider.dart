import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/notification_service.dart';

final staffUnreadNotifProvider = StreamProvider<int>((ref) {
  final dio = ref.watch(dioProvider);
  final service = StaffNotificationService(dio);

  Future<int> fetch() async {
    try {
      final notifications = await service.getNotifications();
      return notifications.where((n) {
        final isRead = n['is_read'];
        return isRead == false || isRead == 0 || isRead == '0';
      }).length;
    } catch (_) {
      return 0;
    }
  }

  return (() async* {
    yield await fetch();
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      yield await fetch();
    }
  })();
});
