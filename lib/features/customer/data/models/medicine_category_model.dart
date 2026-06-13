class MedicineCategoryModel {
  final String id;
  final String name;

  const MedicineCategoryModel({
    required this.id,
    required this.name,
  });

  factory MedicineCategoryModel.fromJson(Map<String, dynamic> json) {
    return MedicineCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}