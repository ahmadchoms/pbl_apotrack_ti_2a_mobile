import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/medicine.dart';

class CartItem {
  final Medicine medicine;
  final int quantity;

  CartItem({required this.medicine, required this.quantity});

  double get subtotal => (medicine.price * quantity).toDouble();

  CartItem copyWith({int? quantity}) {
    return CartItem(medicine: medicine, quantity: quantity ?? this.quantity);
  }
}

class PosCartNotifier extends StateNotifier<List<CartItem>> {
  PosCartNotifier() : super([]);

  void addItem(Medicine medicine) {
    final existingIndex = state.indexWhere(
      (item) => item.medicine.id == medicine.id,
    );
    final maxStock = medicine.totalActiveStock;

    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      if (existingItem.quantity + 1 > maxStock) {
        throw Exception('Stok tidak mencukupi. Sisa stok: $maxStock');
      }

      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            existingItem.copyWith(quantity: existingItem.quantity + 1)
          else
            state[i],
      ];
    } else {
      if (1 > maxStock) {
        throw Exception('Stok obat ini sedang kosong.');
      }
      state = [...state, CartItem(medicine: medicine, quantity: 1)];
    }
  }

  void subtractItem(String medicineId) {
    final existingIndex = state.indexWhere(
      (item) => item.medicine.id == medicineId,
    );

    if (existingIndex < 0) return;

    final existingItem = state[existingIndex];

    if (existingItem.quantity <= 1) {
      removeItem(medicineId);
    } else {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            existingItem.copyWith(quantity: existingItem.quantity - 1)
          else
            state[i],
      ];
    }
  }

  void updateQuantity(String medicineId, int delta) {
    state = [
      for (final item in state)
        if (item.medicine.id == medicineId)
          () {
            final newQty = item.quantity + delta;
            if (newQty > item.medicine.totalActiveStock) {
              throw Exception(
                'Stok tidak mencukupi. Sisa stok: ${item.medicine.totalActiveStock}',
              );
            }
            return item.copyWith(quantity: newQty.clamp(1, 999));
          }()
        else
          item,
    ];
  }

  void removeItem(String medicineId) {
    state = state.where((item) => item.medicine.id != medicineId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0, (total, item) => total + item.subtotal);
  }
}

final posCartProvider = StateNotifierProvider<PosCartNotifier, List<CartItem>>((
  ref,
) {
  return PosCartNotifier();
});

final posProcessingProvider = StateProvider<bool>((ref) => false);
