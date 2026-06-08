import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/customer_api_service.dart';
import '../models/order_model.dart';

class OrderService {
  OrderService({required CustomerApiService api}) : _api = api;
  final CustomerApiService _api;

  Future<OrderModel> createOrder({
    required String pharmacyId,
    required String serviceType,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double subtotal,
    required double shippingCost,
    String? addressId,
    String? notes,
    double? distanceKm,
  }) async {
    final apiItems = items
        .map((item) => {
              'id': item.medicineId,
              'quantity': item.quantity,
              'price': item.price.toDouble(),
            })
        .toList();

    final result = await _api.createOrder(
      pharmacyId: pharmacyId,
      items: apiItems,
      subtotalAmount: subtotal,
      serviceType: serviceType,
      paymentMethod: paymentMethod,
      shippingCost: shippingCost,
      notes: notes,
    );

    return OrderModel.fromJson(result);
  }

  Future<OrderModel> getOrderById(String orderId) async {
    final result = await _api.getOrderDetail(orderId);
    return OrderModel.fromJson(result);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final data = await _api.getOrders();
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final data = await _api.getOrders();
    final all = data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return all
        .where((o) =>
            o.orderStatus == 'PENDING' ||
            o.orderStatus == 'PROCESSING' ||
            o.orderStatus == 'SHIPPED' ||
            o.orderStatus == 'READY_FOR_PICKUP')
        .toList();
  }

  Future<void> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    throw UnimplementedError('Cancel via API not yet available');
  }

  /// Simulasi pembayaran via API
  Future<Map<String, dynamic>> simulatePayment(String orderId) async {
    return await _api.simulatePayment(orderId);
  }

  /// Kirim ulasan via API
  Future<Map<String, dynamic>> submitReview({
    required String medicineId,
    required int rating,
    String? comment,
  }) async {
    return await _api.submitReview(
      medicineId: medicineId,
      rating: rating,
      comment: comment,
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(api: ref.watch(customerApiServiceProvider));
});

final myOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).getMyOrders();
});

final activeOrdersProvider = FutureProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).getActiveOrders();
});

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).getOrderById(orderId);
});
