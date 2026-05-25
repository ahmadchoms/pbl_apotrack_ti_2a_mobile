import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/customer_api_service.dart';
import '../models/medicine_model.dart';
import '../models/medicine_category_model.dart';

class MedicineService {
  MedicineService({required CustomerApiService api}) : _api = api;
  final CustomerApiService _api;

  Future<List<MedicineModel>> getMedicinesByPharmacy(
      String pharmacyId) async {
    final data = await _api.getMedicines(pharmacyId: pharmacyId);
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => MedicineModel.fromJson(e))
        .toList();
  }

  Future<List<MedicineModel>> getMedicinesByCategory({
    required String pharmacyId,
    required String categoryId,
  }) async {
    final data = await _api.getMedicines(
        pharmacyId: pharmacyId, categoryId: categoryId);
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => MedicineModel.fromJson(e))
        .toList();
  }

  Future<List<MedicineModel>> searchMedicines({
    required String pharmacyId,
    required String query,
  }) async {
    final data =
        await _api.getMedicines(pharmacyId: pharmacyId, search: query);
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => MedicineModel.fromJson(e))
        .toList();
  }

  Future<List<MedicineCategoryModel>> getCategories() async {
    final data = await _api.getCategories();
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => MedicineCategoryModel.fromJson(e))
        .toList();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final medicineServiceProvider = Provider<MedicineService>((ref) {
  return MedicineService(api: ref.watch(customerApiServiceProvider));
});

final medicinesProvider =
    FutureProvider.family<List<MedicineModel>, String>((ref, pharmacyId) {
  return ref.watch(medicineServiceProvider).getMedicinesByPharmacy(pharmacyId);
});

final medicineCategoriesProvider =
    FutureProvider<List<MedicineCategoryModel>>((ref) {
  return ref.watch(medicineServiceProvider).getCategories();
});
