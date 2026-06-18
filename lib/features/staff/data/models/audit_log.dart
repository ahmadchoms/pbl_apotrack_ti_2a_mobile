import 'dart:convert';

class AuditLog {
  final String id;
  final String? userId;
  final String action;
  final String description;
  final String status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final String relativeTime;
  final String? username;

  AuditLog({
    required this.id,
    this.userId,
    required this.action,
    required this.description,
    required this.status,
    this.metadata,
    required this.createdAt,
    required this.relativeTime,
    this.username,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    // Metadata can be a Map or a JSON String depending on the DB driver/Eloquent cast
    Map<String, dynamic>? meta;
    if (json['metadata'] is Map) {
      meta = json['metadata'] as Map<String, dynamic>;
    } else if (json['metadata'] is String) {
      try {
        meta = jsonDecode(json['metadata']) as Map<String, dynamic>;
      } catch (_) {}
    }

    return AuditLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      action: json['action'] ?? 'UNKNOWN',
      description: json['description'] ?? '',
      status: json['status'] ?? 'SUCCESS',
      metadata: meta,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      relativeTime: json['relative_time'] ?? '',
      username: json['user']?['username'],
    );
  }
}
