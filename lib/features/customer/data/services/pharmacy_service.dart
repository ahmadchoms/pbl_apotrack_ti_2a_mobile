import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/customer_api_service.dart';
import '../models/pharmacy_model.dart';
import '../../presentation/providers/customer_profile_provider.dart';

class PharmacyService {
  PharmacyService({required CustomerApiService api}) : _api = api;
  final CustomerApiService _api;

  Future<List<Map<String, dynamic>>> getPharmacies({
    Position? userPosition,
    String? categoryId,
  }) async {
    final data = await _api.getPharmacies(
      latitude: userPosition?.latitude,
      longitude: userPosition?.longitude,
      radius: 20.0,
      categoryId: categoryId,
    );
    return data.map((e) => e.toJson()).toList();
  }

  Future<List<PharmacyModel>> getActivePharmacies({
    Position? userPosition,
    String? categoryId,
  }) async {
    final data = await _api.getPharmacies(
      latitude: userPosition?.latitude,
      longitude: userPosition?.longitude,
      radius: 20.0,
      categoryId: categoryId,
    );
    return data.map((e) => PharmacyModel.fromJson(e.toJson())).toList();
  }

  Future<Map<String, dynamic>?> getPharmacyById(String id) async {
    try {
      final pharmacy = await _api.getPharmacyDetail(id);
      return pharmacy.toJson();
    } catch (_) {
      return null;
    }
  }

  Future<PharmacyModel?> getPharmacyModel(String id) async {
    try {
      final pharmacy = await _api.getPharmacyDetail(id);
      return PharmacyModel.fromJson(pharmacy.toJson());
    } catch (_) {
      return null;
    }
  }

  Future<List<PharmacyModel>> searchPharmacies(String query) async {
    final data = await _api.getPharmacies(search: query);
    return data.map((e) => PharmacyModel.fromJson(e.toJson())).toList();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  return PharmacyService(api: ref.watch(customerApiServiceProvider));
});

final activePharmaciesProvider =
    FutureProvider.family<List<PharmacyModel>, String?>((ref, categoryId) {
      final profileState = ref.watch(customerProfileProvider);
      final activeAddr =
          profileState.tempGpsAddress ??
          profileState.addresses.where((a) => a.isPrimary).firstOrNull;

      Position? position;
      if (activeAddr != null) {
        position = Position(
          latitude: activeAddr.latitude,
          longitude: activeAddr.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      return ref
          .watch(pharmacyServiceProvider)
          .getActivePharmacies(userPosition: position, categoryId: categoryId);
    });

final pharmacyDetailProvider = FutureProvider.family<PharmacyModel?, String>((
  ref,
  pharmacyId,
) {
  return ref.watch(pharmacyServiceProvider).getPharmacyModel(pharmacyId);
});
