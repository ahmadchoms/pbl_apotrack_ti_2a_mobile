// ─── Simple Cart State (gunakan Provider/Riverpod di production) ───
class CartItem {
  final String id;          // medicine UUID
  final String name;
  final int price;
  final String unit;
  final String imageUrl;
  final String pharmacyName;
  final String pharmacyId;  // pharmacy UUID
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.pharmacyName,
    required this.pharmacyId,
    this.quantity = 1,
  });
}

class CartState {
  static final CartState _instance = CartState._internal();
  factory CartState() => _instance;
  CartState._internal();

  final List<CartItem> items = [];

  void addItem(CartItem newItem) {
    final existing = items.firstWhere(
      (e) => e.id == newItem.id && e.pharmacyId == newItem.pharmacyId,
      orElse: () => CartItem(id: '', name: '', price: 0, unit: '', imageUrl: '', pharmacyName: '', pharmacyId: ''),
    );
    if (existing.id.isNotEmpty) {
      existing.quantity++;
    } else {
      items.add(newItem);
    }
  }

  int get totalCount => items.fold(0, (sum, e) => sum + e.quantity);
}
