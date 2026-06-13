import 'package:dio/dio.dart';

class PharmacyService {
  final Dio _dio;

  PharmacyService(this._dio);

  Future<List<Map<String, dynamic>>> getPharmacies({double? latitude, double? longitude, String? search}) async {
    final params = <String, dynamic>{};
    if (latitude != null) params['latitude'] = latitude;
    if (longitude != null) params['longitude'] = longitude;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _dio.get('/pharmacies', queryParameters: params.isNotEmpty ? params : null);
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getPharmacyById(String id) async {
    final response = await _dio.get('/pharmacies/$id');
    return response.data['data'] as Map<String, dynamic>?;
  }
}
