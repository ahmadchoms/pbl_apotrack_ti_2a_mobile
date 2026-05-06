import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/models/medicine.dart';
import '../../data/services/medicine_service.dart';

final medicineServiceProvider = Provider<MedicineService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MedicineService(apiClient);
});

final medicineListProvider = AsyncNotifierProvider<MedicineListNotifier, List<Medicine>>(() {
  return MedicineListNotifier();
});

class MedicineListNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    return ref.read(medicineServiceProvider).getMedicines();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(medicineServiceProvider).getMedicines());
  }
}
