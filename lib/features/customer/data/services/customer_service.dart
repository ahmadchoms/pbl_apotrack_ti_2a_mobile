import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_profile.dart';
import '../models/customer_address.dart';
import '../repositories/customer_repository.dart';

class CustomerService {
  CustomerService(this._repository);
  final CustomerRepository _repository;

  // Profile

  Future<CustomerProfile> getProfile() async {
    try {
      final response = await _repository.fetchMe();
      final data = response.data['data'] ?? response.data;
      return CustomerProfile.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      print('[Service] getProfile error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<CustomerProfile> updateProfile({
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
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: 'profile.jpg',
          ),
        ),
      );
    }

    final response = await _repository.updateProfile(formData);
    return CustomerProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword({
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
  }

  // Addresses

  Future<List<CustomerAddress>> getAddresses() async {
    try {
      final response = await _repository.getAddresses();
      print('[Service] getAddresses response: ${response.data}');
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      print('[Service] getAddresses error: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<CustomerAddress> addAddress({
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    final response = await _repository.addAddress({
      'label': label,
      'address_detail': addressDetail,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    });
    return CustomerAddress.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerAddress> updateAddress({
    required String id,
    required String label,
    required String addressDetail,
    required double latitude,
    required double longitude,
    bool isPrimary = false,
  }) async {
    print('[Service] updateAddress id=$id isPrimary=$isPrimary');
    try {
      final response = await _repository.updateAddress(id, {
        'label': label,
        'address_detail': addressDetail,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': isPrimary,
      });
      return CustomerAddress.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final errorBody = e.response?.data;
      print('[Service] updateAddress error ${e.response?.statusCode}: $errorBody');
      final message = _extractLaravelError(errorBody) ?? 'Gagal memperbarui alamat';
      throw Exception(message);
    }
  }

  Future<void> setPrimaryAddress(String id) async {
    print('[Service] setPrimaryAddress id=$id');
    try {
      await _repository.setPrimaryAddress(id);
      print('[Service] setPrimaryAddress success');
    } on DioException catch (e) {
      final errorBody = e.response?.data;
      print('[Service] setPrimaryAddress error ${e.response?.statusCode}: $errorBody');
      final message = _extractLaravelError(errorBody) ?? 'Gagal mengatur alamat utama';
      throw Exception(message);
    }
  }

  Future<void> deleteAddress(String id) async {
    print('[Service] deleteAddress id=$id');
    try {
      final response = await _repository.deleteAddress(id);
      print('[Service] deleteAddress success: ${response.statusCode}');
    } on DioException catch (e) {
      final errorBody = e.response?.data;
      print('[Service] deleteAddress error ${e.response?.statusCode}: $errorBody');
      final message = _extractLaravelError(errorBody) ?? 'Gagal menghapus alamat';
      throw Exception(message);
    }
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

final customerServiceProvider = Provider<CustomerService>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerService(repository);
});