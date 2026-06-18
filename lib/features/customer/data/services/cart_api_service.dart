import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart.dart';

class CartApiService {
  final Dio _dio;

  CartApiService(this._dio);

  Future<void> syncCart(String pharmacyId, List<CartItem> items) async {
    final apiItems = items
        .map((item) => {
              'medicine_id': item.id,
              'quantity': item.quantity,
            })
        .toList();

    await _dio.post('/cart/sync', data: {
      'pharmacy_id': pharmacyId,
      'items': apiItems,
    });
  }
}

final cartApiServiceProvider = Provider<CartApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return CartApiService(dio);
});
