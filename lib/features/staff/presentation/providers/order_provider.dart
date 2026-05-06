import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/models/order.dart';
import '../../data/services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});

final ordersByStatusProvider = FutureProvider.family<List<Order>, String>((ref, status) async {
  return ref.watch(orderServiceProvider).getOrders(status: status == 'Semua' ? null : status);
});

final orderDetailProvider = FutureProvider.family<Order, int>((ref, id) async {
  return ref.watch(orderServiceProvider).getOrderDetail(id);
});
