import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/medicine.dart';
import '../repositories/medicine_repository.dart';

class StaffMedicineService {
  final StaffMedicineRepository _repository;
  StaffMedicineService(this._repository);

  Future<List<Medicine>> getMedicines({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getMedicines(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => Medicine.fromJson(e)).toList();
  }

  Future<Medicine> getMedicine(String id) async {
    final response = await _repository.getMedicineDetail(id);
    return Medicine.fromJson(response.data['data']);
  }

  Future<Medicine> createMedicine(dynamic payload) async {
    final response = await _repository.createMedicine(payload);
    return Medicine.fromJson(response.data['data']);
  }

  Future<Medicine> updateMedicine(String id, dynamic payload) async {
    final response = await _repository.updateMedicine(id, payload);
    return Medicine.fromJson(response.data['data']);
  }

  Future<void> updateStock(String medicineId, Map<String, dynamic> payload) async {
    await _repository.updateStock(medicineId, payload);
  }

  Future<void> deleteMedicine(String id) async {
    await _repository.deleteMedicine(id);
  }
}

final staffMedicineServiceProvider = Provider<StaffMedicineService>((ref) {
  final repository = ref.watch(staffMedicineRepositoryProvider);
  return StaffMedicineService(repository);
});
