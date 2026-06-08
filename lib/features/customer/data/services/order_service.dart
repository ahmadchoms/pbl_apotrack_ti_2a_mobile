import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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
    required String serviceType,
    required String paymentMethod,
    String? addressId,
    String? notes,
    int shippingCost = 0,
    String? courierCode,
    String? courierService,
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
      if (courierCode != null) 'courier_code': courierCode,
      if (courierService != null) 'courier_service': courierService,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getShippingRates({
    required String pharmacyId,
    required String addressId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post('/shipping-rates', data: {
      'pharmacy_id': pharmacyId,
      'address_id': addressId,
      'items': items,
    });
    return (response.data['data'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  Future<void> uploadPrescription(
      String orderId, Uint8List bytes, String filename) async {
    final contentType = _guessContentType(filename);
    final formData = FormData.fromMap({
      'prescription_image': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    });
    await _dio.post('/orders/$orderId/prescription', data: formData);
  }

  Future<Map<String, dynamic>> simulatePayment(String orderId) async {
    final response = await _dio.post('/orders/$orderId/simulate-payment');
    return response.data['data'] as Map<String, dynamic>;
  }

  MediaType? _guessContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return null;
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
});
