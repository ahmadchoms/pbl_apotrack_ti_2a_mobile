import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

/// Base URL server Laravel.
/// Override at build time: flutter run --dart-define=API_BASE_URL=https://api.example.com
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.19.38:8000/api',
);

/// Riverpod Provider untuk instance Dio yang sudah terkonfigurasi penuh.
final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);

  // Penanganan otomatis untuk Android Emulator
  String baseUrl = _kBaseUrl;
  if (!kIsWeb && Platform.isAndroid && baseUrl.contains('127.0.0.1')) {
    baseUrl = baseUrl.replaceFirst('127.0.0.1', '10.0.2.2');
  }

  return _buildDio(storageService, baseUrl);
});

/// Factory function yang membangun Dio dengan semua konfigurasi.
Dio _buildDio(SecureStorageService storageService, String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Pasang interceptor autentikasi & logging
  dio.interceptors.addAll([
    _AuthInterceptor(storageService),
    if (kDebugMode) _LoggingInterceptor(),
  ]);

  return dio;
}

// ─────────────────────────────────────────────
// AUTH INTERCEPTOR
// Otomatis menyisipkan Bearer token ke setiap request
// ─────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storageService);
  final SecureStorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Transformasi error menjadi pesan yang lebih ramah
    final appError = _mapDioError(err);
    return handler.next(appError);
  }

  DioException _mapDioError(DioException err) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        message = 'Koneksi timeout. Periksa jaringan Anda.';
        break;
      case DioExceptionType.connectionError:
        message =
            'Tidak dapat terhubung ke server. Pastikan server sedang berjalan.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        if (statusCode == 401) {
          message =
              'Sesi tidak valid atau telah berakhir. Silakan masuk kembali.';
          // Auto-clear invalid token so router redirects to login
          _storageService.clearAll();
        } else if (statusCode == 422) {
          // Laravel validation error — ambil pesan pertama dari errors map
          final errors = responseData?['errors'];
          if (errors is Map && errors.isNotEmpty) {
            message = (errors.values.first as List).first.toString();
          } else {
            message =
                responseData?['message'] ?? 'Data yang dikirim tidak valid.';
          }
        } else if (statusCode == 403) {
          message = 'Anda tidak memiliki izin untuk melakukan aksi ini.';
        } else if (statusCode == 404) {
          message = 'Data atau endpoint tidak ditemukan.';
        } else if (statusCode != null && statusCode >= 500) {
          message =
              responseData?['message'] as String? ??
              'Terjadi kesalahan pada server. Coba lagi nanti.';
        } else {
          message =
              responseData?['message'] ??
              'Terjadi kesalahan yang tidak diketahui.';
        }
        break;
      default:
        message = 'Terjadi kesalahan jaringan.';
    }
    return err.copyWith(message: message);
  }
}

// ─────────────────────────────────────────────
// LOGGING INTERCEPTOR (Debug Mode Only)
// ─────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─────────── [REQUEST] ───────────');
    debugPrint('│ ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    debugPrint('└─────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─────────── [RESPONSE ${response.statusCode}] ───────────');
    debugPrint('│ ${response.requestOptions.uri}');
    debugPrint('└─────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─────────── [ERROR] ───────────');
    debugPrint('│ ${err.requestOptions.uri}');
    debugPrint('│ ${err.message}');
    debugPrint('└────────────────────────────────');
    handler.next(err);
  }
}

/// Legacy ApiClient singleton has been REMOVED.
/// All code should use `dioProvider` which includes auth interceptor.
/// If you were importing this file for ApiClient, use dioProvider instead:
///   final dio = ref.watch(dioProvider);
