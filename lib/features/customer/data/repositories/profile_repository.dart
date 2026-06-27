import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository({required Dio dio}) : _dio = dio;

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

  Future<Response> joinStaffByInvitation(String invitationUrl) =>
      _dio.post('/staff/join', data: {'invitation_url': invitationUrl});

  Future<Response> joinStaffByPin(String pin) =>
      _dio.post('/staff/join', data: {'pin': pin});
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio: dio);
});
