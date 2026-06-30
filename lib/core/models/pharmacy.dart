import 'package:mobile/core/network/api_client.dart';

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? logoUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final String verificationStatus;
  final int totalReviews;
  final bool isActive;
  final bool isForceClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pharmacy({
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

  bool get isOpen =>
      isActive && verificationStatus == 'VERIFIED' && !isForceClosed;

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
      logoUrl: resolveImageUrl(json['logo_url'] as String?),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      verificationStatus: json['verification_status'] as String? ?? 'PENDING',
      totalReviews: json['total_reviews'] as int? ?? 0,
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['verification_status'] == 'VERIFIED',
      isForceClosed:
          json['is_force_closed'] == true || json['is_force_closed'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
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

// Typedef alias for backward compatibility
typedef PharmacyModel = Pharmacy;
