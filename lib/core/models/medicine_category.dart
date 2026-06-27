class MedicineCategory {
  final String id;
  final String name;

  const MedicineCategory({
    required this.id,
    required this.name,
  });

  factory MedicineCategory.fromJson(Map<String, dynamic> json) {
    return MedicineCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

// Typedef alias for backward compatibility
typedef MedicineCategoryModel = MedicineCategory;
