// mobile/lib/core/models/notification_model.dart
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? referenceId;
  final DateTime createdAt;

  NotificationModel({
    required this.id, required this.title, required this.message,
    required this.type, required this.isRead, this.referenceId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      referenceId: json['reference_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}