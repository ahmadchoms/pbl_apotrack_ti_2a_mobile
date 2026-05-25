import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class CustomerApiService {
  CustomerApiService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  // ── Pharmacies ────────────────────────────────────────────────
  Future<List<dynamic>> getPharmacies({String? search}) async {
    final response = await _dio.get(
      '/pharmacies',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPharmacyDetail(String id) async {
    final response = await _dio.get('/pharmacies/$id');
    final raw = response.data['data'];
    return (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>;
  }

  // ── Medicines ─────────────────────────────────────────────────
  Future<List<dynamic>> getMedicines({
    required String pharmacyId,
    String? categoryId,
    String? search,
  }) async {
    final response = await _dio.get(
      '/medicines',
      queryParameters: {
        'pharmacy_id': pharmacyId,
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
  }

  // ── Categories ────────────────────────────────────────────────
  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/categories');
    return (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
  }

  // ── Orders ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required double subtotalAmount,
    required String serviceType,
    required String paymentMethod,
    double? shippingCost,
    String? notes,
  }) async {
    final response = await _dio.post('/orders', data: {
      'pharmacy_id': pharmacyId,
      'items': items,
      'subtotal_amount': subtotalAmount,
      'service_type': serviceType,
      'payment_method': paymentMethod,
      if (shippingCost != null) 'shipping_cost': shippingCost,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final raw = response.data['data'];
    return (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getOrders() async {
    final response = await _dio.get('/orders');
    return (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final response = await _dio.get('/orders/$id');
    final raw = response.data['data'];
    return (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> simulatePayment(String orderId) async {
    final response = await _dio.post('/orders/$orderId/simulate-payment');
    final raw = response.data['data'];
    return (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>;
  }

  // ── Reviews ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitReview({
    required String medicineId,
    required int rating,
    String? comment,
  }) async {
    final response = await _dio.post('/reviews', data: {
      'medicine_id': medicineId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    final raw = response.data['data'];
    return (raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>;
  }
}

final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomerApiService(dio: dio);
});
