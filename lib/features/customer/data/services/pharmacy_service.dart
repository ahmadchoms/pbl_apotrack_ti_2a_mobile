import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/customer_api_service.dart';
import '../models/pharmacy_model.dart';

class PharmacyService {
  PharmacyService({required CustomerApiService api}) : _api = api;
  final CustomerApiService _api;

  /// Ambil semua apotek aktif
  Future<List<Map<String, dynamic>>> getPharmacies() async {
    final data = await _api.getPharmacies();
    return data.cast<Map<String, dynamic>>();
  }

  /// Ambil semua apotek aktif sebagai PharmacyModel
  Future<List<PharmacyModel>> getActivePharmacies() async {
    final data = await _api.getPharmacies();
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => PharmacyModel.fromJson(e))
        .toList();
  }

  /// Ambil detail apotek by id — return raw map
  Future<Map<String, dynamic>?> getPharmacyById(String id) async {
    try {
      return await _api.getPharmacyDetail(id);
    } catch (_) {
      return null;
    }
  }

  /// Ambil detail apotek by id sebagai PharmacyModel
  Future<PharmacyModel?> getPharmacyModel(String id) async {
    try {
      final data = await _api.getPharmacyDetail(id);
      return PharmacyModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Cari apotek berdasarkan nama
  Future<List<PharmacyModel>> searchPharmacies(String query) async {
    final data = await _api.getPharmacies(search: query);
    return data
        .cast<Map<String, dynamic>>()
        .map((e) => PharmacyModel.fromJson(e))
        .toList();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  return PharmacyService(api: ref.watch(customerApiServiceProvider));
});

final activePharmaciesProvider = FutureProvider<List<PharmacyModel>>((ref) {
  return ref.watch(pharmacyServiceProvider).getActivePharmacies();
});

final pharmacyDetailProvider =
    FutureProvider.family<PharmacyModel?, String>((ref, pharmacyId) {
  return ref.watch(pharmacyServiceProvider).getPharmacyModel(pharmacyId);
});
