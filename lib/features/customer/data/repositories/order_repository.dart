import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class OrderRepository {
  final Dio _dio;
  OrderRepository({required Dio dio}) : _dio = dio;

  Future<Response> getCustomerOrders(Map<String, dynamic>? queryParams) =>
      _dio.get('/orders', queryParameters: queryParams);

  Future<Response> getCustomerOrderHistory(Map<String, dynamic>? queryParams) =>
      _dio.get('/orders/history', queryParameters: queryParams);

  Future<Response> getCustomerOrderDetail(String id) => _dio.get('/orders/$id');

  Future<Response> simulatePayment(String id) =>
      _dio.post('/orders/$id/simulate-payment');

  Future<Response> requestCancellation(String id, String reason) =>
      _dio.post('/orders/$id/cancel', data: {'reason': reason});

  Future<Response> confirmReceived(String id) =>
      _dio.post('/orders/$id/confirm-received');

  Future<Response> createOrder(Map<String, dynamic> data) =>
      _dio.post('/orders', data: data);

  Future<Response> uploadPrescription(String orderId, FormData data) =>
      _dio.post('/orders/$orderId/prescription', data: data);

  Future<Response> submitReview(Map<String, dynamic> data) =>
      _dio.post('/reviews', data: data);
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepository(dio: dio);
});
