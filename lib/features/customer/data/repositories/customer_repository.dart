import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class CustomerRepository {
  final Dio _dio;
  CustomerRepository({required Dio dio}) : _dio = dio;

  // ── Order methods ────────────────────────────────────────────
  Future<Response> getCustomerOrders(Map<String, dynamic>? queryParams) =>
      _dio.get('/orders', queryParameters: queryParams);

  Future<Response> getCustomerOrderHistory(
          Map<String, dynamic>? queryParams) =>
      _dio.get('/orders/history', queryParameters: queryParams);

  Future<Response> getCustomerOrderDetail(String id) =>
      _dio.get('/orders/$id');

  Future<Response> getCustomerOrderTracking(String id) =>
      _dio.get('/orders/$id/tracking');

  Future<Response> simulatePayment(String id) =>
      _dio.post('/orders/$id/simulate-payment');

  Future<Response> requestCancellation(String id, String reason) =>
      _dio.post('/orders/$id/cancel', data: {'reason': reason});

  Future<Response> confirmReceived(String id) =>
      _dio.post('/orders/$id/confirm-received');

  Future<Response> joinStaffByInvitation(String invitationUrl) =>
    _dio.post('/staff/join', data: {'invitation_url': invitationUrl});

  // ── Profile methods ──────────────────────────────────────────
  Future<Response> fetchMe() => _dio.get('/me');

  Future<Response> updateProfile(dynamic data) {
    if (data is FormData) {
      data.fields.add(const MapEntry('_method', 'PUT'));
      return _dio.post('/profile', data: data);
    }
    return _dio.put('/profile', data: data);
  }

  Future<Response> changePassword(Map<String, dynamic> data) =>
      _dio.put('/password', data: data);

  Future<Response> logout() => _dio.post('/auth/logout');

  // ── Address methods ──────────────────────────────────────────
  Future<Response> getAddresses() => _dio.get('/user/addresses');

  Future<Response> addAddress(Map<String, dynamic> data) =>
      _dio.post('/user/addresses', data: data);

  Future<Response> updateAddress(String id, Map<String, dynamic> data) async {
    print('[Repository] updateAddress PATCH /user/addresses/$id');
    print('[Repository] payload: $data');
    try {
      final response = await _dio.patch('/user/addresses/$id', data: data);
      print('[Repository] updateAddress success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('[Repository] updateAddress error: ${e.response?.statusCode}');
      print('[Repository] error body: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> setPrimaryAddress(String id) async {
    print('[Repository] setPrimaryAddress PATCH /user/addresses/$id');
    try {
      final response = await _dio.patch('/user/addresses/$id', data: {'is_primary': true});
      print('[Repository] setPrimaryAddress success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('[Repository] setPrimaryAddress error: ${e.response?.statusCode}');
      print('[Repository] error body: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> deleteAddress(String id) async {
    print('[Repository] deleteAddress DELETE /user/addresses/$id');
    try {
      final response = await _dio.delete('/user/addresses/$id');
      print('[Repository] deleteAddress success: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('[Repository] deleteAddress error: ${e.response?.statusCode}');
      print('[Repository] error body: ${e.response?.data}');
      rethrow;
    }
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomerRepository(dio: dio);
});