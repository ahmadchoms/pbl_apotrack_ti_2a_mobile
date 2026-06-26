import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  Future<OrderModel> createOrder({
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

    final response = await _dio.post('/orders', data: {
      'pharmacy_id': pharmacyId,
      'items': apiItems,
      'subtotal_amount': subtotal.toInt(),
      'service_type': serviceType,
      'payment_method': paymentMethod,
      // ignore: use_null_aware_elements
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> getOrderById(String orderId) async {
    final response = await _dio.get('/orders/$orderId');
    return OrderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _dio.get('/orders');
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderModel>> getActiveOrders() async {
    final all = await getMyOrders();
    return all
        .where((o) =>
            o.orderStatus == 'PENDING' ||
            o.orderStatus == 'PROCESSING' ||
            o.orderStatus == 'READY_FOR_PICKUP')
        .toList();
  }

  Future<Map<String, dynamic>> simulatePayment(String orderId) async {
    final response = await _dio.post('/orders/$orderId/simulate-payment');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> uploadPrescription(String orderId, File file) async {
    final formData = FormData.fromMap({
      'prescription_image': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    await _dio.post('/orders/$orderId/prescription', data: formData);
  }

  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/reviews', data: {
      'order_id': orderId,
      'rating': rating,
      // ignore: use_null_aware_elements
      if (comment != null) 'comment': comment,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
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
