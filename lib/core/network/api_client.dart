import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state_provider.dart';
import 'app_exception.dart';
import 'secure_storage_service.dart';

/// Base URL server Laravel.
/// Override at build time: flutter run --dart-define=API_BASE_URL=https://api.example.com
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

/// Riverpod Provider untuk instance Dio yang sudah terkonfigurasi penuh.
final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);

  // Penanganan otomatis untuk Android Emulator
  String baseUrl = _kBaseUrl;
  if (!kIsWeb && Platform.isAndroid && baseUrl.contains('127.0.0.1')) {
    baseUrl = baseUrl.replaceFirst('127.0.0.1', '10.0.2.2');
  }

  return _buildDio(storageService, ref, baseUrl);
});

/// Factory function yang membangun Dio dengan semua konfigurasi.
Dio _buildDio(SecureStorageService storageService, Ref ref, String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  // Pasang interceptor autentikasi & logging
  dio.interceptors.addAll([
    _AuthInterceptor(storageService, ref),
    if (kDebugMode) _LoggingInterceptor(),
  ]);

  return dio;
}

// ─────────────────────────────────────────────
// AUTH INTERCEPTOR
// Otomatis menyisipkan Bearer token ke setiap request
// ─────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storageService, this._ref);
  final SecureStorageService _storageService;
  final Ref _ref;
  bool _isHandling401 = false;

  static String? _resolvedBaseUrl;
  static bool _isResolving = false;
  static Completer<String>? _resolutionCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Dynamic IP discovery for local development in debug mode on physical devices/emulators
    if (kDebugMode &&
        !kIsWeb &&
        (options.baseUrl.contains('localhost') ||
            options.baseUrl.contains('127.0.0.1') ||
            options.baseUrl.contains('10.0.2.2'))) {
      if (_resolvedBaseUrl != null) {
        options.baseUrl = _resolvedBaseUrl!;
      } else {
        if (_isResolving) {
          final res = await _resolutionCompleter!.future;
          options.baseUrl = res;
        } else {
          _isResolving = true;
          _resolutionCompleter = Completer<String>();

          final discovered = await _discoverLocalServerIp();
          final finalUrl = discovered ?? options.baseUrl;

          _resolvedBaseUrl = finalUrl;
          _isResolving = false;
          _resolutionCompleter!.complete(finalUrl);
          options.baseUrl = finalUrl;
        }
      }
    }

    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_isHandling401) {
      _isHandling401 = true;
      _ref.read(authExpiredProvider.notifier).state = true;
      _isHandling401 = false;
    }

    // Transformasi error menjadi pesan yang lebih ramah
    final appError = _mapDioError(err);
    final appException = AppException.fromDioException(appError);
    final wrappedError = appError.copyWith(
      message: appError.message,
      error: appException,
    );

    // Layer di atas (seperti ApiService) sebaiknya menangkap AppException yang dibungkus dalam DioException
    return handler.next(wrappedError);
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
          // Jangan clearAll di sini — biarkan service layer yang handle
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

/// Menemukan IP lokal komputer host yang menjalankan server Laravel pada port 8000.
/// Melakukan scanning terhadap seluruh subnet /24 secara parallel dengan timeout singkat.
Future<String?> _discoverLocalServerIp() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address;
        if (ip.startsWith('127.') || ip.startsWith('169.254')) continue;

        final parts = ip.split('.');
        if (parts.length != 4) continue;
        final prefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

        // Scan seluruh subnet (1-254) secara parallel
        final futures = <Future<String?>>[];
        for (int i = 1; i < 255; i++) {
          final targetIp = '$prefix$i';
          if (targetIp == ip) continue; // Lewati IP perangkat sendiri

          futures.add(() async {
            try {
              final socket = await Socket.connect(
                targetIp,
                8000,
                timeout: const Duration(milliseconds: 200),
              );
              socket.destroy();
              return targetIp;
            } catch (_) {
              return null;
            }
          }());
        }

        final results = await Future.wait(futures);
        for (final res in results) {
          if (res != null) {
            debugPrint('Auto-discovered Laravel server at: http://$res:8000/api');
            return 'http://$res:8000/api';
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Gagal melakukan scanning IP lokal: $e');
  }
  return null;
}
