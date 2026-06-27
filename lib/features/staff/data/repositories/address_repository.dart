import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffAddressRepository {
  final Dio _dio;
  StaffAddressRepository(this._dio);

  Future<Response> getAddresses() => _dio.get('/user/addresses');

  Future<Response> addAddress(Map<String, dynamic> data) =>
      _dio.post('/user/addresses', data: data);

  Future<Response> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      return await _dio.patch('/user/addresses/$id', data: data);
    } on DioException {
      rethrow;
    }
  }

  Future<Response> setPrimaryAddress(String id) async {
    try {
      return await _dio.patch('/user/addresses/$id', data: {'is_primary': true});
    } on DioException {
      rethrow;
    }
  }

  Future<Response> deleteAddress(String id) async {
    try {
      return await _dio.delete('/user/addresses/$id');
    } on DioException {
      rethrow;
    }
  }
}

final staffAddressRepositoryProvider = Provider<StaffAddressRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffAddressRepository(dio);
});
