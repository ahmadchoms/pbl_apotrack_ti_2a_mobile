import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key constants untuk semua item yang disimpan di secure storage.
abstract class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
}

/// Riverpod Provider untuk instance FlutterSecureStorage.
/// Menggunakan singleton agar tidak ada instance ganda.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Helper class untuk mengabstraksi operasi FlutterSecureStorage
/// agar kode lebih bersih dan mudah di-mock saat testing.
class SecureStorageService {
  SecureStorageService(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> getToken() => _storage.read(key: StorageKeys.authToken);
  Future<void> saveToken(String token) =>
      _storage.write(key: StorageKeys.authToken, value: token);
  Future<void> deleteToken() => _storage.delete(key: StorageKeys.authToken);

  Future<String?> getUserRole() => _storage.read(key: StorageKeys.userRole);
  Future<void> saveUserRole(String role) =>
      _storage.write(key: StorageKeys.userRole, value: role);

  Future<void> clearAll() => _storage.deleteAll();
}

/// Provider untuk SecureStorageService.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});
