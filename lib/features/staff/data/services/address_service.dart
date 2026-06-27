import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/customer_address.dart';
import '../repositories/address_repository.dart';

class StaffAddressService {
  final StaffAddressRepository _repository;
  StaffAddressService(this._repository);

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await _repository.getAddresses();
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memuat alamat',
      );
    }
  }

  Future<CustomerAddress> addAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _repository.addAddress({
        'label': label,
        'address_detail': addressDetail,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': isPrimary,
      });
      return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal menambah alamat',
      );
    }
  }

  Future<CustomerAddress> updateAddress({
    required String id,
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    try {
      final response = await _repository.updateAddress(id, {
        'label': label,
        'address_detail': addressDetail,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': isPrimary,
      });
      return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memperbarui alamat',
      );
    }
  }

  Future<void> setPrimaryAddress(String id) async {
    try {
      await _repository.setPrimaryAddress(id);
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal mengatur alamat utama',
      );
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _repository.deleteAddress(id);
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal menghapus alamat',
      );
    }
  }

  String? _extractLaravelError(dynamic errorBody) {
    if (errorBody == null) return null;
    if (errorBody is Map) {
      if (errorBody['message'] != null) return errorBody['message'].toString();
      if (errorBody['errors'] is Map) {
        final errors = errorBody['errors'] as Map;
        final firstKey = errors.keys.first;
        final firstError = errors[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return errorBody.toString();
  }
}

final staffAddressServiceProvider = Provider<StaffAddressService>((ref) {
  final repository = ref.watch(staffAddressRepositoryProvider);
  return StaffAddressService(repository);
});
