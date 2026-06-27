import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/medicine_repository.dart';
import 'package:mobile/core/models/medicine.dart';
import 'package:mobile/core/models/medicine_category.dart';

class MedicineService {
  MedicineService({required MedicineRepository repository}) : _repository = repository;
  final MedicineRepository _repository;

  Future<List<Medicine>> getMedicinesByPharmacy(String pharmacyId) async {
    final response = await _repository.getMedicines(pharmacyId: pharmacyId);
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Medicine>> getMedicinesByCategory({
    required String pharmacyId,
    required String categoryId,
  }) async {
    final response = await _repository.getMedicines(
      pharmacyId: pharmacyId,
      categoryId: categoryId,
    );
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Medicine>> searchMedicines({
    required String pharmacyId,
    required String query,
  }) async {
    final response = await _repository.getMedicines(
      pharmacyId: pharmacyId,
      search: query,
    );
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicineCategory>> getCategories() async {
    final response = await _repository.getCategories();
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => MedicineCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final medicineServiceProvider = Provider<MedicineService>((ref) {
  return MedicineService(repository: ref.watch(medicineRepositoryProvider));
});

final medicinesProvider =
    FutureProvider.family<List<Medicine>, String>((ref, pharmacyId) {
  return ref.watch(medicineServiceProvider).getMedicinesByPharmacy(pharmacyId);
});

final medicineCategoriesProvider =
    FutureProvider<List<MedicineCategory>>((ref) {
  return ref.watch(medicineServiceProvider).getCategories();
});
