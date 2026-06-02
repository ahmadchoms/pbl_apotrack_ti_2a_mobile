import 'package:dio/dio.dart';

class PharmacyService {
  final Dio _dio;

  PharmacyService(this._dio);

  Future<List<Map<String, dynamic>>> getPharmacies() async {
    final response = await _dio.get('/pharmacies');
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getPharmacyById(String id) async {
    final response = await _dio.get('/pharmacies/$id');
    return response.data['data'] as Map<String, dynamic>?;
  }
}
