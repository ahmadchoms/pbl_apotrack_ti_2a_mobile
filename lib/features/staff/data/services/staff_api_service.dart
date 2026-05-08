import '../../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class StaffApiService {
  final ApiClient _client = ApiClient();

  /// Mengambil daftar pesanan dari backend
  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await _client.dio.get('/staff/orders');
      
      // Laravel biasanya membungkus data dalam field 'data' jika menggunakan Resource
      if (response.data is Map && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Gagal mengambil pesanan: ${e.message}');
    }
  }

  /// Mengambil daftar obat/inventori dari backend
  Future<List<Map<String, dynamic>>> getMedicines() async {
    try {
      final response = await _client.dio.get('/staff/medicines');
      
      if (response.data is Map && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Gagal mengambil data obat: ${e.message}');
    }
  }
}
