import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/order.dart';
import '../repositories/order_repository.dart';

class StaffOrderService {
  final StaffOrderRepository _repository;
  StaffOrderService(this._repository);

  Future<List<Order>> getOrders({Map<String, dynamic>? queryParams}) async {
    final response = await _repository.getOrders(queryParams);
    final list = response.data['data'] as List? ?? [];
    return list.map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> getOrderDetail(String orderId) async {
    final response = await _repository.getOrderDetail(orderId);
    return Order.fromJson(response.data['data']);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _repository.updateOrderStatus(orderId, status);
  }

  Future<void> shipOrder(String orderId) async {
    await _repository.shipOrder(orderId);
  }

  Future<void> simulateTracking(String orderId, String status) async {
    await _repository.simulateTracking(orderId, status);
  }

  Future<Order> verifyOrderByCode(String verificationCode) async {
    final response = await _repository.verifyOrderByCode(verificationCode);
    return Order.fromJson(response.data['data']);
  }

  Future<void> approveCancellation(String orderId) async {
    await _repository.approveCancellation(orderId);
  }

  Future<void> rejectCancellation(String orderId) async {
    await _repository.rejectCancellation(orderId);
  }

  Future<Order> storePosOrder(Map<String, dynamic> payload) async {
    final response = await _repository.storePosOrder(payload);
    return Order.fromJson(response.data['data']);
  }
}

final staffOrderServiceProvider = Provider<StaffOrderService>((ref) {
  final repository = ref.watch(staffOrderRepositoryProvider);
  return StaffOrderService(repository);
});
