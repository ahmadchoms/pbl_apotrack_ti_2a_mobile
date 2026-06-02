import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../staff/data/models/order.dart';
import '../repositories/customer_repository.dart';

class CustomerOrderService {
  final CustomerRepository _repository;

  CustomerOrderService(this._repository);

  Future<List<Order>> getActiveOrders({int page = 1}) async {
    final res = await _repository.getCustomerOrders(
      {'page': page, 'per_page': 10},
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> getOrderHistory({int page = 1}) async {
    final res = await _repository.getCustomerOrderHistory(
      {'page': page, 'per_page': 15},
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getOrderDetail(String id) async {
    final res = await _repository.getCustomerOrderDetail(id);
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<DeliveryTracking> getOrderTracking(String id) async {
    final res = await _repository.getCustomerOrderTracking(id);
    return DeliveryTracking.fromJson(
        res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> simulatePayment(String id) async {
    final res = await _repository.simulatePayment(id);
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> requestCancellation(String id, String reason) async {
    final res = await _repository.requestCancellation(id, reason);
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Order> confirmReceived(String id) async {
    final res = await _repository.confirmReceived(id);
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final customerOrderServiceProvider = Provider<CustomerOrderService>((ref) {
  return CustomerOrderService(ref.read(customerRepositoryProvider));
});