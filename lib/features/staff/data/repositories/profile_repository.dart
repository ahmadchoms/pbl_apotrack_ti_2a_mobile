import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class StaffProfileRepository {
  final Dio _dio;
  StaffProfileRepository(this._dio);

  Future<Response> fetchMe() => _dio.get('/me');

  Future<Response> updateProfile(dynamic data) {
    if (data is FormData) {
      data.fields.add(const MapEntry('_method', 'PUT'));
      return _dio.post('/profile', data: data);
    }
    return _dio.put('/profile', data: data);
  }

  Future<Response> changePassword(Map<String, dynamic> data) =>
      _dio.put('/password', data: data);

  Future<Response> logout() => _dio.post('/auth/logout');
}

final staffProfileRepositoryProvider = Provider<StaffProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffProfileRepository(dio);
});
