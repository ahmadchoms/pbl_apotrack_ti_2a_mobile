class MedicineModel {
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

  // Dari join tabel
  final String? categoryName;
  final String? typeName;
  final String? unitName;
  final String? formName;

  const MedicineModel({
    required this.id,
    required this.pharmacyId,
    required this.categoryId,
    required this.formId,
    required this.typeId,
    required this.unitId,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.description,
    required this.dosageInfo,
    required this.price,
    required this.requiresPrescription,
    required this.weightInGrams,
    this.imageUrl,
    required this.isActive,
    this.totalActiveStock = 0,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.typeName,
    this.unitName,
    this.formName,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] as String,
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      formId: json['form_id'] as String? ?? '',
      typeId: json['type_id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? '',
      name: json['name'] as String,
      genericName: json['generic_name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dosageInfo: json['dosage_info'] as String? ?? '',
      price: double.parse((json['price'] ?? 0).toString()),
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      weightInGrams:
          double.parse((json['weight_in_grams'] ?? 0).toString()),
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      totalActiveStock: (json['total_active_stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      // Dari join (Supabase) atau langsung (Laravel API)
      categoryName: json['medicine_categories'] != null
          ? json['medicine_categories']['name'] as String?
          : json['category'] as String?,
      typeName: json['medicine_types'] != null
          ? json['medicine_types']['name'] as String?
          : json['type'] as String?,
      unitName: json['medicine_units'] != null
          ? json['medicine_units']['name'] as String?
          : json['unit'] as String?,
      formName: json['medicine_forms'] != null
          ? json['medicine_forms']['name'] as String?
          : json['form'] as String?,
    );
  }
}

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

  // Dari join tabel
  final String? categoryName;
  final String? typeName;
  final String? unitName;
  final String? formName;

  const Medicine({
    required this.id,
    required this.pharmacyId,
    required this.categoryId,
    required this.formId,
    required this.typeId,
    required this.unitId,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.description,
    required this.dosageInfo,
    required this.price,
    required this.requiresPrescription,
    required this.weightInGrams,
    this.imageUrl,
    required this.isActive,
    this.totalActiveStock = 0,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.typeName,
    this.unitName,
    this.formName,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? '',
      formId: json['form_id'] as String? ?? '',
      typeId: json['type_id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      genericName: json['generic_name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dosageInfo: json['dosage_info'] as String? ?? '',
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      requiresPrescription: json['requires_prescription'] == true || json['requires_prescription'] == 1,
      weightInGrams: double.tryParse((json['weight_in_grams'] ?? 0).toString()) ?? 0.0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      totalActiveStock: (json['total_active_stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      categoryName: json['medicine_categories'] != null
          ? json['medicine_categories']['name'] as String?
          : json['category'] as String?,
      typeName: json['medicine_types'] != null
          ? json['medicine_types']['name'] as String?
          : json['type'] as String?,
      unitName: json['medicine_units'] != null
          ? json['medicine_units']['name'] as String?
          : json['unit'] as String?,
      formName: json['medicine_forms'] != null
          ? json['medicine_forms']['name'] as String?
          : json['form'] as String?,
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
}