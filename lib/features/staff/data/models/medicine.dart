import 'package:flutter/material.dart';

class Medicine {
  final int id;
  final String name;
  final String? genericName;
  final String? description;
  final String? dosage;
  final String? sideEffects;
  final num price;
  final int totalActiveStock;
  final bool requiresPrescription;
  final bool isActive;
  final String? category;
  final String? form;
  final String? type;
  final String? unit;
  final String? imageUrl;
  final DateTime? createdAt;

  // UI UI Helpers (not from API)
  final Color accentColor;
  final IconData icon;

  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.description,
    this.dosage,
    this.sideEffects,
    required this.price,
    required this.totalActiveStock,
    this.requiresPrescription = false,
    this.isActive = true,
    this.category,
    this.form,
    this.type,
    this.unit,
    this.imageUrl,
    this.createdAt,
    this.accentColor = const Color(0xFF1D70F5),
    this.icon = Icons.medication_rounded,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      genericName: json['generic_name'],
      description: json['description'],
      dosage: json['dosage'],
      sideEffects: json['side_effects'],
      price: json['price'] ?? 0,
      totalActiveStock: json['total_active_stock'] ?? 0,
      requiresPrescription: json['requires_prescription'] ?? false,
      isActive: json['is_active'] ?? true,
      category: json['category'] is Map ? json['category']['name'] : json['category'],
      form: json['form'] is Map ? json['form']['name'] : json['form'],
      type: json['type'] is Map ? json['type']['name'] : json['type'],
      unit: json['unit'] is Map ? json['unit']['name'] : json['unit'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      accentColor: _getAccentColor(json['category']),
      icon: _getIcon(json['category']),
    );
  }

  static Color _getAccentColor(dynamic category) {
    final catName = category is Map ? category['name'] : category.toString();
    if (catName.contains('Antibiotik')) return const Color(0xFF6366F1);
    if (catName.contains('Analgesik')) return const Color(0xFF10B981);
    if (catName.contains('Sirup')) return const Color(0xFFF59E0B);
    return const Color(0xFF1D70F5);
  }

  static IconData _getIcon(dynamic category) {
    final catName = category is Map ? category['name'] : category.toString();
    if (catName.contains('Sirup')) return Icons.water_drop_rounded;
    if (catName.contains('Antibiotik')) return Icons.local_pharmacy_rounded;
    return Icons.medication_rounded;
  }
}
