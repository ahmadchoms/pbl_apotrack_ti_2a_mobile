class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.addressDetail,
    this.completeAddress,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
  });

  final String id;
  final String label;
  final String addressDetail;
  final String? completeAddress;
  final double latitude;
  final double longitude;
  final bool isPrimary;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String? ?? 'Unknown',
      addressDetail: json['address_detail'] as String? ?? '',
      completeAddress: json['complete_address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  String get displayAddress => completeAddress ?? addressDetail;
}
