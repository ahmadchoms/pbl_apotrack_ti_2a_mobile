import '../../../../core/network/api_client.dart';
import '../models/order.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  Future<List<Order>> getOrders({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      final response = await _apiClient.get('/orders', queryParameters: queryParams);
      if (response.data['status'] == 'success') {
        final List data = response.data['data'];
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> getOrderDetail(int id) async {
    try {
      final response = await _apiClient.get('/orders/$id');
      return Order.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    try {
      await _apiClient.put('/orders/$id/status', data: {'status': status});
    } catch (e) {
      rethrow;
    }
  }
}
