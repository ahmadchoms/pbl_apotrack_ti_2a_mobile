import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/customer_repository.dart';
import '../../../../core/network/api_client.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await _dio.get('/orders');
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final response = await _dio.get('/orders/$orderId');
    return response.data['data'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final order = await getOrderById(orderId);
    final items = order?['items'] as List<dynamic>? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required int subtotalAmount,
    required String serviceType,  // DELIVERY | PICK_UP
    required String paymentMethod, // CASH | TRANSFER | E-WALLET
    String? addressId,
    String? notes,
    int shippingCost = 0,
  }) async {
    final response = await _dio.post('/orders', data: {
      'pharmacy_id': pharmacyId,
      'items': items,
      'subtotal_amount': subtotalAmount,
      'service_type': serviceType,
      'payment_method': paymentMethod,
      if (addressId != null) 'address_id': addressId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (serviceType == 'DELIVERY') 'shipping_cost': shippingCost,
    });
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
}

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
});
