import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class MedicineRepository {
  final Dio _dio;
  MedicineRepository({required Dio dio}) : _dio = dio;

  Future<Response> getMedicines({
    required String pharmacyId,
    String? categoryId,
    String? search,
  }) => _dio.get(
        '/medicines',
        queryParameters: {
          'pharmacy_id': pharmacyId,
          if (categoryId != null && categoryId.isNotEmpty)
            'category_id': categoryId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

  Future<Response> getCategories() => _dio.get('/categories');

  Future<Response> getPopularCategories() => _dio.get('/categories/popular');
}

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MedicineRepository(dio: dio);
});
