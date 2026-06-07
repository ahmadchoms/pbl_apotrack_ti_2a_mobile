import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/customer_address.dart';

class AddressService {
  final Dio _dio;

  AddressService(this._dio);

  Future<List<CustomerAddress>> getAddresses() async {
    final response = await _dio.get('/user/addresses');
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerAddress> createAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    final response = await _dio.post('/user/addresses', data: {
      'label': label,
      'address_detail': addressDetail,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    });
    return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<CustomerAddress> updateAddress({
    required String id,
    String? label,
    String? addressDetail,
    double? latitude,
    double? longitude,
    bool? isPrimary,
  }) async {
    final response = await _dio.patch('/user/addresses/$id', data: {
      if (label != null) 'label': label,
      if (addressDetail != null) 'address_detail': addressDetail,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (isPrimary != null) 'is_primary': isPrimary,
    });
    return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> setPrimary(String id) async {
    await _dio.patch('/user/addresses/$id/set-primary');
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('/user/addresses/$id');
  }
}

final addressServiceProvider = Provider<AddressService>((ref) {
  final dio = ref.watch(dioProvider);
  return AddressService(dio);
});
