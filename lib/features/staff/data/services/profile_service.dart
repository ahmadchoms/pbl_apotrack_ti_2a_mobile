import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/user_model.dart';
import '../repositories/profile_repository.dart';

class StaffProfileService {
  final StaffProfileRepository _repository;
  StaffProfileService(this._repository);

  Future<UserModel> getProfile() async {
    try {
      final response = await _repository.fetchMe();
      final data = response.data['data'] ?? response.data;
      return UserModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memuat profil',
      );
    }
  }

  Future<UserModel> updateProfile({
    required String username,
    required String email,
    String? phone,
    dynamic imageFile,
  }) async {
    final formData = FormData.fromMap({
      'username': username,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });

    if (imageFile != null) {
      final path = imageFile is String ? imageFile : imageFile.path;
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(path, filename: 'profile.jpg'),
        ),
      );
    }

    try {
      final response = await _repository.updateProfile(formData);
      return UserModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal memperbarui profil',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _repository.changePassword({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(
        _extractLaravelError(e.response?.data) ?? 'Gagal mengubah password',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
  }

  String? _extractLaravelError(dynamic errorBody) {
    if (errorBody == null) return null;
    if (errorBody is Map) {
      if (errorBody['message'] != null) return errorBody['message'].toString();
      if (errorBody['errors'] is Map) {
        final errors = errorBody['errors'] as Map;
        final firstKey = errors.keys.first;
        final firstError = errors[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return errorBody.toString();
  }
}

final staffProfileServiceProvider = Provider<StaffProfileService>((ref) {
  final repository = ref.watch(staffProfileRepositoryProvider);
  return StaffProfileService(repository);
});
