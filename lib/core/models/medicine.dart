import 'package:flutter/material.dart';
import 'package:mobile/core/network/api_client.dart';

class Medicine {
  final String id;
  final String pharmacyId;
  final String categoryId;
  final String formId;
  final String typeId;
  final String unitId;
  final String name;
  final String genericName;
  final String manufacturer;
  final String description;
  final String dosageInfo;
  final double price;
  final bool requiresPrescription;
  final double weightInGrams;
  final String? imageUrl;
  final bool isActive;
  final int totalActiveStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? categoryName;
  final String? typeName;
  final String? unitName;
  final String? formName;
  final List<Map<String, dynamic>>? batches;

  // UI Helpers
  final Color accentColor;
  final IconData icon;

  const Medicine({
    required this.id,
    this.pharmacyId = '',
    this.categoryId = '',
    this.formId = '',
    this.typeId = '',
    this.unitId = '',
    required this.name,
    this.genericName = '',
    this.manufacturer = '',
    this.description = '',
    this.dosageInfo = '',
    required this.price,
    this.requiresPrescription = false,
    this.weightInGrams = 0.0,
    this.imageUrl,
    this.isActive = true,
    this.totalActiveStock = 0,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.typeName,
    this.unitName,
    this.formName,
    this.batches,
    this.accentColor = const Color(0xFF1D70F5),
    this.icon = Icons.medication_rounded,
  });

  // Getters for staff backward compatibility
  String? get category => categoryName;
  String? get type => typeName;
  String? get form => formName;
  String? get unit => unitName;
  String? get dosage => dosageInfo;
  String? get sideEffects => ''; // Default empty since not used in customer

  factory Medicine.fromJson(Map<String, dynamic> json) {
    final catName = json['medicine_categories'] != null
        ? json['medicine_categories']['name'] as String?
        : json['category'] is Map 
            ? json['category']['name'] as String?
            : json['category']?.toString();

    final typeName = json['medicine_types'] != null
        ? json['medicine_types']['name'] as String?
        : json['type'] is Map 
            ? json['type']['name'] as String?
            : json['type']?.toString();

    final unitName = json['medicine_units'] != null
        ? json['medicine_units']['name'] as String?
        : json['unit'] is Map 
            ? json['unit']['name'] as String?
            : json['unit']?.toString();

    final formName = json['medicine_forms'] != null
        ? json['medicine_forms']['name'] as String?
        : json['form'] is Map 
            ? json['form']['name'] as String?
            : json['form']?.toString();

    return Medicine(
      id: json['id']?.toString() ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      formId: json['form_id']?.toString() ?? '',
      typeId: json['type_id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      genericName: json['generic_name']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      dosageInfo: json['dosage_info']?.toString() ?? json['dosage']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      requiresPrescription: json['requires_prescription'] == true || json['requires_prescription'] == 1,
      weightInGrams: double.tryParse(json['weight_in_grams']?.toString() ?? '0.0') ?? 0.0,
      imageUrl: resolveImageUrl(json['image_url']?.toString()),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      totalActiveStock: (num.tryParse(json['total_active_stock']?.toString() ?? json['stock']?.toString() ?? '0') ?? 0).toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      categoryName: catName,
      typeName: typeName,
      unitName: unitName,
      formName: formName,
      batches: json['batches'] != null ? List<Map<String, dynamic>>.from(json['batches']) : null,
      accentColor: _getAccentColor(catName),
      icon: _getIcon(catName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'category_id': categoryId,
      'form_id': formId,
      'type_id': typeId,
      'unit_id': unitId,
      'name': name,
      'generic_name': genericName,
      'manufacturer': manufacturer,
      'description': description,
      'dosage_info': dosageInfo,
      'price': price,
      'requires_prescription': requiresPrescription,
      'weight_in_grams': weightInGrams,
      'image_url': imageUrl,
      'is_active': isActive,
      'total_active_stock': totalActiveStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': categoryName,
      'type': typeName,
      'unit': unitName,
      'form': formName,
    };
  }

  static Color _getAccentColor(String? catName) {
    if (catName == null) return const Color(0xFF1D70F5);
    if (catName.contains('Antibiotik')) return const Color(0xFF6366F1);
    if (catName.contains('Analgesik')) return const Color(0xFF10B981);
    if (catName.contains('Sirup')) return const Color(0xFFF59E0B);
    return const Color(0xFF1D70F5);
  }

  static IconData _getIcon(String? catName) {
    if (catName == null) return Icons.medication_rounded;
    if (catName.contains('Sirup')) return Icons.water_drop_rounded;
    if (catName.contains('Antibiotik')) return Icons.local_pharmacy_rounded;
    return Icons.medication_rounded;
  }
}

// Typedef alias for backward compatibility
typedef MedicineModel = Medicine;
