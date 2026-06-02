import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffRepository {
  final Dio _dio;
  StaffRepository(this._dio);

  // --- PESANAN (ORDERS) ---
  Future<Response> getOrders(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/orders', queryParameters: queryParams);

  Future<Response> getOrderDetail(String id) =>
      _dio.get('/staff/orders/$id');

  Future<Response> updateOrderStatus(String id, String status) =>
      _dio.patch('/staff/orders/$id/status', data: {'status': status});

  Future<Response> shipOrder(
          String id, String courierCode, String courierService) =>
      _dio.post('/staff/orders/$id/ship', data: {
        'courier_code': courierCode,
        'courier_service': courierService,
      });

  Future<Response> verifyOrderByCode(String verificationCode) =>
      _dio.post('/staff/orders/verify', data: {'verification_code': verificationCode});

  // --- INVENTARIS (MEDICINES) ---
  Future<Response> getMedicines(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/medicines', queryParameters: queryParams);

  Future<Response> getMedicineDetail(String id) =>
      _dio.get('/staff/medicines/$id');

  Future<Response> createMedicine(dynamic data) =>
      _dio.post('/staff/medicines', data: data);

  Future<Response> updateMedicine(String id, dynamic data) {
    if (data is FormData) {
      data.fields.add(MapEntry('_method', 'PUT'));
      return _dio.post('/staff/medicines/$id', data: data);
    }
    return _dio.put('/staff/medicines/$id', data: data);
  }

  Future<Response> updateStock(String id, Map<String, dynamic> data) =>
      _dio.post('/staff/medicines/$id/stock', data: data);

  Future<Response> deleteMedicine(String id) =>
      _dio.delete('/staff/medicines/$id');

  // --- AUDITS & LOGS ---
  Future<Response> getAudits(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/audits', queryParameters: queryParams);

  // --- POINT OF SALE (POS) ---
  Future<Response> storePosOrder(Map<String, dynamic> data) =>
      _dio.post('/staff/pos/orders', data: data);

  // --- PROFIL & KEAMANAN (shared: Customer & Staff) ---
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

  // --- ALAMAT CUSTOMER ---
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

  Future<Response> deleteAddress(String id) async {
    try {
      return await _dio.delete('/user/addresses/$id');
    } on DioException {
      rethrow;
    }
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffRepository(dio);
});