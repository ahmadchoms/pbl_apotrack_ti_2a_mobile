import 'dart:html' as html;
import 'secure_storage_service.dart';

class LocalStorageBackend implements StorageBackend {
  static const String _prefix = 'apotrack_';

  @override
  Future<String?> read(String key) async {
    return html.window.localStorage['$_prefix$key'];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage['$_prefix$key'] = value;
  }

  @override
  Future<void> delete(String key) async {
    html.window.localStorage.remove('$_prefix$key');
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.keys
        .where((k) => k.startsWith(_prefix))
        .toList()
        .forEach(html.window.localStorage.remove);
  }
}

StorageBackend getWebStorage() => LocalStorageBackend();
