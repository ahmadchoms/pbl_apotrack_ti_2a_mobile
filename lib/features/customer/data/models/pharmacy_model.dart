class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? logoUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final String verificationStatus; // VERIFIED, PENDING, REJECTED
  final int totalReviews;
  final bool isActive;
  final bool isForceClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.logoUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.verificationStatus,
    this.totalReviews = 0,
    required this.isActive,
    this.isForceClosed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Apotek dianggap buka jika: aktif, verified, dan tidak force closed
  bool get isOpen =>
      isActive && verificationStatus == 'VERIFIED' && !isForceClosed;

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      logoUrl: json['logo_url'] as String?,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      rating: double.parse(json['rating'].toString()),
      verificationStatus: (json['verification_status'] as String?) ?? 'PENDING',
      totalReviews: (json['total_reviews'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      isForceClosed: (json['is_force_closed'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone ?? '',
      'logo_url': logoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'verification_status': verificationStatus,
      'total_reviews': totalReviews,
      'is_active': isActive,
      'is_force_closed': isForceClosed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}