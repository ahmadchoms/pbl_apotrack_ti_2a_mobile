import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class CustomerRepository {
  final Dio _dio;
  CustomerRepository(this._dio);

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
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomerRepository(dio);
});