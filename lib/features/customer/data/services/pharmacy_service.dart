import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/pharmacy_repository.dart';
import 'package:mobile/core/models/pharmacy.dart';
import '../../presentation/providers/customer_profile_provider.dart';

class PharmacyService {
  PharmacyService({required PharmacyRepository repository}) : _repository = repository;
  final PharmacyRepository _repository;

  Future<List<Map<String, dynamic>>> getPharmacies({Position? userPosition, String? categoryId}) async {
    final response = await _repository.getPharmacies(
      latitude: userPosition?.latitude,
      longitude: userPosition?.longitude,
      radius: 3.0,
      categoryId: categoryId,
    );
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    final parsed = rawList
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
    return parsed.map((e) => e.toJson()).toList();
  }

  Future<List<Pharmacy>> getActivePharmacies({Position? userPosition, String? categoryId}) async {
    final response = await _repository.getPharmacies(
      latitude: userPosition?.latitude,
      longitude: userPosition?.longitude,
      radius: 3.0,
      categoryId: categoryId,
    );
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>?> getPharmacyById(String id) async {
    try {
      final response = await _repository.getPharmacyDetail(id);
      final raw = response.data['data'];
      final pharmacy = Pharmacy.fromJson(
        (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>,
      );
      return pharmacy.toJson();
    } catch (_) {
      return null;
    }
  }

  Future<Pharmacy?> getPharmacyModel(String id) async {
    try {
      final response = await _repository.getPharmacyDetail(id);
      final raw = response.data['data'];
      return Pharmacy.fromJson(
        (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Pharmacy>> searchPharmacies(String query) async {
    final response = await _repository.getPharmacies(search: query);
    final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
    return rawList
        .map((e) => Pharmacy.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final pharmacyServiceProvider = Provider<PharmacyService>((ref) {
  return PharmacyService(repository: ref.watch(pharmacyRepositoryProvider));
});

final activePharmaciesProvider = FutureProvider.family<List<Pharmacy>, String?>((ref, categoryId) {
  final profileState = ref.watch(customerProfileProvider);
  final activeAddr = profileState.tempGpsAddress ?? profileState.addresses.where((a) => a.isPrimary).firstOrNull;

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

  return ref.watch(pharmacyServiceProvider).getActivePharmacies(
    userPosition: position,
    categoryId: categoryId,
  );
});

final pharmacyDetailProvider =
    FutureProvider.family<Pharmacy?, String>((ref, pharmacyId) {
  return ref.watch(pharmacyServiceProvider).getPharmacyModel(pharmacyId);
});
