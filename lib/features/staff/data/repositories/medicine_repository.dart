import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffMedicineRepository {
  final Dio _dio;
  StaffMedicineRepository(this._dio);

  Future<Response> getMedicines(Map<String, dynamic>? queryParams) =>
      _dio.get('/staff/medicines', queryParameters: queryParams);

  Future<Response> getMedicineDetail(String id) =>
      _dio.get('/staff/medicines/$id');

  Future<Response> createMedicine(dynamic data) =>
      _dio.post('/staff/medicines', data: data);

  Future<Response> updateMedicine(String id, dynamic data) {
    if (data is FormData) {
      data.fields.add(MapEntry('_method', 'PUT'));
      return _dio.post('/staff/medicines/$id', data: data);
    }
    return _dio.put('/staff/medicines/$id', data: data);
  }

  Future<Response> updateStock(String id, Map<String, dynamic> data) =>
      _dio.post('/staff/medicines/$id/stock', data: data);

  Future<Response> deleteMedicine(String id) =>
      _dio.delete('/staff/medicines/$id');
}

final staffMedicineRepositoryProvider = Provider<StaffMedicineRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffMedicineRepository(dio);
});
