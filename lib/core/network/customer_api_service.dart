import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/customer/data/models/pharmacy_model.dart';
import '../../features/customer/data/models/medicine_model.dart';
import '../../features/customer/data/models/order_model.dart';
import '../../features/customer/data/models/medicine_category_model.dart';
import 'api_client.dart';
import 'app_exception.dart';

class CustomerApiService {
  CustomerApiService({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<List<Pharmacy>> getPharmacies({
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.get(
        '/pharmacies',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
          if (radius != null) 'radius': radius.toString(),
          if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        },
      );
      final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
      return rawList.map((e) => Pharmacy.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<Pharmacy> getPharmacyDetail(String id) async {
    try {
      final response = await _dio.get('/pharmacies/$id');
      final raw = response.data['data'];
      return Pharmacy.fromJson((raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // ── Medicines ─────────────────────────────────────────────────
  Future<List<Medicine>> getMedicines({
    required String pharmacyId,
    String? categoryId,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/medicines',
        queryParameters: {
          'pharmacy_id': pharmacyId,
          if (categoryId != null && categoryId.isNotEmpty)
            'category_id': categoryId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
      return rawList.map((e) => Medicine.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<MedicineCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
      return rawList.map((e) => MedicineCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<MedicineCategoryModel>> getPopularCategories() async {
    try {
      final response = await _dio.get('/categories/popular');
      final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
      return rawList.map((e) => MedicineCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // ── Orders ────────────────────────────────────────────────────
  Future<Order> createOrder({
    required String pharmacyId,
    required List<Map<String, dynamic>> items,
    required double subtotalAmount,
    required String serviceType,
    required String paymentMethod,
    double? shippingCost,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/orders', data: {
        'pharmacy_id': pharmacyId,
        'items': items,
        'subtotal_amount': subtotalAmount,
        'service_type': serviceType,
        'payment_method': paymentMethod,
        // ignore: use_null_aware_elements
        if (shippingCost != null) 'shipping_cost': shippingCost,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      final raw = response.data['data'];
      return Order.fromJson((raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _dio.get('/orders');
      final rawList = (response.data['data'] as List<dynamic>?) ?? response.data as List<dynamic>;
      return rawList.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  Future<Order> getOrderDetail(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      final raw = response.data['data'];
      return Order.fromJson((raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // TODO: Remove before production release or move to a dedicated TestingApiService.
  Future<Order> simulatePayment(String orderId) async {
    assert(kDebugMode, 'simulatePayment() hanya boleh dipanggil di debug/staging mode.');
    try {
      final response = await _dio.post('/orders/$orderId/simulate-payment');
      final raw = response.data['data'];
      return Order.fromJson((raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }

  // ── Reviews ───────────────────────────────────────────────────
  Future<ReviewResponse> submitReview({
    required String medicineId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post('/reviews', data: {
        'medicine_id': medicineId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      final raw = response.data['data'];
      return ReviewResponse.fromJson((raw as Map<String, dynamic>?) ?? response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    }
  }
}

class ReviewResponse {
  final String id;
  final String medicineId;
  final int rating;
  final String? comment;

  const ReviewResponse({
    required this.id,
    required this.medicineId,
    required this.rating,
    this.comment,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id']?.toString() ?? '',
      medicineId: json['medicine_id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
    );
  }
}

final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomerApiService(dio: dio);
});
