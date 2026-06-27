import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class PharmacyRepository {
  final Dio _dio;
  PharmacyRepository({required Dio dio}) : _dio = dio;

  Future<Response> getPharmacies({
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
  }) => _dio.get(
        '/pharmacies',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
          if (radius != null) 'radius': radius.toString(),
          if (categoryId != null && categoryId.isNotEmpty)
            'category_id': categoryId,
        },
      );

  Future<Response> getPharmacyDetail(String id) => _dio.get('/pharmacies/$id');
}

final pharmacyRepositoryProvider = Provider<PharmacyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PharmacyRepository(dio: dio);
});
