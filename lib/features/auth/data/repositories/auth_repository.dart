import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode, this.originalError});
  final String message;
  final int? statusCode;
  final dynamic originalError;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': emailOrPhone.trim(), 'password': password},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Login gagal.');
    }
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email.trim()});
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AuthException('Email tidak terdaftar di sistem kami.');
      }
      throw AuthException(e.message ?? 'Gagal mengirim instruksi reset.');
    }
  }

  Future<void> requestRegistrationOtp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/register/request-otp',
        data: {
          'username': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password.trim(),
        },
      );
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Gagal mengirim OTP.');
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Kode OTP salah atau kadaluarsa.');
    }
  }

  Future<UserModel> fetchMe() async {
    try {
      final response = await _dio.get('/me');
      final data = response.data['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw AuthException(
        e.message ?? 'Gagal mengambil profil.',
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile(dynamic data) async {
    try {
      final response = await _dio.post('/profile', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AuthException(e.message ?? 'Gagal memperbarui profil.');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio: dio);
});
