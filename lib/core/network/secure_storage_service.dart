import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';

/// Key constants untuk semua item yang disimpan di secure storage.
abstract class StorageKeys {
  static const String authToken = 'auth_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
  static const String userData = 'user_data';
}

/// Platform-agnostic storage abstraction.
abstract class StorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Native implementation using FlutterSecureStorage.
class NativeStorageBackend implements StorageBackend {
  NativeStorageBackend(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Web implementation using in-memory Map.
class WebStorageBackend implements StorageBackend {
  final _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }
}

/// Riverpod Provider untuk StorageBackend (auto-switch based on platform).
final storageBackendProvider = Provider<StorageBackend>((ref) {
  if (kIsWeb) {
    return getWebStorage();
  }
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return NativeStorageBackend(storage);
});

/// Helper class untuk mengabstraksi operasi storage.
class SecureStorageService {
  SecureStorageService(this._backend);
  final StorageBackend _backend;

  Future<String?> getToken() => _backend.read(StorageKeys.authToken);
  Future<void> saveToken(String token) =>
      _backend.write(StorageKeys.authToken, token);
  Future<void> deleteToken() => _backend.delete(StorageKeys.authToken);

  Future<String?> getUserRole() => _backend.read(StorageKeys.userRole);
  Future<void> saveUserRole(String role) =>
      _backend.write(StorageKeys.userRole, role);

  Future<String?> getUserData() => _backend.read(StorageKeys.userData);
  Future<void> saveUserData(String data) =>
      _backend.write(StorageKeys.userData, data);

  Future<void> clearAll() => _backend.deleteAll();
}

/// Provider untuk SecureStorageService.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final backend = ref.watch(storageBackendProvider);
  return SecureStorageService(backend);
});
