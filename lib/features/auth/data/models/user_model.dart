/// Model data untuk pengguna yang terautentikasi.
class UserModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final String? pharmacyName;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.pharmacyName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Ekstraksi Nama Apotek (Cek apakah dia String atau Map)
    String? pName;
    final rawPharmacyName = json['pharmacy_name'];

    if (rawPharmacyName is String) {
      pName = rawPharmacyName;
    } else if (json['pharmacy_staff'] != null &&
        json['pharmacy_staff'] is Map) {
      final staff = json['pharmacy_staff'] as Map<String, dynamic>;
      final pharmacy = staff['pharmacy'];
      if (pharmacy != null && pharmacy is Map) {
        pName = pharmacy['name']?.toString();
      }
    }

    // 2. Ekstraksi Avatar (Pastikan bukan Map)
    String? avatar;
    if (json['avatar_url'] is String) {
      avatar = json['avatar_url'] as String;
    }

    // 3. Ekstraksi Phone (Cek beberapa kemungkinan key)
    final phone = json['phone']?.toString() ?? json['phone_number']?.toString();

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      phone: phone,
      pharmacyName: pName,
      avatarUrl: avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'phone': phone,
      'pharmacy_name': pharmacyName,
      'avatar_url': avatarUrl,
    };
  }

  bool get isStaff =>
      role == 'STAFF' ||
      role == 'APOTEKER' ||
      email.toLowerCase().contains('@apotek');
  bool get isCustomer =>
      role == 'USER' && !email.toLowerCase().contains('@apotek');

  String get initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase();
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? phone,
    String? pharmacyName,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: $role, phone: $phone, pharmacyName: $pharmacyName, avatarUrl: $avatarUrl)';
  }
}
