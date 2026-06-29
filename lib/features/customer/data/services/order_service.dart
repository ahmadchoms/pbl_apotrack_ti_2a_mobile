import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/order.dart';
import '../repositories/order_repository.dart';

class CustomerOrderService {
  final OrderRepository _repository;

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

  // Merged from old OrderService
  Future<Order> createOrder({
    required String pharmacyId,
    required String serviceType,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double subtotal,
    String? notes,
  }) async {
    final apiItems = items
        .map((item) => {
              'id': item.medicineId,
              'quantity': item.quantity,
              'price': item.price.toDouble(),
            })
        .toList();

    final res = await _repository.createOrder({
      'pharmacy_id': pharmacyId,
      'items': apiItems,
      'subtotal_amount': subtotal.toInt(),
      'service_type': serviceType,
      'payment_method': paymentMethod,
      // ignore: use_null_aware_elements
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Order.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> uploadPrescription(
    String orderId,
    Uint8List bytes, {
    String? fileName,
    String? doctorName,
    String? patientName,
    String? issuedDate,
  }) async {
    final formData = FormData.fromMap({
      'prescription_image': MultipartFile.fromBytes(
        bytes,
        filename: fileName ?? 'resep.jpg',
      ),
      if (doctorName != null) 'doctor_name': doctorName,
      if (patientName != null) 'patient_name': patientName,
      if (issuedDate != null) 'issued_date': issuedDate,
    });
    await _repository.uploadPrescription(orderId, formData);
  }

  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final res = await _repository.submitReview({
      'order_id': orderId,
      'rating': rating,
      // ignore: use_null_aware_elements
      if (comment != null) 'comment': comment,
    });
    return res.data['data'] as Map<String, dynamic>;
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────
final customerOrderServiceProvider = Provider<CustomerOrderService>((ref) {
  return CustomerOrderService(ref.read(orderRepositoryProvider));
});

// Alias for backward compatibility
final orderServiceProvider = customerOrderServiceProvider;

final myOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(customerOrderServiceProvider).getOrderHistory();
});

final activeOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(customerOrderServiceProvider).getActiveOrders();
});

typedef OrderService = CustomerOrderService;
