import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/secure_storage_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Service untuk menangani logika bisnis otentikasi.
/// Menghubungkan AuthRepository (API) dengan SecureStorageService (Lokal).
class AuthService {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthService(this._repository, this._storage);

  /// Melakukan login dan menyimpan token serta informasi user.
  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final result = await _repository.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    // Simpan token, role, dan data user ke storage lokal
    await _storage.saveToken(result['token']);
    final user = UserModel.fromJson(result['user']);
    await _storage.saveUserRole(user.role);
    await _storage.saveUserData(jsonEncode(result['user']));

    return user;
  }

  /// Melakukan logout dan membersihkan storage lokal.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Abaikan error logout API, tetap bersihkan storage lokal
    } finally {
      await _storage.clearAll();
    }
  }

  /// Memulihkan sesi user dari token yang tersimpan.
  Future<UserModel?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    try {
      final user = await _repository.fetchMe();
      await _storage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      int? statusCode;
      dynamic originalError = e;

      if (e is AuthException) {
        statusCode = e.statusCode;
        originalError = e.originalError;
      } else if (e is DioException) {
        statusCode = e.response?.statusCode;
      }

      // Hapus sesi hanya jika token expired/invalid (401), bukan error jaringan
      if (statusCode == 401) {
        await _storage.clearAll();
        return null;
      }

      // Untuk error jaringan/timeout, coba pakai data user yang di-cache
      if (originalError is DioException) {
        final cached = await _storage.getUserData();
        if (cached != null) {
          try {
            return UserModel.fromJson(
              jsonDecode(cached) as Map<String, dynamic>,
            );
          } catch (_) {
            // cached data corrupted
          }
        }
      }
      return null;
    }
  }

  /// Finalisasi pendaftaran setelah verifikasi OTP.
  Future<UserModel?> finalizeRegistration({
    required String email,
    required String otp,
  }) async {
    final result = await _repository.verifyRegistrationOtp(
      email: email,
      otp: otp,
    );

    final token = result['token']?.toString();
    if (token != null) {
      await _storage.saveToken(token);
      final userMap = result['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final user = UserModel.fromJson(userMap);
        await _storage.saveUserRole(user.role);
        await _storage.saveUserData(jsonEncode(userMap));
        return user;
      }
    }
    return null;
  }

  // --- Proxy ke Repository (Logic tanpa storage) ---

  Future<void> forgotPassword({required String email}) async {
    await _repository.forgotPassword(email: email);
  }

  Future<void> requestRegistrationOtp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _repository.requestRegistrationOtp(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<UserModel> fetchMe() async {
    return await _repository.fetchMe();
  }

  Future<Map<String, dynamic>> updateProfile(dynamic payload) async {
    return await _repository.updateProfile(payload);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthService(repository, storage);
});
