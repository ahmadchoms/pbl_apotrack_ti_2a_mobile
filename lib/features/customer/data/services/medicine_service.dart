import 'package:dio/dio.dart';

class MedicineService {
  final Dio _dio;

  MedicineService(this._dio);

  Future<List<Map<String, dynamic>>> getMedicines({int? limit}) async {
    final response = await _dio.get('/medicines', queryParameters: {
      if (limit != null) 'per_page': limit,
      'sort_by': 'name',
      'sort_order': 'asc',
    });
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMedicinesByPharmacy(
    String pharmacyId,
  ) async {
    final response = await _dio.get('/medicines', queryParameters: {
      'pharmacy_id': pharmacyId,
    });
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}