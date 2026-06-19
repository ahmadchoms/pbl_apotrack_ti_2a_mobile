class CartItem {
  final String id;          // medicine UUID
  final String name;
  final int price;
  final String unit;
  final String imageUrl;
  final String pharmacyName;
  final String pharmacyId;  // pharmacy UUID
  int quantity;
  final int stock;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.pharmacyName,
    required this.pharmacyId,
    this.quantity = 1,
    this.stock = 99,
  });
}

class CartState {
  static final CartState _instance = CartState._internal();
  factory CartState() => _instance;
  CartState._internal();

  final List<CartItem> items = [];

  /// Menambahkan item ke keranjang.
  /// Jika obat (id + apotek) sudah ada di keranjang, quantity-nya akan
  /// DITAMBAHKAN dengan quantity dari [newItem] (bukan hanya +1), lalu
  /// dibatasi maksimal sesuai stok terbaru (newItem.stock) supaya tidak
  /// melebihi stok yang tersedia saat ini.
  void addItem(CartItem newItem) {
    final existingIndex = items.indexWhere(
      (e) => e.id == newItem.id && e.pharmacyId == newItem.pharmacyId,
    );

    if (existingIndex != -1) {
      final existing = items[existingIndex];
      existing.quantity += newItem.quantity;
      if (existing.quantity > newItem.stock) {
        existing.quantity = newItem.stock;
      }
    } else {
      items.add(newItem);
    }
  }

  int get totalCount => items.fold(0, (sum, e) => sum + e.quantity);

  void clear() {
    items.clear();
  }
}