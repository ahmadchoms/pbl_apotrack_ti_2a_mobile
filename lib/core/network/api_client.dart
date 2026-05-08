import 'package:dio/dio.dart';

class ApiClient {
  // GANTI IP INI dengan IP laptop Anda (cek lewat ipconfig di terminal)
  static const String baseUrl = 'http://192.168.18.14:8000/api'; 

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Singleton pattern agar hemat memori
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();
}
