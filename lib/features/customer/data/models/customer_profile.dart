class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.createdAt,
  });

  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String? createdAt;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    // Handle id - bisa int atau String dari server
    late int id;
    final rawId = json['id'];
    if (rawId is int) {
      id = rawId;
    } else if (rawId is String) {
      id = int.tryParse(rawId) ?? 0;
    } else {
      id = 0;
    }

    return CustomerProfile(
      id: id,
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'unknown@example.com',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'USER',
      createdAt: json['created_at'] as String?,
    );
  }

  /// 2 huruf inisial dari username untuk avatar fallback
  String get initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  CustomerProfile copyWith({
    String? username,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return CustomerProfile(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role,
      createdAt: createdAt,
    );
  }
}
