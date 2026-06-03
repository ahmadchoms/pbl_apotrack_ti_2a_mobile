import 'dart:html' as html;
import 'secure_storage_service.dart';

class LocalStorageBackend implements StorageBackend {
  @override
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}

StorageBackend getWebStorage() => LocalStorageBackend();
