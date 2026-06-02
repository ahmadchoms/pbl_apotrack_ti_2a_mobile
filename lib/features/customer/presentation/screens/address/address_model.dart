import '../../../data/models/customer_address.dart';

/// Model untuk satu alamat tersimpan
class AddressModel {
  final String id;
  final String name;       // nama label, mis. "Rumah", "Kantor"
  final String fullAddress;
  final String? landmark;  // patokan
  final AddressType type;  // personal / bisnis
  final bool isPrimary;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    this.landmark,
    this.type = AddressType.personal,
    this.isPrimary = false,
    this.latitude,
    this.longitude,
  });

  AddressModel copyWith({
    String? id,
    String? name,
    String? fullAddress,
    String? landmark,
    AddressType? type,
    bool? isPrimary,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      landmark: landmark ?? this.landmark,
      type: type ?? this.type,
      isPrimary: isPrimary ?? this.isPrimary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory AddressModel.fromCustomerAddress(CustomerAddress addr) {
    return AddressModel(
      id: addr.id,
      name: addr.label,
      fullAddress: addr.completeAddress ?? addr.addressDetail,
      isPrimary: addr.isPrimary,
      latitude: addr.latitude,
      longitude: addr.longitude,
    );
  }
}

enum AddressType { personal, bisnis }

