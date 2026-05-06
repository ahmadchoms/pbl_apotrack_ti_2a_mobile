import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Attach bearer token if available
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Global error handling logic
    String errorMessage = 'Terjadi kesalahan sistem';

    if (err.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Koneksi terputus, periksa internet Anda';
    } else if (err.response != null) {
      final statusCode = err.response?.statusCode;
      if (statusCode == 401) {
        errorMessage = 'Sesi habis, silakan login kembali';
        // Handle logout/navigation to login if needed
      } else if (statusCode == 422) {
        // Validation error from Laravel
        errorMessage = err.response?.data['message'] ?? 'Data tidak valid';
      }
    }

    // You could show a snackbar or log errors here
    print('API Error: $errorMessage');
    
    return handler.next(err);
  }
}
