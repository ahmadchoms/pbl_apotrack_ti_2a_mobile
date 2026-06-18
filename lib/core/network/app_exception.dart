import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  AppException.fromDioException(DioException e)
    : message = e.message ?? 'Terjadi kesalahan jaringan.',
      statusCode = e.response?.statusCode;

  @override
  String toString() => message;
}
