import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffOrderRepository {
  final Dio _dio;
  StaffOrderRepository(this._dio);

  Future<Response> getOrders(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/orders', queryParameters: queryParams);

  Future<Response> getOrderDetail(String id) =>
      _dio.get('/staff/orders/$id');

  Future<Response> updateOrderStatus(String id, String status) =>
      _dio.patch('/staff/orders/$id/status', data: {'status': status});

  Future<Response> shipOrder(String id) =>
      _dio.post('/staff/orders/$id/ship');

  Future<Response> simulateTracking(String id, String status) =>
      _dio.post('/staff/orders/$id/simulate-tracking/$status');

  Future<Response> verifyOrderByCode(String verificationCode) =>
      _dio.post('/staff/orders/verify', data: {'verification_code': verificationCode});

  Future<Response> approveCancellation(String id) =>
      _dio.post('/staff/orders/$id/approve-cancellation');

  Future<Response> rejectCancellation(String id) =>
      _dio.post('/staff/orders/$id/reject-cancellation');

  Future<Response> storePosOrder(Map<String, dynamic> data) =>
      _dio.post('/staff/pos/orders', data: data);
}

final staffOrderRepositoryProvider = Provider<StaffOrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffOrderRepository(dio);
});
